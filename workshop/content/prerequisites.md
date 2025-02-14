---
title: Prerequisites
# date: 2021-12-19
---

## Page content
- **Prerequisites**
  - [Prerequisites](#prerequisites) for unix-based OS
  - [Prerequisites for Windows users](#for-windows-users-only)
- [Login into your Azure Tenant](#login-into-your-azure-tenant)
- [Download workshop repository from GitHub](#download-workshop-repository-from-github)
- **Docker**
  - [Build docker image](#build-docker-image)
  - [Run docker container](#run-docker-container)
  - [Exec into the docker container](#exec-into-the-docker-container)
- [Set environment variables](#set-environment-variables)
- [Create Azure resource group](#create-azure-resource-group)

---

## Prerequisites

+ [Azure subscription](https://azure.microsoft.com/free/), and permission to create and access following Azure resources:
    + [Azure Resource Groups](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal)
    + [Azure OpenAI](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview)
    + [Azure AI Search](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search)
    + [Azure Storage Account](https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview)
    + [Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/overview) & [Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview)
    + [Azure Monitor Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
+ [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) 
  + **Note**: Ensure the **az bicep extension** is installed. You can install it by running:
  {{< copycode lang="bash" >}}
az bicep install
{{< /copycode >}}

+ [Docker](https://docs.docker.com/engine/install/)
+ [Git](https://git-scm.com/downloads)

---

## For Windows users only

If you're on Windows, install:
  + [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) with [Ubuntu distro](https://documentation.ubuntu.com/wsl/en/latest/guides/install-ubuntu-wsl2/)
  + [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed inside Ubuntu
  + [Docker](https://docs.docker.com/engine/install/ubuntu/) installed inside Ubuntu
  + [Git](https://git-scm.com/downloads) installed inside Ubuntu

From this point forward, all steps and commands in this workshop will assume you are working on a **Unix-based operating system**. If you are using Windows, please open an **Ubuntu terminal** and ensure your environment is ready to execute the commands provided in the upcoming sections. 

---

## Login into your Azure Tenant  

{{< copycode lang="bash" >}}
az login --tenant "your-tenant-id-here"
{{< /copycode >}} 

## Download workshop repository from GitHub

Clone the repo and cd into project's root directory.

{{< copycode lang="bash" >}}
git clone https://github.com/Azure-Samples/azure-open-ai-rag-oyd-text-images
cd azure-open-ai-rag-oyd-text-images
{{< /copycode >}} 

## Build docker image

This repository includes a **Dockerfile** that builds a Docker image containing all the necessary tools and dependencies required to successfully complete this workshop. Using this Docker image ensures a consistent and hassle-free environment for following the steps. 

To build the Docker image for this workshop, run the following command in the terminal.

{{< copycode lang="bash" >}}
bash ./helper.sh docker-build
{{< /copycode >}} 

## Run docker container

Now that the Docker image is built, you can run a container from this image. The container is configured to use a Docker volume to share your **Azure authentication token** between your local environment and the container. This setup enables you to execute commands inside the container and create Azure resources within your Azure subscription seamlessly.  

{{< copycode lang="bash" >}}
bash ./helper.sh docker-run
{{< /copycode >}} 

## Exec into the docker container

Finally, access the Docker container interactively. From this point forward, all commands and steps for the workshop should be executed **inside the Docker container**.

{{< copycode lang="bash" >}}
bash ./helper.sh docker-exec
{{< /copycode >}} 

Validate you're running inside the docker container. The command **pwd** should return **/home/ubuntu/azure-open-ai-rag-oyd-text-images**.

{{< copycode lang="bash" >}}
pwd
{{< /copycode >}}

---

## Set environment variables

To streamline the workshop, we'll use a local file named **helper.sh** to gather and load environment variables that will be utilized throughout the session. Load the default environment variables to get started.

> Note: If you close your terminal (i.e., exit the Docker container) and open a new one, you'll need to re-run the command to reload the environment variables.

{{< copycode lang="bash" >}}
source helper.sh
{{< /copycode >}} 

Validate environment variables are loaded successfully. The command **echo "${region}"** should return **region="eastus"**.

{{< copycode lang="bash" >}}
echo "${region}"
{{< /copycode >}} 

---

## Create Azure resource group

Create an Azure resource group to host all the resources required for this workshop.

{{< copycode lang="bash" >}}
az group create --name "${resource_group_name}" --location "${region}"
{{< /copycode >}}

---

[&laquo; Workshop Overview](/azure-open-ai-rag-oyd-text-images/workshop_overview/) | [Document Data Management: Overview &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/)

<!-- <div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div> -->
