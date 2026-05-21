#!/bin/bash
set -euo pipefail

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
# NOTE: ClickHouse has a 1Gi memory limit. For sustained load or backlog replay,
# consider bumping to 2Gi in clickhouse.yaml before running this script.
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --version "${CHART_VERSION}" \
  --namespace telemetry \
  --reuse-values \
  --values "${ANALYTICS_DIR}/grafana-analytics-values.yaml" \
  --wait --timeout 120s

kubectl apply -f "${ANALYTICS_DIR}/grafana-datasource.yaml"
kubectl apply -f "${ANALYTICS_DIR}/grafana-dashboard.yaml"

echo "==> Applying ReferenceGrant and ListenerPolicy"
kubectl apply -f "${SCRIPT_DIR}/../referencegrants/telemetry/listenerpolicy-ingress-gw-rg.yaml"
kubectl apply -f "${SCRIPT_DIR}/../policies/listenerpolicies/access-log-listener-policy.yaml"

GRAFANA_SVC=$(kubectl get svc -n telemetry -l app.kubernetes.io/name=grafana -o name | head -1)
echo ""
echo "==> Analytics stack installed."
echo "    Grafana: kubectl port-forward -n telemetry ${GRAFANA_SVC} 3000:80"
echo "    Dashboard: http://localhost:3000/d/api-analytics"
echo "    Login: admin / prom-operator"
