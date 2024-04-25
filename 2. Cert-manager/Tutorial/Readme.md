# Cert-manager Tutorial
This tutorial explains how to use cert-manager to obtain free and automatic TLS certificates for Kubernetes services.

## ClusterIssuer and Issuer
To be able to create TLS certificates, you need to set up a `ClusterIssuer` or an `Issuer` that defines the certificate authority (CA) you want to use. There are several types of CAs that you can configure with cert-manager. Here, we will see how to set up a self-signed CA, a custom CA, and Let's Encrypt.
- A `ClusterIssuer` is a Kubernetes resource that defines a CA that can be used to issue certificates across all namespaces.
- An `Issuer` is a Kubernetes resource that defines a CA specific to a namespace.

### Self-Signed CA
We will create a self-signed `ClusterIssuer` and a self-signed `Issuer`.

1. This `ClusterIssuer` defines a self-signed CA that allows issuing self-signed certificates for all namespaces:
    *selfsigned-cluster-issuer.yaml*:
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
        name: selfsigned-cluster-issuer
    spec:
        selfSigned: {}
    ```
    

2. This `Issuer` defines a self-signed CA that allows issuing self-signed certificates only for the *kuard* namespace:
    *selfsigned-issuer.yaml*:
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
        name: selfsigned-issuer
    namespace: kuard
    spec:
        selfSigned: {}
    ```

### Custom CA (optional)
If you already own a CA and a certificate, you can use them to issue TLS certificates. To do this, you need to create a Kubernetes secret to store the certificate and the private key of the CA. Then, you can create a `ClusterIssuer` or an `Issuer` that references this secret.

1. Create the certificate and private key for the CA:
    ```shell
    openssl req -x509 -newkey rsa:4096 -keyout ca.key -out ca.crt -days 365 -nodes -subj "/CN=my-ca"
    ```
2. Create a Kubernetes secret to store the certificate and private key:
    ```shell
    kubectl create secret tls my-ca-secret --key ca.key --cert ca.crt -n cert-manager
    ```
3. Create a `ClusterIssuer` or an `Issuer` that references this secret:
    *custom-cluster-issuer.yaml*:
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer # or Issuer
    metadata:
        name: my-custom-cluster-issuer
    spec:
        ca:
            secretName: my-ca-secret
    ```

### Let's Encrypt
Let's Encrypt is a CA that provides free and automatic TLS certificates. To obtain a Let's Encrypt certificate, you need to set up a `ClusterIssuer` or an `Issuer` that uses a challenge to verify that you own the domain for which you are requesting a certificate. There are two types of challenges you can use with Let's Encrypt: `http01` and `dns01`.

#### http01 Challenge
This challenge involves creating a file on a web server to prove that you own the domain for which you are requesting a certificate. To use this challenge, you must expose your Kubernetes service to the internet so that Let's Encrypt can access it.

Create a `ClusterIssuer` that uses the `http01` challenge to verify that you own the domain:
*http01-cluster-issuer.yaml*:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
    name: http01-cluster-issuer
spec:
    acme:
        server: https://acme-staging-v02.api.letsencrypt.org/directory
        # For production, use the following server:
        # server: https://acme-v02.api.letsencrypt.org/directory
        email: <your_email>
        privateKeySecretRef:
            name: http01-cluster-issuer-secret
        solvers:
        - http01:
            ingress:
            class: contour
```
Replace `<your_email>` with your email address.

#### dns01 Challenge
This challenge involves creating a DNS record to prove that you own the domain for which you are requesting a certificate. To use this challenge, you must have a DNS provider that supports programmatic DNS updates.

1. Create a `ClusterIssuer` that uses the `dns01` challenge to verify that you own the domain:
    *dns01-cluster-issuer.yaml*:
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: ClusterIssuer
    metadata:
        name: dns01-cluster-issuer
    spec:
        acme:
            server: https://acme-staging-v02.api.letsencrypt.org/directory
            # For production, use the following server:
            # server: https://acme-v02.api.letsencrypt.org/directory
            email: <your_email>
            privateKeySecretRef:
                name: dns01-cluster-issuer-secret
            solvers:
            - dns01:
                azuredns:
                    clientID: <your_client_id>
                    clientSecretSecretRef:
                        name: azuredns-secret
                        key: client-secret
                    subscriptionID: <your_subscription_id>
                    tenantID: <your_tenant_id>
                    resourceGroupName: <your_resource_group>
                    hostedZoneName: <your_hosted_zone>
    ```
    Replace `<your_email>`, `<your_client_id>`, `<your_subscription_id>`, `<your_tenant_id>`, `<your_resource_group>`, and `<your_hosted_zone>` with your information.


## Creating Certificates
Once you have set up a `ClusterIssuer` or an `Issuer`, you can create certificates for your Kubernetes services. There are several ways to create certificates with cert-manager:
- The first is to manually create the `Certificate` resource, then reference the secret containing the certificate and private key in an `Ingress`. In this case, you must manually manage the renewal of the certificates.
- The second involves creating an `Ingress` with a special annotation that references the `ClusterIssuer` or `Issuer`. In this case, cert-manager will automatically create a certificate for you and renew it automatically.

### First Method - Manually Create a Certificate
1. Create a self-signed certificate for the *kuard* service in the *kuard* namespace:
   *selfsigned-cert.yaml*:
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
        name: kuard-selfsigned-cert
        namespace: kuard
    spec:
        secretName: kuard-selfsigned-tls
        issuerRef:
            name: selfsigned-issuer
        commonName: <domain>
    ```
    Replace `<domain>` with the domain you wish to use to access the application.
