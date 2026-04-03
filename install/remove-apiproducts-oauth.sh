#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - OAuth -----------------------------------------

kubectl delete -f policies/authconfigs/apiproducts-atv-portalauth-authconfig.yaml
kubectl delete -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl delete -f policies/trafficpolicies/ektp-apiproducts-oauth.yaml

popd

