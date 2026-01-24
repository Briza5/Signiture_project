WITH
    raw_data
    AS
    (
        SELECT *
        FROM {{ source
    
    
    
    
    ('stocks_raw', 'daily_prices') }}
)


SELECT
    date AS price_date, 
open AS open_price,
    high AS high_price,
    low AS low_price,
close AS close_price,
    volume AS volume_traded,
    symbol AS stock_symbol
FROM raw_data