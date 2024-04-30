# Azure devops agent on Kubernetes cluster 
The goal of this project is to deploy an **Azure DevOps** agent to a Kubernetes cluster. The agent will be used to run build and release pipelines in Azure DevOps. 
This project will cover the following steps:
- Create a Docker image for the agent
- Create a deployment for the agent in Kubernetes
- Scale the agent deployment using [KEDA](https://keda.sh/), a Kubernetes-based event-driven autoscaler

## Plan 
- [x] Create a Docker image for the agent
- [x] Create a deployment for the agent in Kubernetes
- [x] Configure Azure DevOps to use the agent on Kubernetes
- [x] Scale the agent deployment using KEDA

## Prerequisites
- Azure DevOps organization
- Azure DevOps project
- A kubernetes cluster

## Create a Docker image for the agent
The following Dockerfile will be used to create a Docker image that contains the necessary dependencies to run the Azure DevOps agent. The `start.sh` script will be used to configure and start the agent. 
### Create a Dockerfile
- Create a Dockerfile with the following content:
    ```Dockerfile
    FROM ubuntu:22.04

    RUN apt update && apt upgrade -y 
    RUN apt install -y curl git jq libicu70

    # Also can be "linux-arm", "linux-arm64".
    ENV TARGETARCH="linux-x64"

    WORKDIR /azp/

    COPY ./start.sh ./
    RUN chmod +x ./start.sh

    RUN useradd agent
    RUN chown agent ./
    USER agent
    # Another option is to run the agent as root.
    # ENV AGENT_ALLOW_RUNASROOT="true"

    ENTRYPOINT ./start.sh
    ```

### Build and push the Docker image
- Build the Docker image and push it to your Docker registry. Replace `<your-registry-name>` with your Docker registry name.
    ```bash
    docker build . -t <your-registry-name>/azsh-linux-agent
    docker push <your-registry-name>/azsh-linux-agent
    ```

## Configuring Azure DevOps to use the agent on Kubernetes 
### Create Agent Pool
- In your Azure DevOps organization, navigate to “**Project Settings**” > “**Agent Pools**”.
- Create a new agent pool or use an existing one for your Kubernetes agents.
- Click on the “**New agent pool**” button to create a new pool, or select an existing one.

### Create PAT Token
- Click on “**User Settings**” from top-right corner of the page.
- Select “**Personal access tokens**” from the dropdown menu.
- Generate a Personal Access Token (PAT) with the appropriate scope for registering agents, and save it for next steps.

## Deploy the agent to Kubernetes
### Create a Kubernetes secret
- Create a Kubernetes secret to store the Azure DevOps PAT token, the Azure DevOps organization URL, and the Azure DevOps agent pool name. 
    ```bash
    kubectl create -n az-devops secret generic azdevops-agent-secret \
    --from-literal=AZP_URL=https://dev.azure.com/<your-organization> \
    --from-literal=AZP_TOKEN=<your-pat-token> \
    --from-literal=AZP_POOL=<your-agent-pool>
    ```
    Replace `<your-organization>`, `<your-pat-token>`, and `<your-agent-pool>` with your Azure DevOps organization URL, PAT token, and agent pool name respectively.

### Create a Kubernetes deployment
- Create a Kubernetes deployment for the Azure DevOps agent using the Docker image created earlier.
    ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: azsh-linux
    namespace: az-devops
    labels:
      app: azsh-linux-agent
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: azsh-linux-agent
    template:
      metadata:
        labels:
          app: azsh-linux-agent
      spec:
        containers:
        - name: kubepodcreation
          image: <your-registry-name>/azsh-linux-agent:latest
          env:
            - name: AZP_URL
              valueFrom:
                secretKeyRef:
                  name: azdevops
                  key: AZP_URL
            - name: AZP_TOKEN
              valueFrom:
                secretKeyRef:
                  name: azdevops
                  key: AZP_TOKEN
            - name: AZP_POOL
              valueFrom:
                secretKeyRef:
                  name: azdevops
                  key: AZP_POOL
    ```
    Don't forget to replace `<your-registry-name>` with your Docker registry name.
    If you are using a private registry, you will need to specify the image pull secret in the deployment YAML file by adding: 
    ```yaml
    spec:
      imagePullSecrets:
      - name: <your-image-pull-secret>
      ...
    ```

### Deploy the agent to Kubernetes
- Create the namespace for the agent:
    ```bash
    kubectl create namespace az-devops
    ```
- Apply the deployment YAML file:
    ```bash
    kubectl apply -f azsh-linux-agent-deployment.yaml
    ```
- Verify that the agent pod and secret are running:
    ```bash
    kubectl get pods -n az-devops
    kubectl get secrets -n az-devops
    ```
Now you have successfully deployed an Azure DevOps agent to your Kubernetes cluster. The agent will be registered with your Azure DevOps organization and can be used to run build and release pipelines.

#### TroubleShooting
- If the agent pod is not running, check the logs for the pod to identify the issue:
    ```bash
    kubectl logs <pod-name> -n az-devops
    ```
  I noticed I had an error that looked like this:
  *Access denied. {User Name} needs Use permissions for pool Default to perform the action. For more information, contact the Azure DevOps Server administrator*. 
  Problem was that the PAT token I created did not have the right permissions. 

### Test your agent 
Let's test if the agent is working correctly by running a simple pipeline in Azure DevOps.
#### Create a new pipeline in Azure DevOps.
- Go to your Azure DevOps project and navigate to “**Pipelines**” > “**New pipeline**”.
- Select the repository where your code is stored, or choose a template to start with.
- Click on “**Start**” to create a new pipeline.
- Select the “**Starter pipeline**” template.
- Replace the content of the pipeline with the following:
    ```yaml
    trigger:
      - master

    pool: agent-pool

    steps:
    - script: echo Hello, world!
      displayName: 'Run a one-line script'

    - script: |
        echo Add other tasks to build, test, and deploy your project.
        echo See https://aka.ms/yaml
      displayName: 'Run a multi-line script'

    - script: echo Hello, world!
      displayName: 'Run a one-line script'
    ```
    Replace `<your-agent-pool-name>` with the name of the agent pool where your Kubernetes agent is registered.
- Click on “**Save and run**” to save the pipeline and trigger a new build.
If the agent is working correctly, you should see the pipeline running on the Kubernetes agent and the output “Hello, world!” in the build logs.


## Scale the agent deployment using KEDA
That is a great first step, now it would be great to `scale` the agent deployment based on the number of build/release jobs in the queue. 

This can be achieved using **KEDA**. KEDA (Kubernetes-based Event-Driven Autoscaling) is a Kubernetes component that can scale applications based on various metrics such as queue length, CPU usage, or custom metrics. 

### Install KEDA
- Install KEDA on your Kubernetes cluster using the following command:
    ```bash
    helm repo add kedacore https://kedacore.github.io/charts
    helm repo update
    helm install keda kedacore/keda --namespace keda --create-namespace
    ```
- Verify that KEDA is installed:
    ```bash
    kubectl get all -n keda
    ```

### Create a TriggerAuthentication
A TriggerAuthentication resource is used to authenticate with external systems such as Azure DevOps. This resource allows you to securely store credentials and other sensitive information required to connect to external systems.
- Create a TriggerAuthentication YAML file with the following content:
    ```yaml
    apiVersion: keda.sh/v1alpha1
    kind: TriggerAuthentication
    metadata:
      name: azdevops-trigger-auth
    spec:
      kedaVersion: v2
      secretTargetRef:
        - parameter: personalAccessToken
          name: azdevops-agent-secret
          key: AZP_TOKEN
    ```
- Apply the TriggerAuthentication YAML file:
    ```bash
    kubectl apply -f azdevops-trigger-auth.yaml
    ```
### Create a ScaledObject
A ScaledObject resource is used to define the scaling behavior for a deployment based on external metrics. In this case, we will create a ScaledObject that scales the Azure DevOps agent deployment based on the number of pending builds or releases in the Azure DevOps queue.
- Create a ScaledObject YAML file with the following content:
    ```yaml
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: azdevops-agent-scaledobject
    spec:
      scaleTargetRef:
        deploymentName: az-devops-linux
      minReplicaCount: 1
      maxReplicaCount: 5
      triggers:
        - type: azure-pipelines
          metadata:
            poolId: 29
            organizationURLFromEnv: "AZP_URL"
          authenticationRef:
            name: azdevops-trigger-auth
    ```
    - You might be restricted with the max number of agents you can run due to your Azure DevOps subscription. 
    - Pour récupérer le *poolId*, vous pouvez utiliser la commande suivante:
      ```bash
      az pipelines pool list --organization https://dev.azure.com/<your-organization> --pool-name <your-agent-pool> | grep id 
      ```
- Apply the ScaledObject YAML file:
    ```bash
    kubectl apply -f azdevops-agent-scaledobject.yaml
    ```

- Verify that the ScaledObject is created:
    ```bash
    kubectl get scaledobjects -n az-devops
    kubectl get all -n az-devops
    ```
From now on, the Azure DevOps agent deployment will be scaled based on the number of pending builds or releases in the Azure DevOps queue. The agent deployment will automatically scale up or down based on the workload, ensuring that you have enough capacity to handle the build and release jobs efficiently.

### Test the scaling behavior
Let's create a new job in Azure DevOps that will trigger the scaling of the agent deployment.
- Create a new pipeline in Azure DevOps.
- Replace the content of the pipeline with the following:
    ```yaml
    trigger: none

    pool: agent-linux-pool
      
    jobs:
    - job: job1
      steps:
      - task: Bash@3
        inputs:
          targetType: 'inline'
          script: 'sleep 5m'
        displayName: Wait for 5 minutes

    - job: job2
      steps:
      - task: Bash@3
        inputs:
          targetType: 'inline'
          script: 'sleep 5m'
        displayName: Wait for 5 minutes

    - job: job3
      steps:
      - task: Bash@3
        inputs:
          targetType: 'inline'
          script: 'sleep 5m'
        displayName: Wait for 5 minutes
      
    - job: job4
      steps:
      - task: Bash@3
        inputs:
          targetType: 'inline'
          script: 'sleep 5m'
        displayName: Wait for 5 minutes

    - job: job5
      steps:
      - task: Bash@3
        inputs:
          targetType: 'inline'
          script: 'sleep 5m'
        displayName: Wait for 5 minutes
    ```

- Click on “**Save and run**” to save the pipeline and trigger a new build.

If you want to create a user for your agent, you can check under [here](/ci-user/Readme.md)
