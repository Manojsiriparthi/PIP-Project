# CloudWatch Logs Insights Queries

## Error rate

```text
fields @timestamp, @message
| filter @message like /ERROR|Error|error/
| stats count() as errors by bin(5m)
| sort @timestamp desc
```

## Error rate by service

```text
fields @timestamp, service, level
| stats count(*) as total,
        sum(if(level = "ERROR", 1, 0)) as errors
  by service, bin(5m)
| fields service, bin(5m), total, errors,
         (errors / total * 100) as error_rate_pct
| sort error_rate_pct desc
```

## Latency percentiles

If logs contain a numeric `latency_ms` field:

```text
fields @timestamp, latency_ms
| filter ispresent(latency_ms)
| stats avg(latency_ms) as avg_latency,
        pct(latency_ms, 50) as p50,
        pct(latency_ms, 95) as p95,
        pct(latency_ms, 99) as p99
  by bin(5m)
```

## Cost tracking

If logs contain `account_id`, `service`, and numeric `cost`:

```text
fields @timestamp, account_id, service, cost
| filter ispresent(cost)
| stats sum(cost) as total_cost by account_id, service
| sort total_cost desc
```
