# How to Make an Application Accessible Outside of a Kubernetes Cluster?
The purpose of this tutorial is to deploy an application in our Kubernetes cluster, and make it accessible from outside the cluster using an *Ingress* or *HTTPProxy* resource.

We will deploy the simple `kuard` application, which is a simple web application that displays its hostname and IP address. 

## Prerequisites
- A Tanzu Kubernetes cluster
- The `kubectl` command line tool
- An Ingress Controller installed in the cluster. 

## Step 1: Create a Namespace
Take the habit of creating a namespace for each application you deploy in your cluster. This will help you to manage your resources more efficiently.
Create a new namespace called `kuard` by executing the following command:
```bash
kubectl create namespace kuard
```

## Step 2: Deploy the kuard Application
1. Deploy an application in the `kuard` namespace with the following file:
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kuard
      namespace: kuard
    spec:
      selector:
        matchLabels:
          app: kuard
      replicas: 1
      template:
        metadata:
          labels:
            app: kuard
        spec:
          containers:
          - image: gcr.io/kuar-demo/kuard-amd64:1
            imagePullPolicy: Always
            name: kuard
            ports:
            - containerPort: 8080
    ```
    Save this file as `deployment.yaml` and execute the following command:
    ```shell
    kubectl apply -f deployment.yaml
    ```

2. Check that the application has been deployed successfully by running:
    ```shell
    kubectl get pods -n kuard
    ```

3. Create a service to expose the application outside the cluster. Create a YAML file called `service.yaml` with the following content:
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: kuard
      namespace: kuard
    spec:
      ports:
      - port: 80
        targetPort: 8080
        protocol: TCP
      selector:
        app: kuard
    ```
    This service will create a ClusterIP type service that will expose the application on port 80.

4. Our application is now available from inside the cluster. Let's test our deployment.
We can create a temporary nginx pod and send a *curl* request to our service's IP address to verify that our application responds well.

    ```bash
    kubectl get service -n kuard
    ```

    Note your service's IP address, then create a temporary pod:
    ```bash
    kubectl run busybox -n kuard --image=nginx:latest
    kubectl exec -it -n kuard busybox -- curl http://<service-ip>
    ```

## Step 3: Expose the Application outside the Cluster
### Using an Ingress Resource
1. Create an Ingress resource to expose the application outside the cluster. Create a YAML file called `ingress.yaml` with the following content:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: kuard
      namespace: kuard
    spec:
      rules:
      - host: <your_domain> # Ex: kuard.example.com
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
    Replace `<your_domain>` with the domain you wish to use to access the application.

2. Apply the Ingress resource by executing the following command:
    ```shell
    kubectl apply -f ingress.yaml
    ```

3. Check that the Ingress has been created successfully by running:
    ```shell
    kubectl get ingress -n kuard
    ```

4. Add a DNS entry for the domain you specified in the Ingress. You can add a local DNS entry in your `/etc/hosts` file to test access to the application. 
*This step won't be necessary in the futur as we will automate this process using External DNS.*

### Using an HTTPProxy Resource
1. Create an HTTPProxy resource to expose the application outside the cluster. Create a YAML file called `httpproxy.yaml` with the following content:
    ```yaml
    apiVersion: projectcontour.io/v1
    kind: HTTPProxy
    metadata:
      name: kuard
      namespace: kuard
    spec:
      virtualhost:
        fqdn: <your_domain>
      routes:
        - services:
            - name: kuard
              port: 80
          conditions:
            - prefix: /
    ```
    Replace `<your_domain>` with the domain you wish to use to access the application.

2. Perform the exact same steps as for the Ingress resource to apply the HTTPProxy resource.


## Step 4: Access the Application
1. Open a web browser and navigate to the following URL: `http://<your_domain>`. You should see the kuard application displayed in your browser.

**Note that access to the application is in HTTP.** If you wish to access the application in **HTTPS**, you will need to configure a **TLS** certificate for the Ingress. See the next step for more details.

## Step 5: Deploy with a TLS Certificate (optional)
If you wish to access the application in HTTPS, you will need to configure a TLS certificate for the Ingress.

For this, you must have a valid TLS certificate for the domain you specified in the Ingress. You can use a self-signed certificate for testing, but for production use, you should obtain a certificate signed by a recognized certification authority (CA).

1. You can use the `gen-certs.sh` script to create a certification authority and a self-signed certificate for the domain you specified in the Ingress.
    ```shell
    ./gen-certs.sh
    ```

2. Create a Kubernetes secret to store the TLS certificate. Execute the following command:
    ```shell
    kubectl create secret tls kuard-tls-secret --key server.key --cert server.crt -n kuard
    ```
    Make sure that the `server.key` and `server.crt` files contain the private keys and corresponding certificates.

3. Modify the Ingress resource to specify the TLS secret. Modify the `ingress.yaml` file to include the TLS secret:

    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: kuard
      namespace: kuard
      annotations: {}
    spec:
      tls:
      - hosts:
          - <your_domain>
        secretName: kuard-tls-secret
      rules:
      - host: <your_domain>
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
    Apply the changes by executing the following command:
    ```shell
    kubectl apply -f ingress.yaml
    ```
    The Ingress will be updated to use the specified TLS certificate.

4. Access the application using HTTPS. Open a web browser and navigate to the following URL: `https://<your_domain>`. You should see the kuard application displayed in your browser using HTTPS.

That's it! You have successfully deployed an application in your Tanzu Kubernetes cluster and made it accessible from outside the cluster using an Ingress resource.

