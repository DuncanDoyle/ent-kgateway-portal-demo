#!/bin/sh

if [ -z "$CLIENT_ID" ]
then
   echo "No OAuth Client-ID set. Please configure the environment variable 'CLIENT_ID' with your OAuth Client-ID."
   exit 1
fi

if [ -z "$CLIENT_SECRET" ]
then
   echo "No OAuth Client-Secret set. Please configure the environment variable 'CLIENT_SECRET' with your OAuth Client-Secret."
   exit 1
fi

export ACCESS_TOKEN=$(curl -s --request POST \
    --url 'http://keycloak.example.com/realms/portal-mgmt/protocol/openid-connect/token' \
    --header 'content-type: application/x-www-form-urlencoded' \
    --data grant_type=client_credentials \
    --data client_id=$CLIENT_ID \
    --data client_secret=$CLIENT_SECRET | jq -r '.access_token')


printf "\nYour OAuth AccessToken (Bearer token) is:\n\n$ACCESS_TOKEN\n\n"