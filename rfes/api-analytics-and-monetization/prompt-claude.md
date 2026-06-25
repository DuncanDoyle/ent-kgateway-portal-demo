# API Analytics and Monetization - Claude prompt

Since Enterprise kgateway 2.2.0, the product now ships with a Developer Portal. I have a local Portal demo project here: /Users/ddoyle/Development/github/ent-kgw-portal-demo

That demo project simply installs kgateway and the Portal via helm charts, deploys a Gateway, deploys Keycloak, deploys a Portal (and some peripheral components like an RDBMS, pgadmin and the gloo-portal-ipd-connect connector which integrates Portal with Keycloak for Oauth self-service) and a Portal UI (React app)

It deploys APIs and APIProducts, including their HTTPRoutes. It can also deploy multiple different AuthN/AuthZ policies and RateLimiting policies to demonstrate credential self-service and (dynamic) rate-limiting.

One thing that customers and prospects keep bringing up is "API Analytics and Monetization". Our current story around this is that we gather API call information via the Envoy access-logs (configured via a
ListenerPolicy) and that we can ship that information via Open Telemetry to a datastore of choice, after which it can be used by other platforms for Analytics and Monetization.

As part of our demo, I want to add an "API Analytics and Monetization" demo to the mix. First of all to show customers and prospect how this can be implemented, but second, having an API Analytics UI (console,
dashboard) would greatly improve the demo itself.

I think we need to do a number of things to accomplish this:
- Deploy and configure the OpenTelemetry infrastructure
- Deploy a datastore in which we can collect the API consumption data and metadata. In other parts of our portfolio we use Clickhouse a lot. Clickhouse was also the datastore we used in the Gloo Mesh Gateway Portal to store this kind of information (you can look at the Gloo Mesh Enterpise codebase at /Users/ddoyle/Development/github/solo-io/gloo-mesh-enterprise to see how that was done. I think we actually provided a Grafana dashboard to visualize this in this GMG Portal demo: /Users/ddoyle/Development/github/gp-portal-demo).
- Design, configure and deploy an OTEL pipeline that ships the API consumption data from the Envoy access logs to the datastore.
- A dashboard platform to display the API consumption data from the datastore and which can provide some analytics dashboards. We used Grafana for this in the past, but if there are other (better) options, we should look at those as well).

Monetization should be a phase 2 IMO, as this would probably require us to implement some other features like "consumption plans", "pricing", etc. Although I would like to include it in our overall plan, I want to start with the API Analytics part first, and only start the design and implementation work of the monetization part (which would also need the API consumption data btw) at a later stage.