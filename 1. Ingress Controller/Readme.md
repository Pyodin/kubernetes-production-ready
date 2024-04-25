# Ingress Controller
In Kubernetes, an Ingress is an object that allows access to your Kubernetes services from outside the Kubernetes cluster. You configure access by creating a collection of rules that define which inbound connections reach which services. 
An Ingress Controller is responsible for fulfilling the Ingress, usually with a load balancer, and it's responsible for routing the traffic to the correct services.

There are many Ingress Controllers available, I will only cover [Contour](https://projectcontour.io/)


# Contour
Contour is an Ingress controller for Kubernetes that works by deploying the Envoy proxy as a reverse proxy and load balancer. Contour is designed to work with any Kubernetes cluster, and it's capable of handling a large number of ingress objects.

## Features
- Contour is a high-performance ingress controller that uses the Envoy proxy.
- Contour supports dynamic configuration updates without the need for a full reload.
- Contour supports HTTP/2, gRPC, and WebSockets.
- Contour supports TLS termination.

What I like the most about Contour, is that it offers very easy ways of doing **"exotic"** deployments, like *canary deployments*, *blue-green deployments*, and *A/B testing* using its CRDs resource: `HTTPProxy`.

## Installation
To install Contour, you need to apply the following manifests:

```bash
kubectl apply -f https://projectcontour.io/quickstart/contour.yaml
```

Verify that Contour is running:

```bash
kubectl get pods -n projectcontour
```
You should see 2 contour pods running, and one envoy pod.

## Usage
Now that contour is running, you can start deploying applications. 
You can get the external IP of the envoy service by running:

```bash
kubectl get svc -n projectcontour envoy -o wide
```

After you deploy your applications with an Ingress or HTTPProxy, you would need to add a DNS record pointing to the external IP of the envoy service.

We will see in an other section how to automate this process using External DNS.

## Resources
- [Contour](https://projectcontour.io/)