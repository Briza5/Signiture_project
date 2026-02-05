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
            close_price
        FROM {{ ref('stg_daily_prices') }}
    ),

calculate_moving_averages AS
(
    SELECT
        price_date,
        stock_symbol,
        close_price,

        -- 20-day moving average
        ROUND(
            AVG(close_price) OVER (
                PARTITION BY stock_symbol
                ORDER BY price_date
                ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
            ),
            4
        ) AS ma_20,

        -- 50-day moving average
        ROUND(
            AVG(close_price) OVER (
                PARTITION BY stock_symbol
                ORDER BY price_date
                ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
            ),
            4
        ) AS ma_50,

        -- 200-day moving average
        ROUND(
            AVG(close_price) OVER (
                PARTITION BY stock_symbol
                ORDER BY price_date
                ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
            ),
            4
        ) AS ma_200

    FROM staging_prices
),

add_previous_mas AS
(
    SELECT
        *,
        LAG(ma_20) OVER (
            PARTITION BY stock_symbol
            ORDER BY price_date
        ) AS prev_ma_20,

        LAG(ma_50) OVER (
            PARTITION BY stock_symbol
            ORDER BY price_date
        ) AS prev_ma_50

    FROM calculate_moving_averages
),

detect_crossovers AS
(
    SELECT
        price_date,
        stock_symbol,
        close_price,

        -- Moving averages
        ma_20,
        ma_50,
        ma_200,

        -- Golden Cross: MA20 crosses above MA50 (bullish signal)
        CASE
            WHEN ma_20 > ma_50 AND prev_ma_20 <= prev_ma_50 THEN TRUE
            ELSE FALSE
        END AS golden_cross,

        -- Death Cross: MA20 crosses below MA50 (bearish signal)
        CASE
            WHEN ma_20 < ma_50 AND prev_ma_20 >= prev_ma_50 THEN TRUE
            ELSE FALSE
        END AS death_cross,

        -- Current trend indicator
        CASE
            WHEN ma_20 > ma_50 AND ma_50 > ma_200 THEN 'strong_uptrend'
            WHEN ma_20 > ma_50 THEN 'uptrend'
            WHEN ma_20 < ma_50 AND ma_50 < ma_200 THEN 'strong_downtrend'
            WHEN ma_20 < ma_50 THEN 'downtrend'
            ELSE 'neutral'
        END AS trend_signal

    FROM add_previous_mas
)

SELECT *
FROM detect_crossovers
