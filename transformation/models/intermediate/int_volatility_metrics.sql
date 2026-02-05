{{
    config
(
        materialized='view',
        schema='intermediate'
    )
}}

WITH
    price_calculations
    AS
    (
        SELECT
            price_date,
            stock_symbol,
            close_price,
            daily_return_pct
        FROM {{ ref('int_price_calculations') }}
    ),

calculate_rolling_volatility AS
(
    SELECT
        price_date,
        stock_symbol,
        close_price,
        daily_return_pct,

        -- 20-day rolling standard deviation of returns
        ROUND(
            STDDEV(daily_return_pct) OVER (
                PARTITION BY stock_symbol
                ORDER BY price_date
                ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
            ),
            4
        ) AS volatility_20d,

        -- 50-day rolling standard deviation of returns
        ROUND(
            STDDEV(daily_return_pct) OVER (
                PARTITION BY stock_symbol
                ORDER BY price_date
                ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
            ),
            4
        ) AS volatility_50d,

        -- Count of trading days for volatility calculation
        COUNT(daily_return_pct) OVER (
            PARTITION BY stock_symbol
            ORDER BY price_date
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS trading_days_20d,

        COUNT(daily_return_pct) OVER (
            PARTITION BY stock_symbol
            ORDER BY price_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS trading_days_50d

    FROM price_calculations
),

annualize_volatility AS
(
    SELECT
        price_date,
        stock_symbol,
        close_price,
        daily_return_pct,

        -- Rolling volatilities
        volatility_20d,
        volatility_50d,

        -- Annualized volatility (std_dev * sqrt(252 trading days))
        ROUND(
            volatility_20d * SQRT(252),
            4
        ) AS annualized_volatility_20d,

        ROUND(
            volatility_50d * SQRT(252),
            4
        ) AS annualized_volatility_50d,

        -- Volatility regime classification (based on 20-day volatility)
        CASE
            WHEN volatility_20d IS NULL THEN 'insufficient_data'
            WHEN volatility_20d < 1.0 THEN 'low_volatility'
            WHEN volatility_20d >= 1.0 AND volatility_20d < 2.0 THEN 'normal_volatility'
            WHEN volatility_20d >= 2.0 AND volatility_20d < 3.0 THEN 'elevated_volatility'
            WHEN volatility_20d >= 3.0 THEN 'high_volatility'
            ELSE 'unknown'
        END AS volatility_regime,

        -- Data quality flags
        trading_days_20d,
        trading_days_50d

    FROM calculate_rolling_volatility
)

SELECT *
FROM annualize_volatility
