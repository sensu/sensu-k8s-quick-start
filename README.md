# Getting Started with Sensu Go on Kubernetes

## Overview

This repo contains instructions that can be used to deploy a Sensu Go cluster and an example application (NGINX) into Kubernetes. 
It also includes configuration to reuse Nagios-style monitoring checks to monitor the example application using Sensu Go (a Sensu sidecar is included in the example application deployment YAML).

_NOTE: this guide is a work in progress; see [#TODO](#todo) for more information._

Contents: 

- [Deploy Sensu](#deploy-sensu)
- [Monitor Kubernetes workloads using a Sensu Agent sidecar]()
- [Customization and troubleshooting]()
- [Roll your own Sensu Agent sidecar container images]()
- [Install custom CA certificates for private Sensu Asset servers]()
- [Use SSD persistent disks for Etcd]()

## Deploy Sensu 

1. **Deploy a Sensu staging environment (Kubernetes Statefulset).**

   Create a Sensu namespace and deploy a Sensu cluster using `kubectl`:

   ```shell
   $ kubectl create namespace sensu-system
   namespace/sensu-system created
   $ kubectl --namespace sensu-system apply -f kubernetes/sensu-backend.yaml
   service/sensu created
   service/sensu-lb created
   statefulset.apps/sensu-etcd created
   statefulset.apps/sensu-backend created
   job.batch/sensu-backend-init created
   ```

	 _NOTE: This will spin up three `sensu-backend-X` pods, it may take a couple moments..._

1. **Verify your Sensu staging environment**.

   Obtain the Sensu backend load balancer IP address using `kubectl`:

   ```shell
   $ kubectl get services --namespace sensu-system
   NAME         TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                      AGE
   sensu-etcd   ClusterIP      None           <none>            2379/TCP,2380/TCP                            5m
   sensu-lb     LoadBalancer   10.10.10.10    123.123.123.123   8080:30487/TCP,8081:30991/TCP,80:32339/TCP   5m
   ```

   _NOTE: the IP address you need is the `EXTERNAL-IP` for the `sensu-lb` service (e.g. "123.123.123.123")._

   You should be able to visit the Sensu dashboard via the Sensu backend load balance IP address, as obtained above (e.g. http://123.123.123.123). 
   Sensu does not use a default username and password – cluster administrator access credentials are configured during cluster initialization (see [`sensu-backend init`][backend-init]). 
   If you have not modified the Kubernetes Batch Job provided in `kubernetes/sensu-backend.yaml`, the cluster admin username is `sensu` and the password is `sensu`.

1. **Download and configure `sensuctl`**.
   
   Please visit https://sensu.io/downloads to download the Sensu CLI (`sensuctl`) for your workstation.

   Once installed, you may configure `sensuctl` using this IP address you obtained in the previous step.
   
   ```shell
   $ sensuctl configure
   ? Authentication method: username/password
   ? Sensu Backend URL: http://123.123.123.123:8080
   ? Namespace: default
   ? Preferred output format: tabular
   ? Username: sensu
   ? Password: *****
   ```

   To test your `sensuctl` configuration, run the following command:

   ```shell
   $ sensuctl cluster id
   sensu cluster id: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   ```

   _BONUS: go visit https://sensu.io/register to register your Sensu deployment and earn cool swag! :tada:_
   
   [backend-init]: https://docs.sensu.io/sensu-go/latest/observability-pipeline/observe-schedule/backend/#initialization

## Monitor Kubernetes workloads using a Sensu Agent sidecar
   
1. **Configure Sensu agent sidecar.**

   Deploy an example application with a Sensu Agent sidecar. 
   The attached example uses an NGINX container as a generic web service deployment with a Sensu Agent sidecar.

   ```shell
   $ kubectl create namespace example-application
   namespace/example-application
   $ kubectl --namespace example-application apply -f kubernetes/example-nginx-deployment.yaml
   service/nginx created
   configmap/nginx-config created
   deployment.extensions/nginx created
   ```

   _NOTE: see `kubernetes/example-nginx-deployment.yaml` for more information on how to configure a Sensu Agent sidecar._

1. **Configure monitoring check w/ Nagios plugins.**

   Use `sensuctl` to configure a monitoring check using a Nagios C plugin:

   ```shell
   $ sensuctl asset add sensu/monitoring-plugins:2.2.0-4
   fetching bonsai asset: sensu/monitoring-plugins:2.2.0-4
   added asset: sensu/monitoring-plugins:2.2.0-4   
   $ sensuctl create -f sensu/check-nginx.yaml
   ```

   _NOTE: the `sensu/monitoring-plugins` asset is a pre-packaged collection of the Nagios C plugins from the https://monitoring-plugins.org project. 
   Please see https://github.com/sensu/monitoring-plugins for more information. 
   To learn more about Sensu Assets, please visit the [Sensu Documentation][4]; 
   to browse publicly available assets, please visit https://bonsai.sensu.io (the Sensu Asset registry)._

   Now visit your Sensu dashboard to see the results!

   [4]: https://docs.sensu.io/sensu-go/latest/reference/assets/


## Customization and troubleshooting

## Roll your own Sensu Agent sidecar container images

The official Sensu Docker images are based on Alpine Linux. 
If your organization requires all containers to share a standard base image (e.g. RHEL), the following instructions will help you get started building custom Sensu Go agent images. 

1. **Review the example Dockerfiles (OPTIONAL).**

   Both of the provided examples (`Dockerfile.el6` and `Dockerfile.el7`) follow a simple series of installation steps:
   
   - build from a trusted base image (e.g. `centos:6` or `centos:7`)
   - download an official Sensu Go binary archive (see 
     https://sensu.io/downloads for more info)
   - extract the Sensu binaries (including `sensu-agent`) 
   - delete the Sensu binary archive

1. **Create custom Sensu Docker images (OPTIONAL).**

   Create a Sensu Agent Docker image `FROM centos:6`:

   ```shell
   $ SENSU_VERSION=6.2.5 && docker build --build-arg "SENSU_VERSION=$SENSU_VERSION" -t sensu-agent:${SENSU_VERSION}-el6 --file Dockerfile.el6 .
   ```

   Create a Sensu Agent Docker image `FROM centos:7`:

   ```shell
   $ SENSU_VERSION=6.2.5 && docker build --build-arg "SENSU_VERSION=$SENSU_VERSION" -t sensu-agent:${SENSU_VERSION}-el7 --file Dockerfile.el7 .
   ```

1. **Publish custom Sensu Docker images (OPTIONAL).**

   Publish Docker images to a Container Registry (required for use w/ Kubernetes). 
   Container registries vary in implementation, so you'll need to adjust the following command accordingly. 
   The steps typically involve tagging a Docker image with a domain and/or organization or repository name prefix, and then pushing the image.

   Examples:

   - [Docker Hub][1]
   - [AWS Elastic Container Registry][2]
   - [Artifactory On-Prem][3]

   ```shell
   $ SENSU_VERSION=6.2.5 && docker tag sensu-agent:${SENSU_VERSION}-el6 your-repository.com/sensu-agent:${SENSU_VERSION}-el6
   $ SENSU_VERSION=6.2.5 && docker push your-repository.com/sensu-agent:${SENSU_VERSION}-el6
   $ SENSU_VERSION=6.2.5 && docker tag sensu-agent:${SENSU_VERSION}-el6 your-repository.com/sensu-agent:${SENSU_VERSION}-el7
   $ SENSU_VERSION=6.2.5 && docker push your-repository.com/sensu-agent:${SENSU_VERSION}-el7
   ```

   [1]: https://docs.docker.com/docker-hub/repos/
   [2]: https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html
   [3]: https://www.jfrog.com/confluence/display/RTF/Getting+Started+with+Artifactory+as+a+Docker+Registry#GettingStartedwithArtifactoryasaDockerRegistry-GettingStartedwithArtifactoryProOn-Prem

1. **Update your Sensu sidecar configuration to use your custom images**.

   To use a custom Docker image as a Sensu Agent sidecar, you'll need to change the container image reference from `sensu/sensu` (the [official Sensu Docker images][4], hosted on the Docker Hub). 
   Please consult your container registry documentation on how to proceed.

   [4]: https://hub.docker.com/r/sensu/sensu/

### Install custom CA certificates for private Sensu Asset servers

If you are hosting Sensu Assets behind your firewall, you may see an error like the following. 
This error generally indicates that the host is using a custom SSL certificate, but the Sensu Agent host (or container in this case) does not have the CA certificate installed in the host system CA trust store.

```
error getting assets for event: error fetching asset: Get https://artifactory.my-company.com/sensu-assets/check-plugins.tar.gz: x509: certificate signed by unknown authority
```

There are a few way to accomplish this in a Kubernetes environment. 
You can either pre-install the certificate in a custom Docker image by modifying your `Dockerfile` (see above), or you can mount the CA certificate file(s) using a Kubernetes Secret or Kubernetes ConfigMap.

1. **Create a Kubernetes ConfigMap from a CA certificate (e.g. .pem file).**

   ```shell
   $ kubectl create secret generic sensu-asset-server-ca-cert --from-file=path/to/sensu-ca-cert.pem
   ```

2. **Modify the Sensu Agent sidecar config.**

   Update your Sensu Agent sidecar with the following configuration details:

   ```yaml
   volumeMounts:
   - name: sensu-asset-server-ca-cert
     mountPath: /etc/pki/ca-trust/source/anchors/sensu-ca-cert.pem # centos
     subPath: sensu-ca-cert.pem
   - name: sensu-asset-server-ca-cert
     mountPath: /usr/local/share/ca-certificates/sensu-ca-cert.crt # alpine/debian
     subPath: sensu-ca-cert.crt
   ```

Once installed, you may also need to run a certificate update command to update the CA trust store. This process differs from platform to platform (see below for more information).

_NOTE: it may be possible to automate this process using a [Docker ENTRYPOINT][6] such as the attached `entrypoint.sh` (experimental)._

[6]: https://docs.docker.com/engine/reference/builder/#entrypoint

#### Alpine Linux

Custom CA certificates can be installed on Alpine Linux by adding the certificate file(s) in question to `/usr/local/share/ca-certificates/*.crt` and running `update-ca-certificates` (NOTE: this requires the `ca-certificates` package to be installed, and the certificate files must use the `.crt` file extension).

#### Centos 6/7

Custom CA certificates can be installed on Centos 6/7 by adding the certificate file(s) in question to `/etc/pki/ca-trust/source/anchors/` and running `update-ca-trust force-enable && update-ca-trust extract` (NOTE: this requires the `ca-certificates` package to be installed).

#### Debian Stretch

Custom CA certificates can be installed on Debian Stretch by adding the certificate file(s) in question to `/usr/local/share/ca-certificates/*.crt` and running `update-ca-certificates` (NOTE: this requires the `ca-certificates` package to be installed, and the certificate files must use the `.crt` file extension).

### Use SSD persistent disks for Etcd

Configure faster SSD persistent disks for Etcd PersistentVolumeClaims. 
The following example can be used to [enable SSD storage on Google Cloud Platform][gke-ssd-pd].

```yaml
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: faster
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-ssd
```

_NOTE: while most Kubernetes clusters offers support for faster SSD storage, storage provider implementations do vary from one Kubernetes distribution to  another. 
Please consult with your Kubernetes administrator or cloud provider regarding availability of SSD storage (and how to enable it)._
  
Add this resource to `kubernetes/sensu-backend.yaml` or save it to a separate file and then enabled it via `kubectl apply -f`. 
Once enabled, uncomment the `sensu-etcd` StatefulSet `VolumeClaimTemplate.spec.storageClassName` field in `kubernetes/sensu-backend.yaml`. 

If you have already deployed your cluster, you may need to stop the cluster and delete the existing PersistentVolumeClaim as follows: 

```
$ kubectl get pvc --namespace sensu-system 
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
sensu-etcd-sensu-etcd-0   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   20Gi       RWO            standard       30m
```

If your existing volume claim is not using the SSD storage class, you can delete it as follows: 

```
$ kubectl delete pvc/sensu-etcd-sensu-etcd-0 --namespace sensu-system
persistentvolumeclaim "sensu-etcd-sensu-etcd-0" deleted
```

[gke-ssd-pd]: https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/ssd-pd

## TODO

This guide is a work in progress. 
Here are some of the improvements we are planning:

- [ ] Add Hashicorp Vault (dev-mode) for secrets management
- [ ] Add instructions for packaging Nagios Perl scripts/plugins as Sensu Assets
- [ ] Add instructions for packaging Nagios Python scripts/plugins as Sensu Assets
- [ ] Add instructions for hosting/mirroring Sensu Assets using NGINX
- [ ] Add instructions for configuring your first Sensu Handler (e.g. PagerDuty)
- [ ] Add instructions for install custom CA certificates (volume mount Kubernetes Secret);
      see `entrypoint.sh` (WIP/experimental)

  

      