{% snapshot dim_hosts %}
{{
    config(
        target_database='AIRBNB',
        target_schema='GOLD',
        unique_key='HOST_ID',
        strategy='timestamp',
        updated_at='HOST_CREATED_AT',
        dbt_valid_to_current="TO_TIMESTAMP('9999-12-31 00:00:00')"
    )
}}

SELECT
    HOST_ID,
    HOST_NAME,
    HOST_SINCE,
    IS_SUPERHOST,
    RESPONSE_RATE_QUALITY,
    COALESCE(HOST_CREATED_AT, CAST('1900-01-01 00:00:00' AS TIMESTAMP_NTZ)) AS HOST_CREATED_AT
FROM {{ ref('hosts') }}

{% endsnapshot %}