# Enterprise KGateway Portal Demo

This repository contains a complete demo of the **Solo Enterprise for kgateway Portal** — a Kubernetes-native API developer portal. It covers installation, API Product deployment, API key and OAuth credential self-service, and an end-to-end demo walkthrough.

The demo deploys:
- Solo Enterprise for kgateway (API gateway)
- Keycloak (Identity Provider)
- PostgreSQL (Portal datastore)
- A Portal Frontend (developer UI) and Backend (portal server)
- Three example API Products: **HTTPBin**, **Petstore**, and **Tracks**

## Prerequisites

- A running Kubernetes cluster with `kubectl` configured
- `helm` installed
- A Solo license key, set in the enviroment variable `ENT_KGATEWAY_LICENSE_KEY`
- `curl` and `jq` available on your PATH

## Installation

All installation and setup scripts are in the `./install` directory.

```bash
cd install
```

Run the steps below **in order**.

### Step 1 — (Optional) Configure CoreDNS

If `keycloak.example.com` is not resolvable by both the browser and kgateway (e.g., in a local cluster), configure CoreDNS to route that hostname through the gateway:

```bash
./k8s-coredns-config.sh
```

> [!NOTE]
> The kgateway and Portal versions installed are configured in `install/env.sh`.

### Step 2 — Install Solo Enterprise for kgateway

This also installs Keycloak.

```bash
./install-ent-kgateway-with-helm.sh
```

### Step 3 — Install PostgreSQL for Portal

```bash
./install-portal-postgres.sh
```

### Step 4 — (Optional) Install pgAdmin

pgAdmin provides a browser-based PostgreSQL management UI, useful for inspecting Portal data during demos.

```bash
./install-pgadmin.sh
```

### Step 5 — Configure Keycloak Realms

```bash
./keycloak-kgateway-demo-realm.sh
./keycloak-portal-mgtm-realm.sh
```

### Step 6 — Install Portal IDP Connect

IDP Connect integrates the Portal server with Keycloak.

```bash
./install-portal-idp-connect.sh
```

### Step 7 — Install the Portal CRDs and Controller

```bash
./install-portal-with-helm.sh
```

### Step 8 — Set Up the Portal Web Server, Frontend, and Routes

```bash
./setup-portal.sh
```

## Gateway and Hostname Configuration

The demo uses the following hostnames:

| Hostname | Purpose |
|---|---|
| `developer.example.com` | Portal Frontend (developer UI) |
| `keycloak.example.com` | Keycloak Identity Provider |
| `api.example.com` | API Products |
| `pgadmin.example.com` | pgAdmin UI |

All hostnames are routed through the `gw` gateway in the `ingress-gw` namespace. For a local demo, port-forward the gateway proxy:

```bash
sudo kubectl -n ingress-gw port-forward deployments/gw 80:80
```

Then add all hostnames to `/etc/hosts`, pointing to `127.0.0.1`.

## Authentication & Authorization

kgateway Portal supports two credential types for API access: **API keys** and **OAuth tokens**. Both are managed through the Portal UI at `http://developer.example.com`, within the context of an *Application*.

The `install` directory provides scripts that deploy the required `AuthConfig`, `RateLimitConfig`, and `EnterpriseKgatewayTrafficPolicy` resources to secure your API Products. The two authentication modes are mutually exclusive — running one setup script automatically removes the other.

**Set up API key authentication:**

```bash
./setup-apiproducts-apikey.sh
```

**Set up OAuth authentication:**

```bash
./setup-apiproducts-oauth.sh
```

To remove authentication entirely:

```bash
./remove-apiproducts-apikey.sh
# or
./remove-apiproducts-oauth.sh
```

## Demo Walkthrough

This walkthrough demonstrates the full Portal lifecycle using the HTTPBin API Product. It covers: deploying an API Product, securing it with API key authentication, creating a team and application, generating an API key, subscribing to an API Product, and admin approval.

### 1. Log in as a regular user

1. Open the Portal UI at `http://developer.example.com`.
2. Click **Login** (top right) — this redirects to Keycloak.
3. Log in with username `user1` and password `password`.
4. Navigate to the **APIs** view. No API Products are visible yet.

### 2. Deploy the HTTPBin API Product

Run the following script from the `install` directory:

```bash
./setup-httpbin-apiproduct.sh
```

Once the resources are deployed, the **HTTPBin** API Product appears in the Portal UI.

### 3. Explore the API Product

1. Click on the **HTTPBin** API Product to view its details.
2. On the right side, click **Swagger View** to open the embedded Swagger UI.
3. The paths in the OpenAPI spec are automatically generated (stitched) from the HTTPRoute configurations in `api-example-com-root-route` and `httpbin-apiproduct`.
4. Expand `GET /httpbin/v1.0/get`, click **Try it out**, and execute the request. You should receive a `200` response.

### 4. Enable API key authentication

Run the API key authentication setup script from the `install` directory:

```bash
./setup-apiproducts-apikey.sh
```

This deploys the `AuthConfig`, `RateLimitConfig`, and `EnterpriseKgatewayTrafficPolicy` that enforce API key authentication on the API Products.

Try `GET /httpbin/v1.0/get` again — you will now receive a `403 Forbidden`. The **Authorize** button is now visible in the Swagger UI (top right), ready to accept an API key.

### 5. Create a team, application, and API key

1. Navigate to the **Teams** view and create a new team.
2. Inside that team, create an **Application**.
3. Open the **Applications** view, select your application, and click **Add API Key**.
4. Copy and store the API key somewhere safe — it is only shown once.

### 6. Authorize in Swagger UI

1. Go back to the HTTPBin API Product Swagger UI.
2. Click **Authorize**, paste your API key, and click **Authorize**.
3. Try `GET /httpbin/v1.0/get` again. You will still receive a `403` — because you are not yet subscribed to the API Product.

### 7. Subscribe to the API Product

1. In the **Applications** view, scroll to the **API Subscriptions** section at the bottom.
2. Click **Add Subscription**, select the **HTTPBin** API Product, and click **Create Subscription**.
3. The new subscription appears with status **Pending** — it requires approval from a Portal administrator.

### 8. Approve the subscription as admin

1. Open a **new browser window** (or private/incognito window) and navigate to `http://developer.example.com`.
2. Log in with username `admin` and password `admin`.
3. You will see the admin view of the Portal UI.
4. Navigate to **Subscriptions**. The pending HTTPBin subscription from `user1` is listed.
5. Click **Approve** on the HTTPBin subscription card.

### 9. Call the API as an authenticated user

1. Return to the `user1` browser. In the **Applications** view, the HTTPBin subscription status is now **Approved**.
2. Go back to the HTTPBin Swagger UI and click **Authorize**. Paste your API key and click **Authorize**.
3. Execute `GET /httpbin/v1.0/get`. You will receive a `200` response with the full HTTPBin output — authenticated via API key, with an approved subscription.

## Additional API Products

The demo includes two more API Products that showcase more advanced Portal features.

### Petstore

The **Petstore** API Product demonstrates Portal's API *stitching* capability: it composes three separate microservice APIs (pets, store, users) into a single unified API Product.

```bash
./setup-petstore-apiproduct.sh
```

### Tracks

The **Tracks** API Product demonstrates **multi-version** API Products: two versions of the API (`v1` and `v2`) are exposed via separate HTTPRoutes and surfaced as a single versioned API Product in the Portal.

```bash
./setup-tracks-apiproduct.sh
```
