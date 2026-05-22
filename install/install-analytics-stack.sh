#!/bin/bash
# Prerequisites: kubectl, helm, jq, and kube-prometheus-stack pre-installed in the telemetry namespace.
set -euo pipefail

for cmd in kubectl helm jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd is required but not found on PATH"; exit 1; }
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYTICS_DIR="${SCRIPT_DIR}/analytics"

CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-clickhouse-demo-password}"

echo "==> Creating analytics namespace"
kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f -

echo "==> Creating ClickHouse auth secrets"
kubectl create secret generic clickhouse-auth \
  --namespace analytics \
  --from-literal=password="${CLICKHOUSE_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

# Copy the secret to telemetry namespace (avoids silent empty-value issue with variable expansion).
kubectl get secret clickhouse-auth -n analytics -o yaml \
  | sed 's/namespace: analytics/namespace: telemetry/' \
  | kubectl apply -f -

echo "==> Deploying ClickHouse"
kubectl apply -f "${ANALYTICS_DIR}/clickhouse.yaml"
kubectl rollout status statefulset/clickhouse -n analytics --timeout=180s

echo "==> Applying ClickHouse schema"
kubectl cp "${ANALYTICS_DIR}/clickhouse-schema.sql" analytics/clickhouse-0:/tmp/clickhouse-schema.sql
kubectl exec -n analytics statefulset/clickhouse -- \
  clickhouse-client --user default --password "${CLICKHOUSE_PASSWORD}" \
  --multiquery --queries-file /tmp/clickhouse-schema.sql

echo "==> Deploying analytics OTEL collector"
kubectl apply -f "${ANALYTICS_DIR}/otel-collector-analytics.yaml"
kubectl rollout status deployment/analytics-otel-collector -n telemetry --timeout=120s

echo "==> Configuring Grafana (plugin + datasource + dashboard)"
CHART_VERSION=$(helm list -n telemetry -o json | jq -r '.[] | select(.name=="kube-prometheus-stack") | .chart' | sed 's/kube-prometheus-stack-//')
if [ -z "${CHART_VERSION}" ]; then
  echo "ERROR: kube-prometheus-stack not found in telemetry namespace. Install it first."
  exit 1
fi

# Use --install to handle both fresh install and upgrade scenarios.
# Disable admission webhooks to avoid the prometheus-operator pod getting stuck
# on a missing TLS secret (kube-prometheus-stack-admission) in clusters where
# the certgen job never ran or the secret was deleted.
# NOTE: ClickHouse has a 1Gi memory limit. For sustained load or backlog replay,
# consider bumping to 2Gi in clickhouse.yaml before running this script.
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --version "${CHART_VERSION}" \
  --namespace telemetry \
  --reuse-values \
  --values "${ANALYTICS_DIR}/grafana-analytics-values.yaml" \
  --set prometheusOperator.admissionWebhooks.patch.enabled=false \
  --set prometheusOperator.admissionWebhooks.enabled=false \
  --atomic=false \
  --timeout 120s || echo "WARN: helm upgrade returned non-zero (prometheus-operator may be unhealthy); continuing install"

kubectl apply -f "${ANALYTICS_DIR}/grafana-datasource.yaml"
kubectl apply -f "${ANALYTICS_DIR}/grafana-dashboard.yaml"

echo "==> Applying ReferenceGrant and ListenerPolicy"
kubectl apply -f "${SCRIPT_DIR}/../referencegrants/telemetry/listenerpolicy-ingress-gw-rg.yaml"
kubectl apply -f "${SCRIPT_DIR}/../policies/listenerpolicies/access-log-listener-policy.yaml"

GRAFANA_SVC=$(kubectl get svc -n telemetry -l app.kubernetes.io/name=grafana -o name 2>/dev/null | head -1 || true)
GRAFANA_ADMIN_PW=$(kubectl get secret -n telemetry -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].data.admin-password}' 2>/dev/null | base64 -d 2>/dev/null || echo "prom-operator")
echo ""
echo "==> Analytics stack installed."
if [ -n "${GRAFANA_SVC}" ]; then
  echo "    Grafana: kubectl port-forward -n telemetry ${GRAFANA_SVC} 3000:80"
fi
echo "    Dashboard: http://localhost:3000/d/api-analytics"
echo "    Login: admin / ${GRAFANA_ADMIN_PW}"
