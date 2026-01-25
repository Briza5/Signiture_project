WITH
    source
    as
    (
        select *
        from {{ source
    
    
    
    
    
    ('stocks_raw', 'pipeline_runs') }}
),

    renamed AS
(

        SELECT
    run_id AS pipeline_run_id,
    pipeline_name AS pipeline_name,
    symbol AS company_symbol,
    rows_loaded AS rows_loaded,
    start_time AS load_start_time,
    end_time AS load_end_time,
    status AS run_status,
    data_date_range AS data_date_range,
    _dlt_load_id AS dlt_load_id,
    _dlt_id AS dlt_id,
    CURRENT_DATETIME("Europe/Prague") AS dbt_loaded_at

FROM source
    )
SELECT *
FROM renamed