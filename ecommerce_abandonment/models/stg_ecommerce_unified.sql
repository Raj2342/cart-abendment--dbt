{{ config(
    materialized='table',
    format='parquet',
    partitioned_by=['year']
) }}

SELECT *
FROM {{ source('ecommerce_raw', 'active_clicks_unified') }}