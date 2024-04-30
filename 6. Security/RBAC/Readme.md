# Create a new user for Kubernetes
This document describes how to create a new user without *cluster-admin* privileges.
In this tutorial, I assume no OpenID is used to connect to the cluster. The user will be authenticated using a certificate.

## Prerequisites
- You need to have `openssl` installed on your machine.
- You need to have appropriate permissions and role-based access control (RBAC) rules to create a new user in the cluster.


## Plan
1. [Generate the user's private key and certificate signing request (CSR)](#generate-the-users-private-key-and-certificate-signing-request-csr)
2. [Send the CSR to the cluster CA](#send-the-csr-to-the-cluster-ca)
3. [Sign the CSR with the cluster CA](#sign-the-csr-with-the-cluster-ca)
4. [Create the user in the cluster](#create-the-user-in-the-cluster)
5. [Add RBAC rules to the user](#add-rbac-rules-to-the-user)
6. [Create a kubeconfig file for the user](#create-a-kubeconfig-file-for-the-user)


## 1. Generate the user's private key and certificate signing request (CSR)
The first step of creating a new user is to generate the user's `private key`. This key will be used to sign the `certificate signing request (CSR)` that will be sent to the cluster CA.    
```bash
openssl genrsa -out user.key 2048
openssl req -new -key user.key -out user.csr -subj "/CN=user/O=group"
```
Notice we put the `CN` field to `user` and the `O` field to `group`. **You can change the O field to the group you want to add the user to.**

## 2. Send the CSR to the cluster CA
Next, we have to send the `CSR` to the cluster CA, but before that, we need to encode the `CSR` in base64 (in one line).    
```bash
cat user.csr | base64 | tr -d '\n'
```
Then, fill the `CertificateSigningRequest` object with the encoded `CSR` and apply the object.    
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: <user-name>
spec:
  request: <encoded-csr>
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
```
```bash
kubectl apply -f csr.yaml
```

## 3. Sign the CSR with the cluster CA
Now we need to approve the `CSR` with the cluster CA. Let's list the `CSR` objects.    
```bash
kubectl get csr
```
You should see something similar to this:
```bash
NAME        AGE     REQUESTOR           CONDITION
user        1m      system:admin        Pending
```
To approve the `CSR`, run the following command:
```bash
kubectl certificate approve user
```
The `CSR` should now be approved. When getting the `CSR` list, you should see the `user` object with the `Approved` condition.

## 4. Create the user in the cluster
Now that the `CSR` is approved, we can get the signed certificate from the cluster CA.    
```bash
kubectl get csr user -o jsonpath='{.status.certificate}' | base64 --decode > user.crt
```
- Let's create the user in the cluster.    
    ```bash
    kubectl config set-credentials user --client-certificate=user.crt --client-key=user.key --embed-certs=true
    ```
    With this command, we tell the cluster to use the `user.crt` and `user.key` files to authenticate the new user.

- Let's set the context for the new user.    
    ```bash
    kubectl config set-context user-context --cluster=<cluster-name> --namespace=<namespace> --user=user
    ```
    You need to remplace <cluster-name> with the name of your cluster. You can find this value by running `kubectl config get-clusters`.
    The namespace field is optional. If you want to set a default namespace for the user, you can add it here. Otherwise, you can remove it. 

## 5. Add RBAC rules to the user
Now that the user is created, we need to add some RBAC rules to the user.    
Let's use a basic, already existing role, `view`, to give the user read-only access to the cluster.    
```bash
kubectl create rolebinding user-view --clusterrole=view --user=user --namespace=<namespace>
```
You need to replace <namespace> with the namespace you want to give the user access to. If you want to give the user access to all namespaces, you can replace `rolebinding` with `clusterrolebinding` and remove the `--namespace` flag.

## 6. Create a kubeconfig file for the user
Finally, let's create a `kubeconfig` file for the user.    
```bash
kubectl config use-context user-context
kubectl config view --minify --flatten > user.kubeconfig
```
With this command, we tell the cluster to use the `user-context` context. Then, we flatten the `kubeconfig` file and save it to `user.kubeconfig`.
We can now send this file to the user, and they can use it to authenticate to the cluster.
**Carreful when sending this file, as it contains sensitive information.**
