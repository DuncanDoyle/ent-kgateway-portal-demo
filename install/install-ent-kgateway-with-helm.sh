
#!/bin/sh

source ./env.sh

if [ -z "$ENT_KGATEWAY_LICENSE_KEY" ]
then
   echo "Solo Enterprise for Kgateway License Key not specified. Please configure the environment variable 'ENT_KGATEWAY_LICENSE_KEY' with your Solo Enterprise for kgateway License Key."
   exit 1
fi

export ENT_KGATEWAY_CRDS_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway-crds"
export ENT_KGATEWAY_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway"

#----------------------------------------- Install Solo Enterprise for kgateway and K8S Gateway API -----------------------------------------

printf "\nApply K8S Gateway CRDs ....\n"
# kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$K8S_GW_API_VERSION/standard-install.yaml
# Note: --server-side is a workaround. If not applied, the HTTPRoute CRD will not install.
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$K8S_GW_API_VERSION/experimental-install.yaml

# Install default KgatewayParameters for enterprise-kgateway GatewayClass
printf "\nInstall Solo Enterprise for Kgateway CRDs ....\n"
helm upgrade --install enterprise-kgateway-crds $ENT_KGATEWAY_CRDS_URL \
    --version $ENT_KGATEWAY_VERSION \
    --namespace $ENT_KGATEWAY_SYSTEM_NAMESPACE \
    --create-namespace \
    --set installExtAuthCRDs=true \
    --set installRateLimitCRDs=true \
    --set installEnterpriseListenerSetCRD=true

# Wait for CRD to be available.
sleep 2
kubectl wait --for=condition=Established crd/enterprisekgatewayparameters.enterprisekgateway.solo.io

pushd ../
printf "\nInstall shared EnterpriseKgatewayParameters for enterprise-kgateway GatewayClass ....\n"
kubectl apply -f gateways/shared-ent-kgateway-parameters.yaml
popd

printf "\nInstall Solo Enterprise for Kgateway ...\n"
helm upgrade --install enterprise-kgateway $ENT_KGATEWAY_URL \
    --version $ENT_KGATEWAY_VERSION \
    --namespace $ENT_KGATEWAY_SYSTEM_NAMESPACE \
    --create-namespace \
    --set-string licensing.licenseKey=$ENT_KGATEWAY_LICENSE_KEY \
    -f $ENT_KGATEWAY_HELM_VALUES_FILE


#----------------------------------------- Deploy the Gateway -----------------------------------------
pushd ../

# create the ingress-gw namespace
kubectl create namespace ingress-gw --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy the Gateway ...\n"
kubectl apply -f gateways/gw.yaml

popd

#----------------------------------------- Install Keycloak -----------------------------------------

pushd ../

# Install Keycloak
printf "\nInstall Keycloak ...\n"
# Create Keycloak namespace if it does not yet exist
kubectl create namespace keycloak --dry-run=client -o yaml | kubectl apply -f -
# Label the httpbin namespace, so the gateway will accept the HTTPRoute from that namespace.
printf "\nLabel keycloak namespace ...\n"
kubectl label namespaces keycloak --overwrite shared-gateway-access="true"

kubectl apply -f keycloak/keycloak-secrets.yaml
kubectl apply -f keycloak/keycloak-db-pv.yaml
kubectl apply -f keycloak/keycloak-postgres.yaml
printf "\nWait for Keycloak Postgres readiness ...\n"
kubectl -n keycloak rollout status deploy/postgres

kubectl apply -f keycloak/keycloak.yaml
printf "\nWait for Keycloak readiness ...\n"
kubectl -n keycloak rollout status deploy/keycloak

kubectl apply -f routes/keycloak-example-com-httproute.yaml

popd


#----------------------------------------- Label the kgateway-system namespace -----------------------------------------

printf "\nLabel kgateway-system namespace ...\n"
kubectl label namespaces kgateway-system --overwrite shared-gateway-access="true"