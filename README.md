# SUSE Private AI stack

SUSE private ai stack provides SUSE customers to easily install an industry standard AI stack to run AI workloads using trusted containers with support for GPU hardware acceleration.

## SUSE Private AI stack Helm Chart
This chart is meant to manage the deployment of SUSE Private AI stack through Helm 3 onto a Kubernetes Cluster.

The open-webui server installed as part of the suse-private-ai stack is designed to be secure by default and requires SSL/TLS configuration. Currently TLS is implemented only for open-webui endpoint. The open-webui is exposed through an Ingress. This means the Kubernetes cluster that you install SUSE Private AI stack in must contain an Ingress controller. The API endpoints for Ollama and Pipelines are not exposed. Ingress for these are disabled.

This section outlines the steps to deploy suse-private-ai stack on a Kubernetes cluster using the Helm CLI.

To set up SUSE Private AI stack,

1. [Add the Helm chart repository](#1-add-the-helm-chart-repository)
2. [Choose your SSL configuration](#2-choose-your-ssl-configuration)
3. [Install cert-manager](#3-install-cert-manager) (unless you are bringing your own certificates, or TLS will be terminated on a load balancer)
4. [Ingress Controller](#4-ingress-controller)
5. [Customization Considerations](#5-customization-considerations)
6. [Install SUSE Private AI with Helm and your chosen certificate option](#6-install-suse-private-ai-with-helm-and-your-chosen-certificate-option)
7. [Verify that the components of the suse-private-ai are successfully deployed](#7-verification)


### 1. Add the Helm Chart Repository

TO DO: Will add repo details when available

For now see how to use the charts from this git source repo to deploy suse-private-ai stack in step 7.


### 2. Choose your SSL Configuration

There are three recommended options for the source of the certificate:

- **Self-Signed (suse-private-ai) TLS certificate:** This is the default option. In this case, you will need to install cert-manager into the cluster. suse-private-ai utilizes cert-manager to issue and maintain its certificates. suse-private-ai will generate a CA certificate of its own, and sign a cert using that CA. cert-manager is then responsible for managing that certificate.

- **Let's Encrypt (letsEncrypt):** The Let's Encrypt option also uses cert-manager. However, in this case, cert-manager is combined with a special Issuer for Let's Encrypt that performs all actions (including request and validation) necessary for getting a Let's Encrypt issued cert. This configuration uses HTTP validation (HTTP-01), so the load balancer must have a public DNS record and be accessible from the internet.

- **Bring your own certificate:** This option allows you to bring your own signed certificate. suse-private-ai will use that certificate to secure HTTPS traffic. In this case, you must upload this certificate (and associated key) as PEM-encoded files with the name tls.crt and tls.key.

| Configuration                  | Helm Chart Option           | Requires cert-manager                 |
| ------------------------------ | ----------------------- | ------------------------------------- |
| Self-Signed (suse-private-ai) Generated Certificates (Default) | `global.tls.source=suse-private-ai`  | [yes](#4-install-cert-manager) |
| Let’s Encrypt                  | `global.tls.source=letsEncrypt`  | [yes](#4-install-cert-manager) |
| Certificates from Files        | `global.tls.source=secret`        | no               |


### 3. Install cert-manager
This step is only required to use certificates issued by suse-private-ai's generated CA (`global.tls.source=suse-private-ai`) which is the default option or to request Let's Encrypt issued certificates (`global.tls.source=letsEncrypt`).
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.2   \
  --set crds.enabled=true
```

Once you’ve installed cert-manager, you can verify it is deployed correctly by checking the cert-manager namespace for running pods:

```bash
kubectl get pods --namespace cert-manager

NAME                                        READY   STATUS    RESTARTS   AGE
cert-manager-56cc584bd4-nhjx7               1/1     Running   0          3m
cert-manager-cainjector-7cfc74b84b-kg7m2    1/1     Running   0          3m
cert-manager-webhook-784f6dd68-69dvn        1/1     Running   0          3m
```


### 4. Ingress Controller

The only component of the suse-private-ai stack that is exposed through an ingress is the open-webui endpoint. It is exposed through an Ingress to be able to access it from outside the cluster. This means the Kubernetes cluster that you install suse-private-ai in must contain an Ingress controller.

For K8s distributions that do not include an Ingress Controller by default you have to deploy an Ingress controller first. Note that the suse-private-ai helm chart `open-webui.ingress.class` does not set an ingressClassName on the ingress by default. Because of this, by default, you have to configure the Ingress controller to also watch ingresses without an ingressClassName.

NGINX is a popular ingress controller and can be chosen and to make sure that you choose the correct ingress-nginx helm chart version, first find an ingress-nginx version that's compatible with your kubernetes version in [kubernetes/ingress-nginx support table](https://github.com/kubernetes/ingress-nginx#supported-versions-table).

Then, list the helm charts available to you by running the following command:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm search repo ingress-nginx -l
```

The helm search command's output contains an APP VERSION column. The versions under this column are equivalent to the ingress-nginx version you chose earlier. Using the app version, select a chart version that bundles an app compatible with your Kubernetes install. For example, if you have Kubernetes v1.30, you can select the 4.11.1 Helm chart, since ingress-nginx v1.11.1 comes bundled with that chart, and v1.11.1 is compatible with Kubernetes v1.30. When in doubt, select the most recent compatible version.

Now that you know which Helm chart version you need, run the following command. It installs an nginx-ingress-controller with a Kubernetes load balancer service:

```bash
helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --version 4.11.1 \
  --create-namespace
```

### 5. Customization Considerations
TO DO - Include documenation around resources, storage, models, etc considerations

### 6. Access to Application Collection Registry

Before installing suse-private-ai stack, a K8s secret resource containing the private registry credentials to the application collection suse registry has to be created in the namespace ```suse-private-ai```
Please substitute your application collection user email and token in the command below.

```bash
kubectl create ns suse-private-ai

kubectl create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=<application_collection_user_email> --docker-password=<application_collection_user_token> -n suse-private-ai
```


### 7. Install SUSE Private AI with Helm and Your Chosen Certificate Option

To deploy the suse private ai stack using helm using the charts in this source repo,

```bash
helm upgrade --install \
  suse-private-ai  . \
  --namespace suse-private-ai \
  --create-namespace
```

Depending on the TLS configuration and your other customization needs, you can create a custom-overrides.yaml file and deploy. The SUSE Private AI chart configuration has many options for customizing the installation to suit your specific environment.

```bash
helm upgrade --install \
  suse-private-ai  . \
  --namespace suse-private-ai \
  --create-namespace \
  --values ./custom-overrides.yaml
```

In the examples below, we use local storage for persistence as an example. Based on the storage considertions, specifying appropriate storage class.

An example of creating local storage provisioner:
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.28/deploy/local-path-storage.yaml
```

#### 7a. Using suse-private-ai generated certificates
The default is for suse-private-ai to generate a CA and uses `cert-manager` to issue the certificate for access to the open-webui server interface.

An example of custom-overrides.yaml: Here we are using self-signed suse-private-ai TLS option:
```bash
global:
  tls:
    source: suse-private-ai
    issuerName: suse-private-ai
open-webui:
  ollamaUrls:
  - http://suse-private-ai-ollama.suse-private-ai.svc.cluster.local:11434
  persistence:
    enabled: true
    storageClass: local-path
  ollama:
    enabled: false
  pipelines:
    enabled: true
    persistence:
      storageClass: local-path
  ingress:
    enabled: true
    class: ""
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    host: open-webui.example.com
    tls: true
    existingSecret: suse-private-ai-tls
  extraEnvVars:
  - name: DEFAULT_MODELS
    value: "gemma:2b"
  - name: DEFAULT_USER_ROLE
    value: "user"
```

Verification of suse-private-ai generated certificates:
```bash
openssl s_client -connect <open-webui-host>:443 -servername <open-webui host>
```

#### 7b. Using letsEncrypt option
This option uses `cert-manager` to automatically request and renew [Let's Encrypt](https://letsencrypt.org/) certificates. This is a free service that provides you with a valid certificate as Let's Encrypt is a trusted CA.

Note: When using letsEncrypt, there must be a public DNS record, and the IP must be public so letsEncrypt can successfully send a challenge to that IP.

An example of custom-overrides.yaml: Here we are using letsEncrypt TLS option:
```bash
global:
  tls:
    # options: suse-private-ai, letsEncrypt, secret
    source: letsEncrypt
    issuerName: suse-private-ai
    letsEncrypt:
      environment: staging
      email: none@example.com
      ingress:
        class: ""
open-webui:
  ollamaUrls:
  - http://suse-private-ai-ollama.suse-private-ai.svc.cluster.local:11434
  persistence:
    enabled: true
    storageClass: local-path
  ollama:
    enabled: false
  pipelines:
    enabled: true
    persistence:
      storageClass: local-path
  ingress:
    enabled: true
    class: ""
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    host: open-webui.example.com
    tls: true
    existingSecret: suse-private-ai-tls
  extraEnvVars:
  - name: DEFAULT_MODELS
    value: "gemma:2b"
  - name: DEFAULT_USER_ROLE
    value: "user"
```

Verification of letsEncrypted generated certificates:
```bash
openssl s_client -connect <open-webui-host>:443

```

#### 7c. Certificates from Files
In this option, Kubernetes secrets are created from your own certificates for suse-private-ai to use.

The `open-webui.ingress.host` option must match the `Common Name` or a `Subject Alternative Names` entry in the server certificate or the Ingress controller will fail to configure correctly.

Although an entry in the `Subject Alternative Names` is technically required, having a matching `Common Name` maximizes compatibility with older browsers and applications. Recent versions of Kubernetes and other software require the use of Subject Alternative Names (SANs) in certificates instead of relying solely on the Common Name (CN) field

An example of custom-overrides.yaml: Here we are using secret TLS option for custom certificates:
```bash
global:
  tls:
    source: secret
open-webui:
  ollamaUrls:
  - http://suse-private-ai-ollama.suse-private-ai.svc.cluster.local:11434
  persistence:
    enabled: true
    storageClass: local-path
  ollama:
    enabled: false
  pipelines:
    enabled: true
    persistence:
      storageClass: local-path
  ingress:
    enabled: true
    class: ""
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    host: open-webui.example.com
    tls: true
    existingSecret: suse-private-ai-tls
  extraEnvVars:
  - name: DEFAULT_MODELS
    value: "gemma:2b"
  - name: DEFAULT_USER_ROLE
    value: "user"
```
Kubernetes will create all the objects and services for SUSE Private AI, but it will not become available until we populate the `suse-private-ai-tls` secret in the `suse-private-ai` namespace with the certificate and key.

Combine the server certificate followed by any intermediate certificate(s) needed into a file named `tls.crt`. Copy your certificate key into a file named `tls.key`.

For example, [acme.sh](https://acme.sh) provides server certificate and CA chains in `fullchain.cer` file.
This `fullchain.cer` should be renamed to `tls.crt` & certificate key file as `tls.key`.

Use `kubectl` with the `tls` secret type to create the secrets.

```bash
kubectl -n suse-private-ai create secret tls suse-private-ai-tls \
  --cert=tls.crt \
  --key=tls.key
```

If you want to replace the certificate, you can delete the `suse-private-ai-tls` secret using `kubectl -n suse-private-ai delete secret suse-private-ai-tls` and add a new one using the command shown above.


### 8. Verify that the components of the suse-private-ai are successfully deployed

```bash
kubectl get all -n suse-private-ai
NAME                                          READY   STATUS    RESTARTS   AGE
pod/open-webui-0                              1/1     Running   0          98m
pod/open-webui-pipelines-5d5b86d8-ft6qx       1/1     Running   0          98m
pod/suse-private-ai-ollama-7896cc4787-6zs7z   1/1     Running   0          98m

NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
service/open-webui               ClusterIP   10.110.188.43   <none>        80/TCP      98m
service/open-webui-pipelines     ClusterIP   10.100.56.69    <none>        9099/TCP    98m
service/suse-private-ai-ollama   ClusterIP   10.109.216.49   <none>        11434/TCP   98m

NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/open-webui-pipelines     1/1     1            1           98m
deployment.apps/suse-private-ai-ollama   1/1     1            1           98m

NAME                                                DESIRED   CURRENT   READY   AGE
replicaset.apps/open-webui-pipelines-5d5b86d8       1         1         1       98m
replicaset.apps/suse-private-ai-ollama-7896cc4787   1         1         1       98m

NAME                          READY   AGE
statefulset.apps/open-webui   1/1     98m
```

Point your browser to ```https://<open-webui host>``` to access the open-webui. For more details on open-webui, checkout https://docs.openwebui.com/ 


## Troubleshooting
For certificate related issues with cert-manager, please refer to https://cert-manager.io/docs/troubleshooting/
