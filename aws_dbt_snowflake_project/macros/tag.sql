{% macro tag(col) %}
    CASE 
        WHEN CAST({{ col }} AS INTEGER) < 100 THEN 'low'
        WHEN CAST({{ col }} AS INTEGER) >= 100 AND CAST({{ col }} AS INTEGER) < 200 THEN 'medium'
        ELSE 'high'
    END
{% endmacro %}