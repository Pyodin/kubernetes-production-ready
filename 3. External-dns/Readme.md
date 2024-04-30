# External-dns
External DNS allows you to manage DNS records dynamically via Kubernetes resources. It's a very useful tool to manage DNS records for your applications running in Kubernetes.


## Features
- **Automated DNS management**: External DNS allows you to manage DNS records dynamically via Kubernetes resources.
- **Integration with Kubernetes**: External DNS is a native Kubernetes resource, and it's very easy to use.
- **Support for multiple DNS providers**: External DNS supports many DNS providers like AWS Route53, Google Cloud DNS, Azure DNS, and others.

## Installation
Depending on your DNS provider, installation steps may vary. You can find the installation steps for each provider in the [official documentation](https://github.com/kubernetes-sigs/external-dns/tree/master?tab=readme-ov-file#running-externaldns)

## Test the Installation
To test the installation, you can create a simple `Service` and `Ingress` resource, and add an annotation to the `Ingress` resource to create a DNS record.

1. Create a simple `Service` resource:
    ```yaml
    apiVersion: v1
    kind: Service
    metadata:
      name: kuard
      namespace: kuard
      annotations:
        external-dns.alpha.kubernetes.io/hostname: svc.example.org
    spec:
      selector:
        app: kuard
      ports:
        - protocol: TCP
          port: 80
          targetPort: 8080
    ```

2. Create an `Ingress` resource with an annotation to create a DNS record:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: my-ingress
    spec:
        rules:
        - host: ingress.example.org
        http:
            paths:
            - path: /
                backend:
                    serviceName: my-service
                    servicePort: 8000
    ```

After you apply these resources, you should see a DNS record created for the `Ingress` resource.

## Resources
- [External DNS](https://github.com/kubernetes-sigs/external-dns/)
