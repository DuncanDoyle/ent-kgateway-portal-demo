#!/bin/sh

# ----------------------------------------- SPA + PKCE: Gateway TLS -----------------------------------------
# The SPA + PKCE Portal Frontend runs the OAuth2 Authorization Code Flow with PKCE in the
# browser. PKCE uses the Web Crypto API (window.crypto.subtle / crypto.randomUUID), which
# browsers only expose in a "secure context" (HTTPS, or http://localhost). Serving the
# portal over plain http://developer.example.com is NOT a secure context, so the login
# button throws and the UI shows "Access issues".
#
# This script provisions a self-signed wildcard cert (*.example.com) and a TLS Secret that
# the gateway's HTTPS listeners terminate. We need BOTH the SPA host (developer.example.com)
# and Keycloak (keycloak.example.com) over HTTPS: after the auth redirect, the SPA does a
# browser fetch() to the Keycloak token endpoint, and an HTTPS page fetching an HTTP URL is
# blocked as mixed content. Both hosts are fronted by the same gateway, so one cert covers them.
#
# The BFF frontend does not need this (the gateway runs the OAuth flow server-side), so the
# existing HTTP listeners are left in place and untouched.

set -e

SECRET_NAME=example-com-tls
SECRET_NS=ingress-gw

CERT_DIR=$(mktemp -d)
trap 'rm -rf "$CERT_DIR"' EXIT

# Self-signed cert valid for the wildcard plus the two hosts the SPA flow touches.
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "$CERT_DIR/tls.key" \
  -out "$CERT_DIR/tls.crt" \
  -days 365 \
  -subj "/CN=*.example.com" \
  -addext "subjectAltName=DNS:*.example.com,DNS:developer.example.com,DNS:keycloak.example.com"

# Create/replace the TLS secret in the gateway namespace.
kubectl create secret tls "$SECRET_NAME" \
  --cert="$CERT_DIR/tls.crt" \
  --key="$CERT_DIR/tls.key" \
  -n "$SECRET_NS" \
  --dry-run=client -o yaml | kubectl apply -f -

printf "\nCreated TLS secret '%s' in namespace '%s'.\n" "$SECRET_NAME" "$SECRET_NS"
printf "It is self-signed, so the browser will warn once per host (developer.example.com and\n"
printf "keycloak.example.com) — accept the warning on both; the page stays a secure context.\n"
