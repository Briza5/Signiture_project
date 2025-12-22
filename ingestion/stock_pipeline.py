import dlt
import yfinance as yf
from datetime import datetime, timedelta, date
import pandas as pd
import logging
import uuid
import argparse
from pathlib import Path

# Setup logging
log_dir = Path("../logs")
log_dir.mkdir(exist_ok=True)

log_file = log_dir / f"pipeline_run_{datetime.now().strftime('%Y-%m-%d_%H-%M')}.log"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_file,encoding='utf-8'),
        logging.StreamHandler()  # Also print to console
    ]
)

logger = logging.getLogger(__name__)

# Test symboly
TEST_SYMBOLS = ["AAPL", "MSFT", "GOOGL", "AMZN", "NVDA"]

# Global run tracking
run_metadata = []
run_id = str(uuid.uuid4())[:8]

@dlt.resource(
    write_disposition="merge",
    primary_key=["symbol", "date"],
    name="daily_prices"
)
def fetch_daily_prices(
    symbols: list,
    last_date=dlt.sources.incremental(
        "date", 
        initial_value=(datetime.now() - timedelta(days=730)).date()
       
    )
):
    """
    Stáhne OHLCV data od posledního načteného data.
    První run: od 2023-01-01
    Další runy: od max(date) v BigQuery
    """
    
    start_from = last_date.last_value
    if isinstance(start_from, date):
        start_from = start_from.strftime("%Y-%m-%d")

    end_date = datetime.now().strftime("%Y-%m-%d")
    
    logger.info(f"Fetching data from {start_from} to {end_date}")
    
    for symbol in symbols:
        symbol_start = datetime.now()
        
        try:
            logger.info(f"Downloading {symbol}...")
            
            df = yf.download(
                symbol,
                start=start_from,
                end=end_date,
                progress=False
            )
            
            if df.empty:
                logger.warning(f"No new data for {symbol}")
                run_metadata.append({
                    "run_id": run_id,
                    "pipeline_name": "stocks_pipeline",
                    "symbol": symbol,
                    "rows_loaded": 0,
                    "start_time": symbol_start,
                    "end_time": datetime.now(),
                    "status": "no_data",
                    "error_message": None,
                    "data_date_range": f"{start_from} to {end_date}"
                })
                continue
            
            # Transform
            df = df.reset_index()

            # Flatten MultiIndex columns (pokud existují)
            if isinstance(df.columns, pd.MultiIndex):
                df.columns = df.columns.get_level_values(0)

            df.columns = [col.lower() for col in df.columns]
            df = df.rename(columns={"adj close": "adj_close"})
            
            df["symbol"] = symbol
            df["date"] = pd.to_datetime(df["date"]).dt.date
            
            rows_count = len(df)
            
            # Log success
            logger.info(f"✅ {symbol}: {rows_count} rows")
            run_metadata.append({
                "run_id": run_id,
                "pipeline_name": "stocks_pipeline",
                "symbol": symbol,
                "rows_loaded": rows_count,
                "start_time": symbol_start,
                "end_time": datetime.now(),
                "status": "success",
                "error_message": None,
                "data_date_range": f"{start_from} to {end_date}"
            })
            
            yield df.to_dict(orient="records")
            
        except Exception as e:
            logger.error(f"❌ Error fetching {symbol}: {e}")
            run_metadata.append({
                "run_id": run_id,
                "pipeline_name": "stocks_pipeline",
                "symbol": symbol,
                "rows_loaded": 0,
                "start_time": symbol_start,
                "end_time": datetime.now(),
                "status": "failed",
                "error_message": str(e),
                "data_date_range": f"{start_from} to {end_date}"
            })
            continue

@dlt.resource(
    write_disposition="replace",
    name="company_metadata"
)
def fetch_company_metadata(symbols: list):
    """Stáhne company info"""
    
    metadata = []
    
    for symbol in symbols:
        logger.info(f"Fetching metadata: {symbol}...")
        
        try:
            ticker = yf.Ticker(symbol)
            info = ticker.info
            
            metadata.append({
                "symbol": symbol,
                "company_name": info.get("longName", symbol),
                "sector": info.get("sector", "Unknown"),
                "industry": info.get("industry", "Unknown"),
                "market_cap": info.get("marketCap", 0),
                "country": info.get("country", "US"),
                "updated_at": datetime.now()
            })
        except Exception as e:
            logger.warning(f"Partial metadata for {symbol}: {e}")
            metadata.append({
                "symbol": symbol,
                "company_name": symbol,
                "sector": "Unknown",
                "industry": "Unknown",
                "market_cap": 0,
                "country": "Unknown",
                "updated_at": datetime.now()
            })
    
    yield metadata

@dlt.resource(
    write_disposition="append",
    name="pipeline_runs"
)
def log_pipeline_runs():
    """Pipeline run metadata pro monitoring"""
    yield run_metadata

@dlt.source
def stock_data_source(symbols: list):
    """Stock data source s metadata tracking"""
    
    return [
        fetch_daily_prices(symbols),
        fetch_company_metadata(symbols),
        log_pipeline_runs()
    ]

if __name__ == "__main__":
    
    # Parse arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("--full-refresh", action="store_true", help="Full data reload")
    args = parser.parse_args()
    
    logger.info("Starting Stock Pipeline...")
    logger.info(f"Symbols: {TEST_SYMBOLS}")
    logger.info(f"Run ID: {run_id}")
    logger.info(f"Mode: {'FULL REFRESH' if args.full_refresh else 'INCREMENTAL'}")
    
    # Init pipeline
    pipeline = dlt.pipeline(
        pipeline_name="stocks_pipeline",
        destination="bigquery",
        dataset_name="stocks_raw"
    )
    
      # Run
    if args.full_refresh:
        logger.info("🔄 Running FULL REFRESH...")
        logger.info("Dropping pipeline state...")
        pipeline.drop()  # Smaže lokální state
        
        # Re-init
        pipeline = dlt.pipeline(
            pipeline_name="stocks_pipeline",
            destination="bigquery",
            dataset_name="stocks_raw"
        )
    else:
        logger.info("⚡ Running INCREMENTAL load...")
        
    
    load_info = pipeline.run(
            stock_data_source(symbols=TEST_SYMBOLS)
        )
    
    # Results
    logger.info("="*50)
    logger.info("Pipeline Completed!")
    logger.info(f"Loaded: {load_info}")
    logger.info("="*50)