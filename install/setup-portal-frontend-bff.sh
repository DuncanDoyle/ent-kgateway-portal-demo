#!/bin/sh

pushd ..

#----------------------------------------- Portal Frontend: BFF (default) -----------------------------------------
# Deploys the Portal Frontend in BFF mode, where the gateway performs the OAuth2
# Authorization Code Flow via ExtAuth (oidcAuthorizationCode) and manages the session
# cookie. Overwrites the SPA frontend Deployment and HTTPRoute (shared resource names).

kubectl apply -f portal/portal-frontend.yaml
kubectl apply -f routes/portal-frontend-httproute.yaml

popd
