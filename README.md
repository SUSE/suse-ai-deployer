# SUSE AI stack

SUSE AI stack provides SUSE customers to easily install an industry standard AI stack to run AI workloads using trusted containers with support for GPU hardware acceleration.

## SUSE AI deployer Helm Chart
This chart is meant to manage the deployment of SUSE AI stack through Helm 3 onto a Kubernetes Cluster.

The open-webui server installed as part of the stack is designed to be secure by default and requires SSL/TLS configuration. The open-webui is exposed through an Ingress. This means the Kubernetes cluster that you install SUSE AI stack in must contain an Ingress controller. The API endpoints for Ollama are not publically accessible since ingress is disabled by default since ollama does not have an authenticated endpoint yet.

This section outlines the steps to deploy SUSE AI stack on a Kubernetes cluster using the Helm CLI.

To set up SUSE AI stack,

1. [Choose your SSL configuration](#1-choose-your-ssl-configuration)
2. [Access to Application Collection Registry](#2-access-to-application-collection-registry)
3. [Install cert-manager](#3-install-cert-manager) (unless you are bringing your own certificates, or TLS will be terminated on a load balancer)
4. [Customization Considerations](#4-customization-considerations)
5. [Install SUSE Private AI with Helm and your chosen certificate option](#5-install-suse-ai-with-helm-and-your-chosen-certificate-option)
6. [Verify that the components of the suse ai are successfully deployed](#6-verification)


### 1. Choose your SSL Configuration

There are three recommended options for the source of the certificate:

- **Self-Signed (suse-private-ai) TLS certificate:** This is the default option. In this case, you will need to install cert-manager into the cluster. SUSE AI utilizes cert-manager to issue and maintain its certificates. suse-private-ai will generate a CA certificate of its own, and sign a cert using that CA. cert-manager is then responsible for managing that certificate.

- **Let's Encrypt (letsEncrypt):** The Let's Encrypt option also uses cert-manager. However, in this case, cert-manager is combined with a special Issuer for Let's Encrypt that performs all actions (including request and validation) necessary for getting a Let's Encrypt issued cert. This configuration uses HTTP validation (HTTP-01), so the load balancer must have a public DNS record and be accessible from the internet.

- **Bring your own certificate:** This option allows you to bring your own signed certificate. SUSE AI will use that certificate to secure HTTPS traffic. In this case, you must upload this certificate (and associated key) as PEM-encoded files with the name tls.crt and tls.key.

| Configuration                  | Helm Chart Option           | Requires cert-manager                 |
| ------------------------------ | ----------------------- | ------------------------------------- |
| Self-Signed (suse-private-ai) Generated Certificates (Default) | `global.tls.source=suse-private-ai`  | [yes](#4-install-cert-manager) |
| Let’s Encrypt                  | `global.tls.source=letsEncrypt`  | [yes](#4-install-cert-manager) |
| Certificates from Files        | `global.tls.source=secret`        | no               |


### 2. Access to Application Collection Registry

Before installing SUSE AI stack, a K8s secret resource containing the private registry credentials to the application collection suse registry has to be created in the namespace ```suse-private-ai```
Please substitute your application collection user email and token in the command below.

```bash
kubectl create ns suse-private-ai

kubectl create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=<application_collection_user_email> --docker-password=<application_collection_user_token> -n suse-private-ai
```

### 3. Install cert-manager if not installed already
This step is only required to use certificates issued by suse-private-ai's generated CA (`global.tls.source=suse-private-ai`) which is the default option or to request Let's Encrypt issued certificates (`global.tls.source=letsEncrypt`).
You will need to obtain the Application Collection Token and authenticate to application collection registry using:

```bash
helm registry login dp.apps.rancher.io/charts -u <application_collection_user_email> -p <application_collection_user_token>
kubectl create ns cert-manager
kubectl create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=<application_collection_user_email> --docker-password=<application_collection_user_token> -n cert-manager
```

```bash
helm install \
  cert-manager oci://dp.apps.rancher.io/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version 1.17.2  \
  --set crds.enabled=true \
  --set global.imagePullSecrets={application-collection}
```

Once you’ve installed cert-manager, you can verify it is deployed correctly by checking the cert-manager namespace for running pods:

```bash
kubectl get pods --namespace cert-manager

NAME                                        READY   STATUS    RESTARTS   AGE
cert-manager-56cc584bd4-nhjx7               1/1     Running   0          3m
cert-manager-cainjector-7cfc74b84b-kg7m2    1/1     Running   0          3m
cert-manager-webhook-784f6dd68-69dvn        1/1     Running   0          3m
```

### 4. Install SUSE AI with Helm

To deploy the SUSE AI stack using helm using the charts in this source repo,

Depending on the TLS configuration and your *other* customization needs like storage, you can create a custom-overrides.yaml file and deploy. The SUSE Private AI chart configuration has many options for customizing the installation to suit your specific environment. Please refer to some of the examples overrides in the examples directory. Use the appropriate <RELEASE_NAME> based on your custom overrides.

```bash
helm upgrade --install \
  <RELEASE_NAME> . \
  --namespace suse-private-ai \
  --create-namespace \
  --values ./custom-overrides.yaml
```

### 5. Verify that the components of the suse-private-ai are successfully deployed

```bash
kubectl get all -n suse-private-ai
```

Point your browser to ```https://<open-webui host>``` to access the open-webui. For more details on open-webui, checkout https://docs.openwebui.com/ 


## Troubleshooting
For certificate related issues with cert-manager, please refer to https://cert-manager.io/docs/troubleshooting/
