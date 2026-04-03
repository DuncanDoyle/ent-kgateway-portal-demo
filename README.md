# Enterprise KGateway Portal Demo

## Installation

All installation and setup scripts can be found int the `./install` directory.

```
cd install
```

Optional: Configure CoreDNS to route keycloak.example.com through the gateway. This is needed when keycloak's DNS name is not a registered DNS that is routable by both the front-end (UI) and backend (kgateway). Using CoreDNS, we route the keycloak.example.com hostname to the gateway, which routes it to out kgateway service on our Kubernetes cluster.

```
./k8s-coredns-config.sh
```

> [NOTE!]
> The KGateway version that will be installed is set in a variable in the `install/env.sh` script.


Install Solo Enterprise for kgateway. This will also install Keycloak.
```
install-ent-kgateway-with-helm.sh
```

Install PostreSQL for Portal
```
install-portal-postgres.sh
```

Install pgAdmin PostgreSQL UI
```
install-pgadmin.sh
```

Configure Keycloak kgatewat and portal management realms
```
keycloak-kgateway-demo-realm.sh
keycloak-portal-mgtm-realm.sh
```

Install Portal IDP Connect which integrates the Portal WebServer with the (in our case) Keycloak IdP
```
install-portal-idp-connect.sh
```

Install the Portal CRDs and Controller
```
install-portal-with-helm.sh
```

Setup the Portal WebServer, Frontend UI and routes.
```
setup-portal.sh
```

## Gateway and Hostname configuration

In a local setup, the hostnames used in this demo, e.g.:
- developer.example.com
- keycloak.example.com
- api.example.com
- pgadmin.example.com

should be configured to route to the `gw` in the `ingress-gw` namespace. This kgateway gateway-proxy serves the routing for all applications in this demo, the Portal Frontend, Portal Backend, Keycloak, APIProducts, etc. In a local demo, this can be configured by port-forwarding the gateway-proxy:

```
sudo kubectl -n ingress-gw port-forward deployments/gw 80:80
```

and configuring all hostnames in `/etc/hosts` to route to `127.0.0.1`.


## Authentication & Authorization

Kgateway Portal supports both API-Key and OAuth based credential self-service. These credentials can be created in the context of an "Application", which can be created through the Portal UI (http://developer.example.com).

To configure API-Key AuthN or OAuth AuthN, we've provided the necessary scripts in the `install` directory which will register the required `AuthConfig`, `RateLimitConfig` and `EnterpriseKgatewayTrafficPolicy` to secure the route to your APIPrdouct.

Setup APIKey Auth:

```
setup-apiproducts-apikey.sh
```

Setup OAuth Auth:
```
setup-apiproducts-oauth.sh
```

The scripts will remove the other AuthN flavor if already installed. E.g. when you setup the OAuth AuthN via the script, the script will remove the APIKey AuthN if already installed. 

APIKey an OAuth AuthN can be removed using the scripts `remove-apiproducts-apikey.sh` and `remove-apiproducts-oauth.sh`.    


# Demo Walkthrough

- Open the Portal UI (Frontend) at http://developer.example.com.
- Press the "Login" button in the top right, which will redirect you to Keycloak. Login with username `user1` and password `password`.
- Navigate to the API view. Observe that there are no APIs deployed.
- Deploy the HTTPBin APIProduct via the `setup-httpbin-apiproduct.sh` script located in the `install` directory.
- After the HTTPBin application and routes have been succesfully deployed, the HTTPBin APIProduct will be show in the API view.
- Click on the HTTPBin APIProduct to view its details. 
- On the right side of the screen, click on "Swagger View" to open the Swagger UI. Observe that the paths in the OpenAPI spec are generated (stitched) from the HTTPRoute configurations in the `api-example-com-root-route` and the `httpbin-apiproduct` HTTPRoutes
- In the Swagger UI, expand the `GET /httpbin/v1.0/get` operation, and use the "Try it out" button to try out this API. You should get a 200 response from the HTTPBin API.
- Configure the APIKey AuthN/AuthZ using the `setup-apiproducts-apikey.sh` script in the `install` directory. This will deploy the AuthConfig, RateLimitConfig and EnterpriseKgatewayTrafficPolicy that configure API-Key based AuthN/AuthZ for the API Products.
- Try to execute the `GET /httpbin/v1.0/get` API again. This time you will get a 403, as an APIKey. Also note that the Swagger view has an "Authorize" button at the top right.
- To create an API-Key, first create a Team in the "Teams view". Within that Team, create an Application. Once you've created your Application, you can now create an API-Key from the "Applciations view".
- In your Application view, click on "Add API Key" to create a new API-Key. Store the key in a secure location, it will only be shown once.
- Go back to your HTTPBin APIProduct Swagger UI. Click on the "Authorize" button, type or paste your API-Key and click "Authorize"
- Try to execute the `GET /httpbin/v1.0/get` API again. You will still get a 403! The reason for this is that you're not yet subscribed to API Product.
- Go back to your Application view. At the bottom of the screen you will see a section call "API Subscriptions". Click on "Add Subscription", select the HTTPBin APIProduct and click on "Create Subscription".
- A new Subscription will be shown with the status "Pending". The Subscription still needs to be approved by a Portal administrator.
- Open another browser and navigate to http://developer.example.com. Click on the "Login" button to login via Keycloak, but this time login with username `admin` and password `admin`.
- You will now see the Admin view of the Portal UI. Click on "Subscriptions" to navigate to the Subscriptions view. You will see the pending HTTPBin subscription that you've created earlier as `user1`.
- In the HTTPBin subscription card, click on "Approve" to approve the subscription.
- Navigate back to the browser of `user1`. In the Application view, you will see that the status of the HTTPBin subscription has changed from "Pending" to "Approved".
- Go back to your HTTPBin APIProduct Swagger UI. Click on the "Authorize" button, type or paste your API-Key and click "Authorize"
- Try to execute the `GET /httpbin/v1.0/get` API again. This time you will get a "200" response and you will see the result from the HTTPBin applcation, as you've authenticated with the API-Key you created earlier and authorized with the APIProduct subscription.

*TODO*: Describe OAuth AuthN/AuthZ flow.


# Other Demo Options

The "Demo Walkthrough" shows the basic demo steps this demo provides. The demo however provides additional APIProducts with more complex configurations. E.g. the "Petstore" APIProduct composes 3 APIs from 3 different microservices into a single APIProduct using Portal's sticting technology. The "Tracks" APIProduct defines multiple versions of the APIProduct, both exposed via individual HTTPRoutes.

Both APIProducts can be deployed via scripts in the `install` directory:

- `setup-petstore-apiproduct.sh`
- `setup-tracks-apiproduct.sh`