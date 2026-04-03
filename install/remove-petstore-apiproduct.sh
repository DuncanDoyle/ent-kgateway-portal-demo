#!/bin/sh

pushd ..

#----------------------------------------- HTTPBin API Product -----------------------------------------

printf "\nDelete the Petstore HTTPRoute (delegatee) and the Petstore APIProduct ...\n"
kubectl delete -f referencegrants/petstore-ns/portal-kgateway-system-apiproduct-rg.yaml
kubectl delete -f apiproducts/petstore/petstore-apiproduct.yaml
kubectl delete -f apiproducts/petstore/petstore-apiproduct-httproute.yaml

printf "\nDelete Pestore APIDocs ...\n"
kubectl delete -f apis/petstore/pets-apidoc.yaml
kubectl delete -f apis/petstore/store-apidoc.yaml
kubectl delete -f apis/petstore/users-apidoc.yaml

printf "\nDelete Pestore services ...\n"
kubectl delete -f apis/petstore/pets-api.yaml
kubectl delete -f apis/petstore/store-api.yaml
kubectl delete -f apis/petstore/users-api.yaml

kubectl delete ns petstore

popd