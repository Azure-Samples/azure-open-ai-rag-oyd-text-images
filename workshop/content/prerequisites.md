---
title: Prerequisites
# date: 2021-12-19
---

## Prerequisites

+ [Azure subscription](https://azure.microsoft.com/free/)
  + Permission to create and access resources in Azure
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

---

[< Workshop Overview](/azure-open-ai-rag-oyd-text-images/workshop_overview/) | [Document Data Management: Overview >](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/)

<!-- <div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div> -->
