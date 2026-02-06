{{
    config(
        materialized='table',
        schema='marts'
    )
}}

WITH company_metadata AS (
    SELECT
        company_symbol,
        company_name,
        company_sector,
        company_industry,
        company_market_cap,
        company_country,
        last_updated
    FROM {{ ref('stg_company_metadata') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['company_symbol']) }} AS company_key,
    company_symbol,
    company_name,
    company_sector,
    company_industry,
    company_market_cap,
    company_country,
    last_updated,
    CURRENT_DATETIME("Europe/Prague") AS dbt_updated_at
FROM company_metadata
