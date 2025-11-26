{% macro amount_bucket(column_name) %}
    case
        when {{ column_name }} <= 20 then 'small'
        when {{ column_name }} <= 100 then 'medium'
        when {{ column_name }} <= 500 then 'large'
        else 'extra_large'
    end
{% endmacro %}