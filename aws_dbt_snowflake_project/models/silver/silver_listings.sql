{{config(
    materialized='incremental',
    keys='LISTING_ID',
)}}

SELECT
    LISTING_ID,
    HOST_ID,
    PROPERTY_TYPE,
    ROOM_TYPE,
    CITY,
    {{ trimmer('COUNTRY') }} AS COUNTRY,
    ACCOMMODATES,
    BEDROOMS,
    BATHROOMS,
    CAST(PRICE_PER_NIGHT AS INTEGER) AS PRICE_PER_NIGHT,
    {{ tag('PRICE_PER_NIGHT') }} AS PRICE_PER_NIGHT_TAG,
    CREATED_AT
FROM
    {{ ref('bronze_listings') }}