2. Verify that the certificate has been successfully created:
    ```shell
    kubectl get certificate -n kuard
    ```
3. Verify that the secret containing the certificate and private key has been successfully created:
    ```shell
    kubectl get secret kuard-selfsigned-tls -n kuard
    ```

4. Use the secret in an Ingress to enable TLS for the *kuard* service. Create a file `ingress.yaml` with the following content:
   *ingress.yaml*:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: kuard
        namespace: kuard
    spec:
        tls:
        - hosts:
            - <domain>
            secretName: kuard-selfsigned-tls
        rules:
        - host: <domain>
            http:
            paths:
            - path: /
                pathType: Prefix
                backend:
                service:
                    name: kuard
                    port:
                    number: 80
    ```
    Replace `<domain>` with the domain specified in the certificate.
    Apply the Ingress resource by running the following command:
    ```shell
    kubectl apply -f ingress.yaml
    ```
2. Verify that the Ingress has been successfully created by running:
    ```shell
    kubectl get ingress -n kuard
    ```
3. Add a DNS entry for the domain you specified in the Ingress. You can add a local DNS entry in your `/etc/hosts` file to test access to the application.

4. Open a web browser and navigate to the following URL: `https://<domain>`. You should see the kuard application displayed in your browser.

### Second Method
1. Create an `Ingress` with a special annotation that references the `ClusterIssuer` or `Issuer`:
   *ingress-cert.yaml*:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: kuard
        namespace: kuard
        annotations:
            cert-manager.io/cluster-issuer: selfsigned-cluster-issuer
    spec:
        tls:
        - hosts:
            - <domain>
            secretName: kuard-selfsigned-tls
        rules:
        - host: <domain>
            http:
            paths:
            - path: /
                pathType: Prefix
                backend:
                service:
                    name: kuard
                    port:
                    number: 80
    ```
    - Replace `<domain>` with the domain you wish to use to access the application.
    - By adding the annotation `cert-manager.io/cluster-issuer: selfsigned-cluster-issuer`, cert-manager will automatically create a certificate for you and name it as specified in the `secretName` field.
    - Apply the Ingress resource by running the following command:
        ```shell
        kubectl apply -f ingress-cert.yaml
        ```
    Execute steps 2, 3, and 4 from the first method.

### HTTPProxy
Unlike Ingress resources, HTTPProxy resources do not support annotations. To use cert-manager with HTTPProxy, you must manually create a `Certificate` and reference it in an `HTTPProxy` (First Method):

1. Manually create a certificate
    ```yaml
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
        name: cert-for-http-proxy
        namespace: kuard
    spec:
        secretName: cert-for-http-proxy-tls
        issuerRef:
            name: selfsigned-issuer
        commonName: <domain>
    ```
    Replace `<domain>` with the domain you wish to use to access the application.

2. Create an `HTTPProxy` that references the secret containing the certificate and private key:
   *httpproxy-cert.yaml*:
    ```yaml
    apiVersion: projectcontour.io/v1
    kind: HTTPProxy
    metadata:
        name: kuard
    namespace: kuard
    spec:
        virtualhost:
            fqdn: infra.almacg.com
            tls:
                secretName: kuard-tls-with-lets-encrypt
        routes:
        - services:
            - name: kuard
            port: 80
        conditions:
            - prefix: /
    ```

## Conclusion
In this tutorial, we have seen how to set up a `ClusterIssuer` and an `Issuer` to issue TLS certificates with cert-manager. We have also seen how to manually and automatically create certificates for Kubernetes services. Cert-manager is a powerful tool that makes it easy to obtain free and automatic TLS certificates for Kubernetes services. It is highly recommended to use it to secure your Kubernetes services.
