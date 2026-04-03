#!/bin/sh

pushd ..

#----------------------------------------- Portal -----------------------------------------

kubectl apply -f policies/authconfigs/portal-apis-authconfig.yaml
kubectl apply -f policies/authconfigs/portal-authconfig.yaml

kubectl apply -f policies/trafficpolicies/ektp-portal.yaml
kubectl apply -f policies/trafficpolicies/ektp-portal-apis.yaml
kubectl apply -f policies/trafficpolicies/ektp-portal-cors.yaml

kubectl apply -f policies/trafficpolicies/ektp-apiproducts-cors.yaml

kubectl apply -f portal/portal-parameters.yaml
kubectl apply -f portal/portal.yaml
kubectl apply -f portal/portal-frontend.yaml

kubectl apply -f routes/portal-server-httproute.yaml
kubectl apply -f routes/portal-frontend-httproute.yaml

popd

