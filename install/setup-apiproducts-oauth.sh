#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - OAuth -----------------------------------------

kubectl apply -f policies/authconfigs/apiproducts-atv-portalauth-authconfig.yaml
kubectl apply -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml

kubectl delete -f policies/trafficpolicies/ektp-apiproducts-apikey.yaml
kubectl apply -f policies/trafficpolicies/ektp-apiproducts-oauth.yaml

popd

