# Ingress Controller
In Kubernetes, an Ingress is an object that allows access to your Kubernetes services from outside the Kubernetes cluster. You configure access by creating a collection of rules that define which inbound connections reach which services. 
An Ingress Controller is responsible for fulfilling the Ingress, usually with a load balancer, and it's responsible for routing the traffic to the correct services.

There are many Ingress Controllers available, I will cover only two:
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Contour](https://projectcontour.io/)

