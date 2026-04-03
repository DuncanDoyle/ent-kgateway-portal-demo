#!/bin/bash

export ENT_KGATEWAY_VERSION="2.2.0-beta.16"
export ENT_KGATEWAY_HELM_VALUES_FILE="ent-kgateway-helm-values.yaml"
export PORTAL_VERSION="2.2.0-beta.16"
export K8S_GW_API_VERSION="v1.4.1"

export ENT_KGATEWAY_SYSTEM_NAMESPACE="kgateway-system"
export PORTAL_NAMESPACE="kgateway-system"

export PORTAL_HOST=developer.example.com

export KEYCLOAK_HOST=keycloak.example.com
export KC_ADMIN_PASS=admin