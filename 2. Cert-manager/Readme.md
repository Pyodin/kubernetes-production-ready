# Cert-manager
Cert-manager is a Kubernetes add-on to automate the management and issuance of TLS certificates from various issuing sources. It will ensure certificates are valid and up to date periodically, and attempt to renew certificates at an appropriate time before expiry.

## Features
- **Automated certificate management**: Cert-manager can help with issuing certificates from a variety of sources, such as Let's Encrypt, HashiCorp Vault, Venafi, a simple signing key pair, or self-signed.
- **Self-renewing certificates**: Cert-manager will ensure certificates are valid and up to date, attempting to renew certificates at an appropriate time before expiry.
- **Integration with Kubernetes**: Cert-manager is a native Kubernetes certificate management controller. It ensures certificates are valid and up to date by monitoring the certificates in use.
- **Certificate Issuer**: Cert-manager allows you to define `Issuers` and `ClusterIssuers` to manage the lifecycle of certificates.

## Installation
To install cert-manager, you need to apply the following command:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.5/cert-manager.yaml
```

## Configuration
You can see how to configure and use cert-manager in the [Tutorial](./Tutorial/) folder.