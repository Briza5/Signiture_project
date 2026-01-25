

{% macro calculate_return
(current_value, previous_value) %}
    ROUND
(
        SAFE_DIVIDE
(
            {{ current_value }} - {{ previous_value }},
            {{ previous_value }}
        ) * 100,
        4
    ) 
{% endmacro %}