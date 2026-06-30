#!/bin/sh

pushd ..

#----------------------------------------- Portal Frontend: SPA + PKCE -----------------------------------------
# Deploys the Portal Frontend as a SPA that runs the OAuth2 Authorization Code Flow
# with PKCE in the browser, directly against Keycloak. Overwrites the BFF frontend
# Deployment and HTTPRoute (shared resource names). Switch back with setup-portal-frontend-bff.sh.

kubectl apply -f portal/portal-frontend-spa.yaml
kubectl apply -f routes/portal-frontend-spa-httproute.yaml

popd
