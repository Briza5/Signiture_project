{{
    config(
        materialized='table',
        schema='marts'
    )
}}

WITH price_calculations AS (
    SELECT
        price_date,
        stock_symbol,
        open_price,
        high_price,
        low_price,
        close_price,
        volume_traded,
        daily_return_pct,
        intraday_change_pct,
        price_range_pct,
        typical_price,
        prev_close_price
    FROM {{ ref('int_price_calculations') }}
),

moving_averages AS (
    SELECT
        price_date,
        stock_symbol,
        ma_20,
        ma_50,
        ma_200,
        golden_cross,
        death_cross,
        trend_signal
    FROM {{ ref('int_moving_averages') }}
),

volatility_metrics AS (
    SELECT
        price_date,
        stock_symbol,
        volatility_20d,
        volatility_50d,
        annualized_volatility_20d,
        annualized_volatility_50d,
        volatility_regime,
        trading_days_20d,
        trading_days_50d
    FROM {{ ref('int_volatility_metrics') }}
),

dim_companies AS (
    SELECT
        company_key,
        company_symbol,
        company_sector
    FROM {{ ref('dim_companies') }}
),

dim_sectors AS (
    SELECT
        sector_key,
        sector_name
    FROM {{ ref('dim_sectors') }}
)

SELECT
    -- Surrogate key for fact table
    {{ dbt_utils.generate_surrogate_key(['pc.stock_symbol', 'pc.price_date']) }} AS performance_key,

    -- Date dimension
    pc.price_date,

    -- Foreign keys to dimensions
    dc.company_key,
    ds.sector_key,

    -- Business key
    pc.stock_symbol,

    -- Price metrics
    pc.open_price,
    pc.high_price,
    pc.low_price,
    pc.close_price,
    pc.volume_traded,
    pc.prev_close_price,

    -- Performance metrics
    pc.daily_return_pct,
    pc.intraday_change_pct,
    pc.price_range_pct,
    pc.typical_price,

    -- Moving averages
    ma.ma_20,
    ma.ma_50,
    ma.ma_200,
    ma.golden_cross,
    ma.death_cross,
    ma.trend_signal,

    -- Volatility metrics
    vm.volatility_20d,
    vm.volatility_50d,
    vm.annualized_volatility_20d,
    vm.annualized_volatility_50d,
    vm.volatility_regime,
    vm.trading_days_20d,
    vm.trading_days_50d,

    -- Metadata
    CURRENT_DATETIME("Europe/Prague") AS dbt_updated_at

FROM price_calculations pc

INNER JOIN dim_companies dc
    ON pc.stock_symbol = dc.company_symbol

LEFT JOIN dim_sectors ds
    ON dc.company_sector = ds.sector_name

LEFT JOIN moving_averages ma
    ON pc.stock_symbol = ma.stock_symbol
    AND pc.price_date = ma.price_date

LEFT JOIN volatility_metrics vm
    ON pc.stock_symbol = vm.stock_symbol
    AND pc.price_date = vm.price_date
