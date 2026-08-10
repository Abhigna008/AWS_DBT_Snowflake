{{ config(
    severity='warning'
) }}

SELECT
    1
FROM
    {{ source('staging', 'bookings')}}
WHERE
    booking_amount < 0