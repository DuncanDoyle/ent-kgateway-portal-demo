# Demo Roadmap

Tracked improvements, known gaps, and future phases for the Enterprise kgateway Portal demo.

---

## Analytics — Known Gaps

### Application ID not exposed by Portal

The `ApplicationId` column in `api_access_logs` is always empty because the Portal does not inject `application_id` into the request metadata that ext-auth passes downstream.

**Impact:** The **Requests by Application** panel in the Grafana dashboard is a placeholder and shows no data.

---

## Analytics — Dashboard Improvements

### Additional filters

The dashboard currently has an **API Product** filter. Useful additions:
- **HTTP Method** (GET, POST, etc.)
- **Response code category** (success / client error / server error)
- **Path prefix** — for products with many endpoints

---

### kgateway-full.json — verify XDS metric names

The `kgateway-full.json` dashboard (the extended version with the "kgateway Operations" section) uses `gloo_gateway_*`-prefixed metric names for the XDS panels (e.g. `gloo_gateway_xds_streams_insync`, `gloo_gateway_xds_syncs_total`). These were ported from the older `gloo-gateway.json` dashboard and may differ from the actual metric names emitted by the current Solo Enterprise for kgateway build. Verify against a running cluster and update the PromQL expressions if needed.

---

## Phase 2 — Monetization

The next major phase after API Analytics: consumption-based plans, pricing tiers, and billing integration. See `rfes/api-analytics-and-monetization/` for the original RFE context.

Planned scope (to be designed):
- Consumption plans attached to API Products (request quotas, rate limits by tier)
- Pricing model definition (per-request, per-month, tiered)
- Usage aggregation from ClickHouse into a billing summary
- Billing dashboard in Grafana (cost per application / API product)
- Integration with an external billing provider (TBD)
