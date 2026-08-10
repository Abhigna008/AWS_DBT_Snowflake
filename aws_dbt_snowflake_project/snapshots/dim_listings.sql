{% snapshot dim_listings %}
{{
    config(
        target_database='AIRBNB',
        target_schema='GOLD',
        unique_key='LISTING_ID',
        strategy='timestamp',
        updated_at='LISTING_CREATED_AT',
        dbt_valid_to_current="TO_TIMESTAMP('9999-12-31 00:00:00')"
    )
}}

SELECT
    LISTING_ID,
    PROPERTY_TYPE,
    ROOM_TYPE,
    CITY,
    COUNTRY,
    PRICE_PER_NIGHT_TAG,
    COALESCE(LISTING_CREATED_AT, CAST('1900-01-01 00:00:00' AS TIMESTAMP_NTZ)) AS LISTING_CREATED_AT
FROM {{ ref('listings') }}

{% endsnapshot %}