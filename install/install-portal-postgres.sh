#!/bin/sh

pushd ..

#----------------------------------------- Portal-Postgres -----------------------------------------

kubectl apply -f portal/portal-db-pv.yaml
kubectl apply -f portal/portal-postgres-secret.yaml
kubectl apply -f portal/portal-postgres.yaml

export POSTGRES_CONNECTION_URL=$(printf "dsn: host=portal-postgres.gloo-system.svc.cluster.local port=5432 user=user password=pass dbname=db sslmode=disable" | base64)

# kubectl apply -f - <<EOF
# apiVersion: v1
# kind: Secret
# metadata:
#   name: portal-database-config
#   namespace: kgateway-system
# type: Opaque
# data:
#   config.yaml: |
#     $POSTGRES_CONNECTION_URL
# EOF

# ddoyle: We need to use this exact name for the postgres connection secret. This needs to be configurable.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: portal-postgres-secret
  namespace: kgateway-system
type: Opaque
stringData:
  host: "portal-postgres.kgateway-system.svc.cluster.local"   # required
  port: "5432"                                            # optional, defaults to 5432                                  
  username: "user"                                        # required
  password: "pass"                                        # required
  database: "db"                                          # required
  sslmode: "disable"                                      # optional, defaults to "require"
EOF

popd

