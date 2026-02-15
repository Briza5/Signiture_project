{#
  BigQuery Timestamp Precision Fix for Elementary

  Problem: Elementary uses default timestamp type which allows nanosecond precision.
  BigQuery only supports microsecond precision (6 digits).

  Solution: Override edr_type_timestamp macro for BigQuery to use timestamp(6)
  which limits precision to microseconds, matching BigQuery's capabilities.

  Error fixed: "Invalid timestamp: '2026-02-14T19:43:26.693945100Z'"
#}

{% macro bigquery__edr_type_timestamp() %}
    {#
    BigQuery Fix: Use TIMESTAMP without precision parameter
    BigQuery's TIMESTAMP type defaults to microsecond precision (6 digits)
    and does NOT support the timestamp(6) syntax like Athena/Trino
    #}
    {{ log("🎯 Using custom BigQuery TIMESTAMP override (microsecond precision)", info=True) }}
    TIMESTAMP
{% endmacro %}
