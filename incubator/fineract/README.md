# Fineract

Ever wanted to deploy a [Fineract Stack](http://fineract.apache.org/) on Kubernetes?

## TL;DR;

```console
$ helm install stable/fineract
```

## Introduction

This chart bootstraps a [Fineract Stack](http://fineract.apache.org/) deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.
It was designed in a very modular and transparent way. Instead of using a custom built docker container running multiple services like Apache Http and Tomcat inside with no control or overwatch of these processes from within kubernetes, this chart takes the approach of using one service per container.

The charts default configurations were made with performance in mind.

By default the chart is exposed to the public via LoadBalancer IP but exposing the chart via an ingress controller is also supported. If a working [lego container](https://github.com/jetstack/kube-lego) is configured the chart supports creating lets encrypt certificates.

Once you've set up your website, you'd like to have separate development environments for testing? Don't worry, with one additional setting you can [clone an existing release](#cloning-charts) without downtime using the [xtrabackup](https://www.percona.com/software/mysql-database/percona-xtrabackup) [init container](https://hub.docker.com/r/lead4good/xtrabackup/).

Official containers are used wherever possible ( namingly [tomcat](https://hub.docker.com/_/tomcat/), [apache](https://hub.docker.com/_/httpd/), [mysql](https://hub.docker.com/_/mysql/), [mariadb](https://hub.docker.com/_/mariadb/) and [percona](https://hub.docker.com/_/percona/) ) .

## Prerequisites

- Kubernetes 1.9+
- LoadBalancer support or Ingress Controller

## Installing the Chart

To install the chart with the release name `my-release`:

```console
$ helm install --name my-release stable/fineract
```

The command deploys the Fineract chart on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Examples

To try out one of the [examples](examples/). you can run, e.g. for mifos:

```console
$ helm install -f examples/mifos.yaml --name mifos stable/fineract
```

Currently you can try the following examples:

* [examples/mifos.yaml](examples/mifos.yaml)
* [examples/mifos-ingress-ssl.yaml](examples/mifos-ingress-ssl.yaml)
* [examples/mifos-web-conf.yaml](examples/mifos-web-conf.yaml)


## Configuration

The following tables list the configurable parameters of the Mifos chart and their default values.

You can specify each of the parameters using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --name my-release \
  --set init.clone.release=my-first-release-fineract,fineract.oldHTTPRoot=/var/www/my-website.com \
    stable/mifos
```

The above command sets up the chart to create its persistent contents by cloning its content from `my-first-release-mifos` and sets an old http root to compensate for absolute path file links

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --name my-release -f values.yaml stable/fineract
```

> **Tip**: You can use the default [values.yaml](values.yaml) file as a template

### Manually preparing the webroot and database

The manual init container enables you to manually pull a websites backup from somewhere and set it up inside the container before the chart is deployed. Set `init.manually.enabled` to `true` and connect to the container by replacing `example-org-fineract` and executing

```console
$ kubectl exec -it \
  $(kubectl get pods -l app=example-org-fineract --output=jsonpath={.items..metadata.name}) \
  -c init-manually /bin/bash
```

The container has the document root mounted at `/var/www/html` and the database directory mounted at `/var/lib/mysql` . The default manual init container is derived from the official [mysql](https://hub.docker.com/_/mysql/) container and can create and startup a mysql db by setting the necessary environment variables and then executing

```console
$ /entrypoint.sh mysqld &
```

If another flavor of DB is used ([mariadb](https://hub.docker.com/_/mariadb/) or [percona](https://hub.docker.com/_/percona/)) then the repository and tag need to be pointing to the right container.

After setting up your DB backup you can stop the database by executing
```console
$ mysqladmin -uroot -p$MYSQL_ROOT_PASSWORD shutdown
```

Now copy all necessary files into the web directory, but do not forget to recursively chown the webroot to the `www-data` user ( id 33 ) by executing

```console
$ chown -R 33:33 /var/www/html
```

Once everything is setup stopping the init container is done by executing
```console
$ im-done
```

| Parameter | Description | Default |
| - | - | - |
| `init.manually.enabled` | Enables container for manual initialization | false |
| `init.manually.repository` | Containers repository | lead4good/init-wp |
| `init.manually.tag` | Repository tag | latest |
| `init.manually.pullPolicy` | Image pull policy | Always |

### Cloning charts

If `init.clone.release` is set to the fullname of an existing, already running Fineract chart (e.g. `example-org-fineract`), the persistent storage of that chart (web files and db) will be copied to this charts persistent storage. It is mandatory that both database containers are of the same type ([mysql](https://hub.docker.com/_/mysql/), [mariadb](https://hub.docker.com/_/mariadb/) or [percona](https://hub.docker.com/_/percona/)). Mixing them will not work.

| Parameter | Description | Default |
| - | - | - |
| `init.clone.release` | Fullname of the release to clone | _empty_ |
| `init.clone.hostPath` | If the release to clone uses hostPath instead of PVC, set it here. This will only work if both releases are deployed on the same node | _empty_ |

### Init Containers Resources

| `init.resources` | init containers resource requests/limits | `resources` |

### Tomcat and HTTPD Containers

The Tomcat container is at the heart of the Fineract chart. By default, the Fineract chart uses the official Tomcat container from docker hub with Tomcat version 8.5. You can also use your own Tomcat container, which needs to have the official Tomcat container at its base.

| Parameter | Description | Default |
| - | - | - |
| `tomcat.version` | default tomcat repository version, you can specify a different version like 8 or 8.8 | 8 |
| `tomcat.repository` | If not empty, repository is chosen over default tomcat repo | _empty_ |
| `tomcat.tag` | Repository tag | _empty_ |
| `tomcat.pullPolicy` | Image pull policy | Always |
| `tomcat.oldHTTPRoot` | Additionally mounts the webroot at `tomcat.oldHTTPRoot` to compensate for absolute path file links  | _empty_ |
| `server.xml` | additional tomcat config values, see examples on how to use | _empty_ |
| `tomcat.copyRoot` | if true, copies the containers web root `/var/www/html` into persistent storage. This must be enabled, if the container already comes with files installed to `/var/www/html`  | false |
| `tomcat.persistentSubpaths` | instead of enabling persistence for the whole webroot, only subpaths of webroot can be enabled for persistence.  | _empty_ |
| `tomcat.resources` | tomcat container resource requests/limits | `resources` |
| `httpd.resources` | HTTPD container resource requests/limits | `resources` |

### MySQL Container

The MySQL container is disabled by default, any container with the base image of the official [mysql](https://hub.docker.com/_/mysql/), [mariadb](https://hub.docker.com/_/mariadb/) or [percona](https://hub.docker.com/_/percona/) should work.

| Parameter | Description | Default |
| - | - | - |
| `mysql.rootPassword` | Sets the MySQL root password, enables MySQL service if not empty | _empty_ |
| `mysql.user` | MySQL user | _empty_ |
| `mysql.password` | MySQL user password | _empty_ |
| `mysql.database` | MySQL user database | _empty_ |
| `mysql.repository` | MySQL repository - choose one of the official [mysql](https://hub.docker.com/_/mysql/), [mariadb](https://hub.docker.com/_/mariadb/) or [percona](https://hub.docker.com/_/percona/) images | mysql |
| `mysql.tag` | Repository tag | 5.7 |
| `mysql.imagePullPolicy` | Image pull policy | Always |
| `mysql.sockets` | Enables communication between MySQL and tomcat via sockets instead of TCP | true |
| `mysql.resources` | Resource requests/limits | `resources` |

### Default Resources

Default resources are used by all containers which have no custom resources configured.

| Parameter | Description | Default |
| - | - | - |
| `resources.requests.cpu` | CPU resource requests | 1 |
| `resources.requests.memory` | Memory resource requests | 1Mi |
| `resources.limits.cpu` | CPU resource limits | _empty_ |
| `resources.limits.memory` | Memory resource limits | _empty_ |

### Persistence

If `persistence` is enabled, PVC's will be used to store the web root and the db root. If a pod then is redeployed to another node, it will restart within seconds with the old state prevailing. If it is disabled, `EmptyDir` is used, which would lead to deletion of the persistent storage once the pod is moved. Also cloning a chart with `persistence` disabled will not work. Therefor persistence is enabled by default and should only be disabled in a testing environment. In environments where no PVCs are available you can use `persistence.hostPath` instead. This will store the charts persistent data on the node it is running on.

| Parameter | Description | Default |
| - | - | - |
| `persistence.enabled` | Enables persistent volume - PV provisioner support necessary | true |
| `persistence.keep` | Keep persistent volume after helm delete | false |
| `persistence.accessMode` | PVC Access Mode | ReadWriteOnce |
| `persistence.size` | PVC Size | 5Gi |
| `persistence.storageClass` | PVC Storage Class | _empty_ |
| `persistence.hostPath` | if specified, used as persistent storage instead of PVC | _empty_ |

### Network

To be able to connect to the services provided by the Fineract chart, a Kubernetes cluster with working LoadBalancer or Ingress Controller support is necessary.
By default the chart will create a LoadBalancer Service, all services will be available via LoadBalancer IP through different ports. You can set `service.type` to ClusterIP if you do not want your chart to be exposed at all.
If `ingress.enabled` is set to true, the Fineract charts services are made accessible via ingress rules. Those services which are not provided by HTTP protocol via `nodePorts`. In ingress mode the Fineract chart also supports ssl with certificates signed by lets encrypt. This requires a working [lego](https://github.com/jetstack/kube-lego) container running on the cluster.

> **Note**: In ingress mode it is mandatory to set `ingress.domain`, otherwise the ingress rules won't know how to route the traffic to the services.

| Parameter | Description | Default |
| - | - | - |
| `service.type` | Changes to ClusterIP automatically if ingress enabled | LoadBalancer |
| `service.HTTPPort` | Port to advertise the main web service in LoadBalancer mode | 80 |
| `ingress.enabled` | Enables ingress support - working ingress controller necessary | false |
| `ingress.domain` | domain to advertise the services - A records need to point to ingress controllers IP | _empty_ |
| `ingress.subdomainWWW` | enables www subdomain and 301 redirect from domain. Requires nginx ingress controller. | false |
| `ingress.ssl` | Enables [lego](https://github.com/jetstack/kube-lego) letsencrypt ssl support - working nginx controller and lego container necessary | false |
| `ingress.htpasswdString` | if specified main web service requires authentication. Requires nginx ingress controller. Format: _user:$apr1$F..._ | _empty_ |
| `ingress.annotations` | specify custom ingress annotations such as e.g. `ingress.kubernetes.io/proxy-body-size` |  |

### Mifos


The Fineract chart offers additional Mifos features during the init stage. It supports two modes, normal mode sets up the chart completely automatic by downloading an InfiniteWP backup from google drive, while the other mode gets executed when in manual mode (see: `init.manually`). While in manual mode, the web files and db backup need to be manually downloaded and stashed in the appropriate folders (`/var/www/html` <-- web root, `/var/www/mysql` <-- sql backup). The automatic mode does this automatically. Both modes then import the backup and do some necesssary config file changes. So even in manual mode it is not necessary to import the db backup.

In development mode everything that gets executed in normal mode will also get executed. 

| Parameter | Description | Default |
| - | - | - |
| `mifos.enabled` | Enables mifos normal mode | false |
| `mifos.gdriveRToken` | gdrive rtoken for authentication used for downloading InfiniteWP backup from gdrive | _empty_ |
| `mifos.gdriveFolder` | gdrive backup folder - the latest backup inside of the folder where the name includes the string `_full` will be downloaded | `mifos.domain` |
| `mifos.domain` | mifos domain used in dev mode to be search replaced | _empty_ |
| `mifos.develop.enabled` | enables develop mode | false |
| `mifos.develop.deleteUploads` | deletes `wp_content/uploads` folder and links to live site within htaccess | false |
| `mifos.develop.devDomain` | used to search replace `mifos.domain` to `fullname of template`.`develop.devDomain` e.g `mysite-com-fineract.dev.example.com` | _empty_ |

### Other

| Parameter | Description | Default |
| - | - | - |
| `keepSecrets` | Keep secrets after helm delete | false |
| `replicaCount` | > 1 will corrupt your database if one is used. Future releases might enable elastic scaling via galeradb | 1 |
