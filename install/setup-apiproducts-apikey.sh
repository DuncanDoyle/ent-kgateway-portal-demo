#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - APIKey -----------------------------------------

kubectl apply -f policies/authconfigs/apiproducts-apikey-portalauth-authconfig.yaml
kubectl apply -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml

kubectl delete -f policies/trafficpolicies/ektp-apiproducts-oauth.yaml
kubectl apply -f policies/trafficpolicies/ektp-apiproducts-apikey.yaml

popd

