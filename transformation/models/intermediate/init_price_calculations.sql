{{
    config
(
        materialized='view',
        schema='intermediate'
    )
}}

WITH
    staging_prices
    AS
    (
        SELECT
            price_date,
            stock_symbol,
            open_price,
            high_price,
            low_price,
            close_price,
            volume_traded
        FROM {{ ref
    ('stg_daily_prices') }}
),

add_previous_close AS
(
    SELECT
    *,
    LAG(close_price) OVER (
            PARTITION BY stock_symbol 
            ORDER BY price_date
        ) AS prev_close_price
FROM staging_prices
)
,

calculate_metrics AS
(
    SELECT
    price_date,
    stock_symbol,

    -- Original OHLCV
    open_price,
    high_price,
    low_price,
    close_price,
    volume_traded,

    -- Calculated metrics
    {{ calculate_return
('close_price', 'prev_close_price') }} AS daily_return_pct,
        
        {{ calculate_return
('close_price', 'open_price') }} AS intraday_change_pct,
        
        ROUND
(
            SAFE_DIVIDE
(
                high_price - low_price,
                close_price
            ) * 100,
            4
        ) AS price_range_pct,
        
        ROUND
(
            (high_price + low_price + close_price) / 3,
            4
        ) AS typical_price,
        
        -- Metadata
        prev_close_price
        
    FROM add_previous_close
)

SELECT *
FROM calculate_metrics