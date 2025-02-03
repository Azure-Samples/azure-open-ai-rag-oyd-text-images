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
  + **Note**: Ensure the az bicep extension is installed. You can install it by running:

  ```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
    az bicep install
    ```

+ [Docker](https://docs.docker.com/engine/install/)
+ [Git](https://git-scm.com/downloads)

---

## For Windows users only

If you're on Windows, install:
  + [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) with [Ubuntu distro](https://documentation.ubuntu.com/wsl/en/latest/guides/install-ubuntu-wsl2/)
  + [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed inside Ubuntu
  + [Docker](https://docs.docker.com/engine/install/ubuntu/) installed inside Ubuntu
  + [Git](https://git-scm.com/downloads) installed inside Ubuntu

From this point on, all steps and commands will be executed assuming you're using Unix-based OS. Please open an Ubuntu terminal to continue.

---

## Login into your Azure Tenant  

```bash {lineNos=inline}
az login --tenant "your-tenant-id-here"
```

## Download workshop repository from GitHub

Clone the repo and cd into project's root directory.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
git clone https://github.com/Azure-Samples/azure-open-ai-rag-oyd-text-images
cd azure-open-ai-rag-oyd-text-images
```

## Build docker image

This repository comes with a Dockerfile what builds a Docker image with all tools you'll need to successfully be able to follow this workshop.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh docker-build
```

## Run docker container

Now that the docker image is build, run the container from this image. This image will create a docker volume so your Azure token is shared into the container. This will allow to run further command inside the container and create Azure resources in your Azure subsciption.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh docker-run
```


## Exec into the docker container

Lastly, exec into docker container. Going forward, please run all the commands from within the container throughout this workshop.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh docker-exec
```

Validate you're running inside the docker container. The command **pwd** should return **/home/ubuntu/azure-open-ai-rag-oyd-text-images**.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
pwd
```

---

## Set environment variables

To make the workshop smoother, we'll use a local file **helper.sh** to collect and load environment variable that we'll cake use of throughout the workshop.

Load the default environment variables.

> Note: If you close your terminal (aka exit the docker container) and open a new one, you have to re-run the command again to load the environment variables.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
source helper.sh
```

Validate environment variables are loaded successfully. The command **echo "${region}"** should return **region="eastus"**.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
echo "${region}"
```

---

## Create Azure resource group

Create a resource group in which all the resources in this workshop will be deployed.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
az group create --name "${resource_group_name}" --location "${region}"
```

---

[&laquo; Workshop Overview](/azure-open-ai-rag-oyd-text-images/workshop_overview/) | [Document Data Management: Overview &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/)

<!-- <div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div> -->
