WITH
    source
    AS
    (
        SELECT *
        FROM {{ source
    
    ('stocks_raw', 'daily_prices') }}
),

renamed AS
(

SELECT
    date AS price_date,
    ROUND(CAST(open AS NUMERIC), 4) AS open_price,
    ROUND(CAST(high AS NUMERIC), 4) AS high_price,
    ROUND(CAST(low AS NUMERIC), 4) AS low_price,
    ROUND(CAST(close AS NUMERIC), 4) AS close_price,
    volume AS volume_traded,
    symbol AS stock_symbol,
    CURRENT_DATETIME("Europe/Prague") AS dbt_loaded_at
FROM source
)

SELECT *
FROM renamed