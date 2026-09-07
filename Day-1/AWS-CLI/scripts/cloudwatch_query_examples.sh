#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
CloudWatch Logs Insights examples
=================================

1) Error-rate analysis
fields @timestamp, @message
| filter @message like /ERROR|Error|error/
| stats count() as errors by bin(5m)
| sort @timestamp desc

2) Latency percentiles (when latency_ms is logged)
fields @timestamp, latency_ms
| filter ispresent(latency_ms)
| stats avg(latency_ms) as avg_latency,
        pct(latency_ms, 50) as p50,
        pct(latency_ms, 95) as p95,
        pct(latency_ms, 99) as p99
  by bin(5m)

3) Cost tracking (when cost fields exist)
fields @timestamp, account_id, service, cost
| filter ispresent(cost)
| stats sum(cost) as total_cost by account_id, service
| sort total_cost desc

Run these in CloudWatch Logs Insights after selecting the appropriate log group and time range.
EOF
