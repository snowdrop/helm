Table of Contents
=================

* [Introduction](#introduction)
* [Charts repository](#repository)
  * [List of charts available](#list-of-charts-available)
  * [Usage](#usage)
  * [Development New Chart](#Development/Release-a-new-Chart)
  * [Release Spring Boot Examples](#release-a-new-version-of-Spring-Boot-examples)
  * [Testing](#testing)
* [Templates](#templates)
  * [Role-Based Access Control](#rbac)

# Introduction

This project aims to :
- Host the [Helm index repository](http://snowdrop.github.io/helm/index.yaml) of our Spring Boot examples and their released `chart.tgz` files,
- Propose `best practices` to design charts and resolve problems such as: How to deal with [RBAC](#rbac).

# Repository

This repository uses GitHub Pages to publish the Helm charts index at this address: [http://snowdrop.github.io/helm](http://snowdrop.github.io/helm). To use it locally, you need to execute:

```console
$ helm repo add snowdrop https://snowdrop.github.io/helm
```

And confirm that the snowdrop repository is listed:

```console
$ helm repo list
NAME           	URL                               
snowdrop	    https://snowdrop.github.io/helm
```

## List of charts available

| Chart Name                                                             | Description | Source |
|------------------------------------------------------------------------|-------------| ------ |
| [spring-boot-example-app](#spring-boot-example-app)                    | Chart to be used to create a Spring Boot application | [repository/spring-boot-example-app](repository/spring-boot-example-app) |
| [spring-boot-example-rest-http](#spring-boot-example-rest-http)        | Chart to deploy the Snowdrop Spring Boot REST HTTP example | [https://github.com/snowdrop/rest-http-example](https://github.com/snowdrop/rest-http-example) |
| [spring-boot-example-cache](#spring-boot-example-cache)                | Chart to deploy the Snowdrop Spring Boot Cache example | [https://github.com/snowdrop/cache-example](https://github.com/snowdrop/cache-example) |
| [spring-boot-example-crud](#spring-boot-example-crud)                  | Chart to deploy the Snowdrop Spring Boot CRUD example | [https://github.com/snowdrop/crud-example](https://github.com/snowdrop/crud-example) |
| [spring-boot-example-configmap](#spring-boot-example-configmap)        | Chart to deploy the Snowdrop Spring Boot ConfigMap example | [https://github.com/snowdrop/configmap-example](https://github.com/snowdrop/configmap-example) |
| [spring-boot-example-health-check](#spring-boot-example-health-check)  | Chart to deploy the Snowdrop Spring Boot Health Check example | [https://github.com/snowdrop/health-check-example](https://github.com/snowdrop/health-check-example) |
| [spring-boot-example-circuit-breaker](#spring-boot-example-circuit-breaker)  | Chart to deploy the Snowdrop Spring Boot Circuit Breaker example | [https://github.com/snowdrop/circuit-breaker-example](https://github.com/snowdrop/circuit-breaker-example) |
| [spring-boot-example-messaging-queue](#spring-boot-example-messaging-queue)  | Chart to deploy the Snowdrop Spring Boot Messaging Queues example | [https://github.com/snowdrop/messaging-work-queue-example](https://github.com/snowdrop/messaging-work-queue-example) |

## Usage

Requirements:
- Connected/logged to a Kubernetes/OpenShift cluster
- Have installed [the Helm command line](https://helm.sh/docs/intro/install/)

### spring-boot-example-app

This chart deploys and exposes a Spring Boot application on Kubernetes or OpenShift.

- For Kubernetes:
To use it on Kubernetes, the image of the Spring Boot application needs to be published on an images registry where you have access and be logged. In this example, we'll use the image `quay.io/user/my-app:latest`. To install it, you need to execute the following command:

```console
$ helm install my-spring-boot-app snowdrop/spring-boot-example-app --set name=app --set docker.image=quay.io/user/my-app:latest --set ingress.host=<your kubernetes domain>
```

**note**: if you want to expose your application on Kubernetes, you need to provide the `ingress.host` property.

- For OpenShift, to install it, you need to execute the following command:

```console
$ helm install my-spring-boot-app snowdrop/spring-boot-example-app --set name=app --set s2i.source.repo=http://github.com/org/repo --set s2i.source.ref=main --set route.expose=true
```

When you install the chart on OpenShift, a pod is created to build the Spring Boot application using as source the GIT repository cloned and the maven tool. The jar file generated will be copied to an image and pushed to a registry.

**note**: Properties like the S2i base image are defined in the default [`values.yaml`](repository/spring-boot-example-app/values.yaml) file. You can override these values using the `--set` option.

You can watch the progression of the build and deployment using a `watch` command:

```console
$ watch oc get pods
app-1-build     0/1     Completed   0          7m30s
app-1-deploy    0/1     Completed   0          5m27s
app-1-j5jk5     1/1     Running     0          5m25s
```

**note**: OpenShift may take a bit to download the images before triggering the S2i build. 

The pod with name `app-1-build` is automatically triggered by S2i to build the Spring Boot application. After the build is finished, the pod `app-1-deploy` will create the image that then will be used by the pod `app-1-j5jk5` to deploy the application.

As soon as status of the pods `app-1-build` and `app-1-deploy` are completed and that the status of the `app-1-j5jk5` is running, we can now execute the following command get the route of the Service to access it:

```console
$ oc get routes
NAME            HOST/PORT                                       PATH   SERVICES        PORT   TERMINATION   WILDCARD
app             app-xxxx.containers.appdomain.cloud             /      app             8080                 None
```

Finally, our application will be available at `app-xxxx.containers.appdomain.cloud`.

#### Using `spring-boot-example-app` as dependency in custom charts

Let's see how to create a custom chart that deploys one or more Spring Boot applications at once by using the chart `spring-boot-example-app` as dependency.

Our custom chart will deploy two Spring Boot applications at once. To start with, we will first deploy one Spring Boot application and then we'll see how to deploy the second Spring Boot application.

You first need to generate a chart directory using the following command:

```console
$ mkdir my-custom-chart
$ cd my-custom-chart
```

Now, let's create the `Chart.yaml` file under the `my-custom-chart/` folder with your Chart information:

```yaml
apiVersion: v2
name: my-custom-chart
version: 0.0.1
description: A chart that deploys multiple Spring Boot applications
```

And let's also create an empty file with name `values.yaml` under the `my-custom-chart/` folder:

```console
$ touch values.yaml
```

At this point, your chart directory `my-custom-chart` should have the following structure:

```
my-custom-chart
│   Chart.yaml
│   values.yaml
```

Now, we're going to deploy the first Spring Boot application by adding the `spring-boot-example-app` chart as dependency. We need to append the [dependencies](https://helm.sh/docs/topics/charts/#chart-dependencies) section within the `my-custom-chart/Chart.yaml` file:

```yaml
apiVersion: v2
name: my-custom-chart
version: 0.0.1
description: A chart that deploys multiple Spring Boot applications
# Chart dependencies:
dependencies:
  - alias: firstApp
    name: spring-boot-example-app
    version: 0.0.3
    repository: http://snowdrop.github.io/helm
```

When done, execute this command to download the dependency: 
```console
$ helm dependency update
```

After doing this, helm will download the `spring-boot-example-app` chart from the repository `http://snowdrop.github.io/helm` and will copy the Chart tallball `spring-boot-example-app-0.0.3.tgz` at `my-custom-chart/charts/`.

As the build is taking place on the cluster using OpenShift - see [usage section](#spring-boot-example-app), then we have to configure the `s2i` fields defined within the `my-custom-chart/values.yaml` file:

```yaml
firstApp: # match with the alias name
  name: my-first-app
  version: 0.0.1
  route:
    expose: true
  s2i:
    source:
      repo: http://github.com/org/repo
      ref: main
```

If you are using Kubernetes, then you would need to build and publish the docker image and next configure the `docker.image` field within the `my-custom-chart/values.yaml`:

```yaml
firstApp: # match with the alias name
  name: my-first-app
  version: 0.0.1
  ingress:
    host: <your k8s domain>
  docker:
    image: quay.io/user/my-app:latest
```

Let's install our custom chart by executing the following command:

```console
$ helm install my-custom-chart .
```

Helm will deploy the Spring Boot application and expose the application.

Now, we're going to update our custom chart to deploy the second Spring Boot application. For doing this, we need to declare another dependency within the `my-custom-chart/Chart.yaml` file:

```yaml
apiVersion: v2
name: my-custom-chart
version: 0.0.1
description: A chart that deploys multiple Spring Boot applications
# Chart dependencies:
dependencies:
  - alias: firstApp
    name: spring-boot-example-app
    version: 0.0.3
    repository: http://snowdrop.github.io/helm
  - alias: secondApp
    name: spring-boot-example-app
    version: 0.0.3
    repository: http://snowdrop.github.io/helm
```

And, again, we need to edit the `my-custom-chart/values.yaml` file and provide the correct configuration for the second application. For example, for OpenShift this file would look like as:

```yaml
firstApp:
  name: my-first-app
  version: 0.0.1
  route:
    expose: true
  s2i:
    source:
      repo: http://github.com/org/repo
      ref: main
secondApp:
  name: my-second-app
  version: 0.0.1
  route:
    expose: true
  s2i:
    source:
      repo: http://github.com/org/another-repo
      ref: main
```

Let's update our custom chart to deploy both Spring Boot applications by executing the following command:

```console
$ helm upgrade my-custom-chart .
```

After the deployment is finished, we will see two Spring Boot applications up and running.

### spring-boot-example-rest-http

This chart deploys the example from [the repository](https://github.com/snowdrop/rest-http-example). This example shows how to map business operations to a remote procedure call endpoint over HTTP using a REST framework. This corresponds to Level 0 in the Richardson Maturity Model. Creating an HTTP endpoint using REST and its underlying principles to define your API lets you quickly prototype and design the API flexibly.

```
helm install rest-http snowdrop/spring-boot-example-rest-http
```

### spring-boot-example-cache

This chart deploys the example from [the repository](https://github.com/snowdrop/cache-example). This example demonstrates how to use a cache to increase the response time of applications.

```
helm install cache snowdrop/spring-boot-example-cache
```

### spring-boot-example-crud

This chart deploys the example from [the repository](https://github.com/snowdrop/crud-example). This example expands on the REST API Level 0 application to provide a basic example of performing create, read, update and delete (CRUD) operations on a PostgreSQL database using a simple HTTP API. CRUD operations are the four basic functions of persistent storage, widely used when developing an HTTP API dealing with a database.

```
helm install crud snowdrop/spring-boot-example-crud
```

### spring-boot-example-configmap

This chart deploys the example from [the repository](https://github.com/snowdrop/configmap-example). This example uses a ConfigMap to externalize configuration. 

```
helm install configmap snowdrop/spring-boot-example-configmap
```

### spring-boot-example-health-check

This chart deploys the example from [the repository](https://github.com/snowdrop/health-check-example). This example demonstrates the health check pattern through the use of probing. Probing is used to report the liveness and readiness of an application.

```
helm install health-check snowdrop/spring-boot-example-health-check
```

### spring-boot-example-circuit-breaker

This chart deploys the example from [the repository](https://github.com/snowdrop/circuit-breaker-example). This example demonstrates a generic pattern for reporting the failure of a service and then limiting access to the failed service until it becomes available to handle requests. This helps prevent cascading failure in other services that depend on the failed services for functionality.

```
helm install circuit-breaker snowdrop/spring-boot-example-circuit-breaker
```

### spring-boot-example-messaging-queue

This chart deploys the example from [the repository](https://github.com/snowdrop/messaging-work-queue-example). This example demonstrates how to dispatch tasks to a scalable set of worker processes using a message queue. It uses the AMQP 1.0 message protocol to send and receive messages.

```
helm install messaging snowdrop/spring-boot-example-messaging-queue
```
## Development/Release a new Chart

To add a new chart to the repository, follow these steps:
1. Add the new chart folder under `repository/<new chart name>`
2. Update the [Makefile](Makefile) file to add the new repository name in the `CHARTS` array
3. Run `make release` from the root repository folder

## Release a new version of Spring Boot examples

1. Run `make release-examples branch=<SPRING BOOT EXAMPLE BRANCH> chartVersion=<NEW CHART VERSION>` from the root repository folder. 
Example: `make release-examples branch=sb-2.5.x chartVersion=2.5.8`

## Testing

1. Expose the repository locally using Docker and [ChartMuseum](https://chartmuseum.com/) (utility to serve Helm repositories locally):

```console
$ docker run --rm -u 0 -it -d -p 8080:8080 -e DEBUG=1 -e STORAGE=local -e STORAGE_LOCAL_ROOTDIR=/charts -v $(pwd)/charts:/charts chartmuseum/chartmuseum:latest
```

The helm repository should be now available at `http://localhost:8080`.

2. Add the local repository using `helm repo add local http://localhost:8080`. Verify that the local chart is in the local repository `helm search repo local`.
3. Finally, update the `rest-http/Chart.yaml` file to register the dependency:

```yaml
apiVersion: v2
name: rest-http
description: A Helm chart for Kubernetes
# Chart dependencies:
dependencies:
  - name: spring-boot-example-app
    version: 0.0.1
    repository: http://localhost:8080 # Helm local repository
```
Now, use the chart as stated in the [usage section](#usage).

# Templates

## RBAC

To generate the files using the `template` command
```console
$ helm template rbac ./rbac --dry-run --output-dir ./generated
```