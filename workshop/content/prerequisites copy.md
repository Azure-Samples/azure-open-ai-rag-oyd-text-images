---
title: Prerequisites
# date: 2021-12-19
---


## Prerequisites

1. [Azure subscription](https://azure.microsoft.com/free/)
  - Permission to create and access resources in Azure
2. [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) 
   
  **Note**: Ensure the az bicep extension is installed. You can install it by running:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
az bicep install
```

3. [Docker](https://docs.docker.com/engine/install/)



**Note**: If you're on Windows, install:
  + [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) with [Ubuntu distro](https://documentation.ubuntu.com/wsl/en/latest/guides/install-ubuntu-wsl2/)
  + [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed inside Ubuntu
  + [Docker](https://docs.docker.com/engine/install/ubuntu/) installed inside Ubuntu

<!-- + If you're on Windows, [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) with [Ubuntu distro](https://documentation.ubuntu.com/wsl/en/latest/guides/install-ubuntu-wsl2/), [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) and [Docker](https://docs.docker.com/engine/install/ubuntu/) to also be installed inside Ubuntu -->


<!-- + Azure Open AI chat and embedding models deployed  
  
  **Note**: If you don't have the models deployed, you can follow the [create and deploy an Azure OpenAI Service resource](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=web-portal) guide to do so.  

  **Note**: This solution was developed and tested using `gpt-4o` as the chat model, and `text-embedding-ada-002` as the embedding model. Alternative models are likely to work too, but for the best experience, we recommend using the same models whenever possible. -->

## Login into your Azure Tenant  

<!-- ```bash {lineNos=inline}
az login --tenant "your-tenant-id-here"
``` -->

<!-- <div style="dark-mode-toggle" >
    <pre>
        <code>
        az login --tenant "your-tenant-id-here"
        </code>
    </pre>
</div> -->



#### Git clone
Clone or download this repo and cd into project's root directory.

---

[<< Home](/) | [Prerequisites >>](/prerequisites)
