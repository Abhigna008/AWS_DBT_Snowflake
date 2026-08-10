{% snapshot dim_bookings %}
{{
    config(
        target_database='AIRBNB',
        target_schema='GOLD',
        unique_key='BOOKING_ID',
        strategy='timestamp',
        updated_at='CREATED_AT',
        dbt_valid_to_current="TO_TIMESTAMP('9999-12-31 00:00:00')"
    )
}}

SELECT
    BOOKING_ID,
    BOOKING_DATE,
    BOOKING_STATUS,
    COALESCE(CREATED_AT, CAST('1900-01-01 00:00:00' AS TIMESTAMP_NTZ)) AS CREATED_AT
FROM {{ ref('bookings') }}

{% endsnapshot %}