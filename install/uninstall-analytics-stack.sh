#!/bin/bash
set -euo pipefail

for cmd in kubectl helm jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd is required but not found on PATH"; exit 1; }
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Removing ListenerPolicy and ReferenceGrant"
kubectl delete -f "${SCRIPT_DIR}/../policies/listenerpolicies/access-log-listener-policy.yaml" --ignore-not-found
kubectl delete -f "${SCRIPT_DIR}/../referencegrants/telemetry/listenerpolicy-ingress-gw-rg.yaml" --ignore-not-found

echo "==> Removing Grafana dashboard, datasource, and plugin"
kubectl delete -f "${SCRIPT_DIR}/analytics/grafana-dashboard.yaml" --ignore-not-found
kubectl delete -f "${SCRIPT_DIR}/analytics/grafana-datasource.yaml" --ignore-not-found

CHART_VERSION=$(helm list -n telemetry -o json | jq -r '.[] | select(.name=="kube-prometheus-stack") | .chart' | sed 's/kube-prometheus-stack-//')
if [ -n "${CHART_VERSION}" ]; then
  # Disable admission webhooks to avoid operator pod stuck on missing TLS secret.
  # Use --atomic=false so the upgrade is not rolled back if operator is unhealthy
  # (e.g. image pull timeout); Grafana itself always comes up fine.
  helm upgrade kube-prometheus-stack \
    prometheus-community/kube-prometheus-stack \
    --version "${CHART_VERSION}" \
    --namespace telemetry \
    --reuse-values \
    --set-json 'grafana.plugins=[]' \
    --set-json 'grafana.envFromSecrets=[]' \
    --set prometheusOperator.admissionWebhooks.patch.enabled=false \
    --set prometheusOperator.admissionWebhooks.enabled=false \
    --atomic=false \
    --timeout 120s || echo "WARN: helm upgrade returned non-zero (prometheus-operator may be unhealthy); continuing cleanup"
fi

echo "==> Removing analytics OTEL collector"
kubectl delete -f "${SCRIPT_DIR}/analytics/otel-collector-analytics.yaml" --ignore-not-found
kubectl delete secret clickhouse-auth -n telemetry --ignore-not-found

echo "==> Removing ClickHouse"
kubectl delete -f "${SCRIPT_DIR}/analytics/clickhouse.yaml" --ignore-not-found
kubectl delete namespace analytics --ignore-not-found
