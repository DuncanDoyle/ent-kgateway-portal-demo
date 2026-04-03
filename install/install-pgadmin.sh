#!/bin/sh

pushd ..

#----------------------------------------- PGAdmin -----------------------------------------

kubectl apply -f postgres/pg-admin.yaml
kubectl apply -f routes/pgadmin-example-com-httproute.yaml

popd

