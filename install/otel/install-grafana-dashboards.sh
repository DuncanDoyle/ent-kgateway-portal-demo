#!/bin/sh

# Grafana dashboards:
# - envoy.json: fetched from https://docs.solo.io/gateway/2.0.x/observability/envoy.json
# - kgateway-full.json: based on https://github.com/kgateway-dev/dashboards/blob/main/install/helm/kgateway-dashboards/dashboards/kgateway.json
#   with the Gloo Gateway Operations section (XDS sync state, latency, translation/reconciliation metrics) added from gloo-gateway.json

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Create ConfigMaps from our Grafana dashboard files
kubectl -n telemetry create cm envoy-dashboard --from-file=$SCRIPT_DIR/envoy.json
kubectl -n telemetry create cm kgateway-dashboard --from-file=$SCRIPT_DIR/kgateway.json
kubectl -n telemetry create cm kgateway-full-dashboard --from-file=$SCRIPT_DIR/kgateway-full.json

# Label the configmaps so they will be picked up by Grafana.
kubectl label -n telemetry cm envoy-dashboard grafana_dashboard=1
kubectl label -n telemetry cm kgateway-dashboard grafana_dashboard=1
kubectl label -n telemetry cm kgateway-full-dashboard grafana_dashboard=1