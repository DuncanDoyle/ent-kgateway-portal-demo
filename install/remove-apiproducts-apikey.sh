#!/bin/sh

pushd ..

#----------------------------------------- ApiProducts - APIKey -----------------------------------------

kubectl delete -f policies/authconfigs/apiproducts-apikey-portalauth-authconfig.yaml
kubectl delete -f policies/ratelimitconfigs/apiproducts-dynamic-rl.yaml
kubectl delete -f policies/trafficpolicies/ektp-apiproducts-apikey.yaml

popd

