#!/bin/sh

pushd ..

#----------------------------------------- Portal Frontend: SPA + PKCE -----------------------------------------
# Deploys the Portal Frontend as a SPA that runs the OAuth2 Authorization Code Flow
# with PKCE in the browser, directly against Keycloak. Overwrites the BFF frontend
# Deployment and HTTPRoute (shared resource names). Switch back with setup-portal-frontend-bff.sh.

# PKCE requires a browser secure context (HTTPS). Provision the self-signed cert/secret and
# apply the gateway with its HTTPS listeners for developer.example.com and keycloak.example.com.
sh install/setup-spa-tls.sh
kubectl apply -f gateways/gw.yaml

kubectl apply -f portal/portal-frontend-spa.yaml
kubectl apply -f routes/portal-frontend-spa-httproute.yaml

popd
