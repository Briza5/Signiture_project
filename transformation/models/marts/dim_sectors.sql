{{
    config(
        materialized='table',
        schema='marts'
    )
}}

WITH sector_aggregation AS (
    SELECT
        company_sector,
        COUNT(DISTINCT company_industry) AS industry_count
    FROM {{ ref('stg_company_metadata') }}
    WHERE company_sector IS NOT NULL
    GROUP BY company_sector
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['company_sector']) }} AS sector_key,
    company_sector AS sector_name,
    industry_count,
    CURRENT_DATETIME("Europe/Prague") AS dbt_updated_at
FROM sector_aggregation
