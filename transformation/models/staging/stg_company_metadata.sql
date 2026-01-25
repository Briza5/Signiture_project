WITH
    source
    as
    (
        select *
        from {{ source
    
    
    
    
    
    
    ('stocks_raw', 'company_metadata') }}
),

    renamed AS
(   
SELECT
    symbol AS company_symbol,
    company_name AS company_name,
    sector AS company_sector,
    industry AS company_industry,
    CAST(market_cap AS NUMERIC) AS company_market_cap,
    country AS company_country,
    updated_at AS last_updated,
    _dlt_load_id AS dlt_load_id,
    _dlt_id AS dlt_id,
    CURRENT_DATETIME("Europe/Prague") AS dbt_loaded_at
FROM source
)

SELECT *
FROM renamed