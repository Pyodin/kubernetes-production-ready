# kubernetes-production-ready
This repository contains good practices and tools to deploy a production ready `Kubernetes cluster`. I won't cover the node setup, I suggest you to use a cloud provider like AWS, GCP or Azure. 

This repository is a work in progress, I will keep updating it with new tools and tips.

The docs in this repo will explain how to deploy *necessary packages* so that your cluster can host production workloads. I will also provide some basic tutorials on how to use these tools.

The main topics I will cover are: *monitoring*, *backup*, *logging*, *security*, *networking*, *storage*, and *CI/CD*.

## Prerequisites
- A **Kubernetes cluster**
- A **DNS** provider
- A **CI/CD** tool (optional)  

## Table of Contents
Before deploying any application to your cluster, I suggest you take into consideration the following topics:
1. [Ingress Controller (Contour)](#contour)
2. [Cert Manager](#cert-manager)
3. [External DNS](#external-dns)
4. [Backup and Restore](#backup-and-restore)
5. [Monitoring](#monitoring)
6. [Security](#security)
    - [RBAC](#rbac)
    - [TLS Termination](#tls-termination)
    - [Network Policies](#network-policies)
6. [CI/CD](#ci/cd) 
