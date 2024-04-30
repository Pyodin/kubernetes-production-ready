# Network policy tutorial

This tutorial will guide you through the process of creating a network policy for a Kubernetes cluster. You will learn how to create a network policy that restricts traffic to a specific namespace in your cluster.

## Understanding network policies
Basic network policy looks like the following. Use this template to create your own network policy.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
```
This network policy allows incoming traffic from pods with the label `role=db`, from the namespace with the label `project=myproject`, and from pods with the label `role=frontend`. It also allows outgoing traffic to the IP block `


## Step 1: Create a namespace

1. Create a new namespace called `network-policy` by running the following command:

    ```shell
    kubectl create namespace network-policy
    ```

2. Verify that the namespace was created successfully by running:

    ```shell
    kubectl get namespaces
    ```

    You should see `network-policy` in the list of namespaces.

## Step 2: Deploy a sample application

1. Deploy a sample application to the `network-policy` namespace by running the following command:

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: network-policy
    namespace: network-policy
    spec:
    selector:
        matchLabels:
        app: network-policy
    replicas: 2
    template:
        metadata:
        labels:
            app: network-policy
        spec:
        containers:
        - image: nginx:1.14.2
            name: nginx
            ports:
            - containerPort: 80
    ```

2. Verify that the application was deployed successfully by running:

    ```shell
    kubectl get pods -n network-policy
    ```
    You should see two pods named `nginx` in the `network-policy` namespace.

3. Expose the application by creating a service for it by running the following command:

    ```shell
    kubectl expose deployment network-policy --port=80 --type=ClusterIP -n network-policy 
    ```

4. Verify that the service was created successfully by running:

    ```shell
    curl http://<service-ip>
    ```

## Step 3: Create a network policy
We want to create a network policy that allows incoming traffic from anywhere but blocks outgoing traffic to anywhere. This will restrict the pods in the `network-policy` namespace from initiating communication with other pods.

1. Create the following network policy YAML file:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
    name: internet-access-only
    namespace: network-policy
    spec:
    podSelector: {}
    policyTypes:
        - Ingress
        - Egress
    ingress:
        - {} # Allow all incoming traffic
    egress: []
        # Deny all egress traffic from the selected pods. 
        # This means they cannot initiate communication to other pods.
        # However, they can still send responses to incoming connections initiated from the Internet.
    ```
2. Apply the network policy by running the following command:

    ```shell
    kubectl apply -f network-policy.yaml
    ```
3. Verify that the network policy incoming traffic by running:

    ```shell
    curl http://<service-ip>
    ```
    You should see no connection problems as the network policy allows incoming traffic.

4. Verify that the network policy blocks outgoing traffic by running:

    ```shell
    kubectl get pods -n network-policy -o wide
    ```
    get one of the pod's name, and one other pod's IP address, then run:
    ```shell
    kubectl exec -it <pod-name> -n network-policy -- curl <other-pod-ip>
    ```
    You should see a connection error as the network policy blocks outgoing traffic.

