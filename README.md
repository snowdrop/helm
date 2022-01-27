Table of Contents
=================

* [Introduction](#introduction)
* [Charts repository](#repository)
  * [Available Charts in Repository](#available-charts-in-repository)
  * [Usage](#usage)
  * [Development](#development)
  * [Testing](#testing)
* [Templates](#templates)
  * [Role-Based Access Control](#rbac)

# Introduction

This project aims to :
- Host the [Helm index repository](http://snowdrop.github.io/helm/index.yaml) of our Spring Boot examples and their released `chart.tgz` files,
- Propose `best practices` to design charts and resolve problems such as: How to deal with [RBAC](#rbac).

# Repository

The repository uses GitHub Pages to expose the Helm charts at (http://snowdrop.github.io/helm)[http://snowdrop.github.io/helm]. To use it, you need to execute:

```console
$ helm repo add snowdrop http://snowdrop.github.io/helm
```

And confirm that the snowdrop repository is listed:

```console
$ helm repo list
NAME           	URL                               
snowdrop	    http://snowdrop.github.io/helm
```

## Available Charts in Repository

| Chart Name                     | Description | Configuration |
|--------------------------------|-------------| --------------|
| spring-boot-example-app        | Chart to be used by the Snowdrop Spring Boot examples | [values.yaml](repository/spring-boot-example-app/values.yaml) |

## Usage

To use one of the available charts, for example `spring-boot-example-app`, you first need to generate your chart:

```console
$ helm create rest-http
```

The `create` command will generate the following file structure:

```
rest-http
│   Chart.yaml
│   values.yaml
|
└───charts
└───templates
│   │   ...
```

Now, you need to add the `rest-http/requirements.yaml` file to register the dependency:

```yaml
dependencies:
  - name: spring-boot-example-app
    version: 0.0.1
    repository: http://snowdrop.github.io/helm
```

Now, download the dependencies using: 
```console
$ helm dependency update
```

Configure the template accordingly using the chart name as root element:

```yaml
spring-boot-example-app: # This is the chart name from the dependencies!
  name: rest-http
  version: 2.5.0-0-SNAPSHOT
  s2i:
    source:
      repo: https://github.com/snowdrop/rest-http-example
      ref: sb-2.5.x
```

And, install your helm:
```console
$ helm install rest-http .
```

## Development

To add a new chart in the repository, you need to follow the following steps:
1. Add the new chart under `repository/<new chart name>`
2. Update the [Makefile](Makefile) file to add the new repository name in the `CHARTS` array
3. Run `make release` from the root repository folder

## Testing

1. Expose the repository locally using Docker and [ChartMuseum](https://chartmuseum.com/) (utility to serve Helm repositories locally):

```console
docker run --rm -u 0 -it -d -p 8080:8080 -e DEBUG=1 -e STORAGE=local -e STORAGE_LOCAL_ROOTDIR=/charts -v $(pwd)/charts:/charts chartmuseum/chartmuseum:latest
```

The helm repository should be now available at `http://localhost:8080`.

2. Add the local repository using `helm repo add local http://localhost:8080`. Verify that the local chart is in the local repository `helm search repo local`.
3. Finally, update the `rest-http/requirements.yaml` file to register the dependency:

```yaml
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