#!/bin/sh

pushd ..

#----------------------------------------- Tracks API Product -----------------------------------------

# Create tracks namespace if it does not exist yet
kubectl create namespace tracks --dry-run=client -o yaml | kubectl apply -f -

printf "\nDeploy Tracks service ...\n"
kubectl apply -f apis/tracks/tracks-api-1.0.yaml

printf "\nDeploy Tracks APIDoc ...\n"
kubectl apply -f apis/tracks/tracks-api-1.0-apidoc.yaml

printf "\nDeploy the Tracks HTTPRoute (delegatee) and the HTTP APIProduct ...\n"
kubectl apply -f apiproducts/tracks/tracks-v1-apiproduct-httproute.yaml
kubectl apply -f apiproducts/tracks/tracks-v2-apiproduct-httproute.yaml
kubectl apply -f apiproducts/tracks/tracks-apiproduct.yaml
kubectl apply -f referencegrants/tracks-ns/portal-kgateway-system-apiproduct-rg.yaml

#----------------------------------------- api.example.com route -----------------------------------------

printf "\nDeploy the api.example.com HTTPRoute ...\n"
kubectl apply -f routes/api-example-com-root-httproute.yaml

popd

