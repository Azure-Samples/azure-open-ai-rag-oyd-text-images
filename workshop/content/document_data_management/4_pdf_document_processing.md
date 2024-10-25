---
title: PDF Document Processing
---

## Page content
1. [Create Azure Function app](#1-create-azure-function-app)
2. [Give Function app access permission](#2-give-function-app-access-permission)
3. [Create Storage Account to host function source code](#3-create-storage-account-to-host-function-source-code)
4. [Configure Function App setting](#4-configure-function-app-setting)
5. [Publish the function app](#5-publish-the-function-app)

---

In this section, we will be learning about PDF document processing. Here’s an overview of the steps we will be taking:

1. **Create an Azure Function App**: This will host the code responsible for the pre-processing tasks, such as breaking down PDFs into smaller text chunks.
2. **Set Up an Azure Storage Account**: This account will be used to upload and store the source code and other necessary files.
3. **Publish the Function App**: Once our function app is set up, we will configure it to listen for events in an Azure Blob storage. This will allow the function app to automatically trigger whenever a new PDF is uploaded.

By the end of this session, you'll understand how to set up these components and how they work together to process PDF documents efficiently. 

## 1. Create Azure Function app

Our first step involves creating an Azure Function App. This app will host the code responsible for pre-processing the PDFs by breaking them down into smaller text chunks. We also need to create an Azure App Service plan, which essentially dectates the pricing tier and therefor  determines what App Service features you get and how much you pay for the plan.

Run the command below to create the Azure App Service plan and the Azure Function app, and storage the function app name to the **.env** config file.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
appservice_plan_name="${resource_group_name}"
az appservice plan create \
    --name "${appservice_plan_name}" \
    --resource-group "${resource_group_name}" \
    --location "${region}" \
    --sku B1 \
    --is-linux

random_str=$(tr -dc a-z0-9 </dev/urandom | head -c 13; echo)
function_app="${resource_group_name}-${random_str}"
az functionapp create \
    --name "${function_app}" \
    --resource-group "${resource_group_name}" \
    --os-type "Linux" \
    --runtime "python" \
    --runtime-version "3.11" \
    --plan "${appservice_plan_name}" \
    --assign-identity '[system]' \
    --functions-version 4 \
    --storage-account "${storage_account_name}"
echo function_app="${function_app}" >> .env
```

Your **.env** file should look as the following:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# cat .env
AZURE_OPENAI_ENDPOINT=<endpoint-url>
AZURE_OPENAI_KEY=<key-1-value>
AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=aoai-rag-oyd-embedding
AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME=<embedding-model-name>
AZURE_OPENAI_CHATGPT_DEPLOYMENT=aoai-rag-oyd-chat
AZURE_OPENAI_API_VERSION=<chat-model-api-version>
search_service_name=<service-name>
base_url=<url>
search_service_key=<primary-admin-key>
storage_account_name=<storage-account-name>
subscription_id=<subscription-id>
function_app=<function-app-name>
```

## 2. Give Function app access permission

The function will need few permissions to do two essential task:
1. Read PDF from the Azure Blob
2. After processing, write the text chunks and images from the PDF back to Azure Blob

That means, the function need read/write permission for the specific Azure Storage Account that we use to upload PDF. We will be giving the built-in Storage Blob Data Contributor role to the function app system identity to have those permissions in place.

A system identity, is an identity that is created with and managed by the Function App resource itself. Whenever there is a case to grant permission to a system assigend permissions, you can find the system assign identity ID (e.g. object ID) under the Function app resource -> **Settings** -> **Identity** -> **System assigned**. In our case, we'll use the cli command to retreive the object ID for the role assignment.

![alt](../../images/document_data_management_4_pdf_document_processing_1.png)

Run the command below to create the role assignment, scoping the permission only to the one storage account.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidt
# This is the built-in Storage Blob Data Contributor role.
# See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
role="ba92f5b4-2d11-453d-a403-e96b0029c9fe"
scope=$(az storage account show \
	--name "${storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .id)
assignee=$(az functionapp show \
	--name "${function_app}" \
	--resource-group "${resource_group_name}" \
	| jq -r .identity.principalId)

# Assign built-in Storage Blob Data Contributor role to the 
# Azure AI Search system assigned identity.
az role assignment create \
	--role "${role}" \
	--scope "${scope}" \
	--assignee "${assignee}"
```

## 3. Create Storage Account to host function source code

Before deploying the function code itself, we also need an Azure Storage account so we can upload the source code and run remote deployment. Meaning, the code build and deployment will be happening on Azure vs on your local machine.

Run the command below to create the storage account, and storage the function storage account name to the **.env** config file.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidt
random_str=$(tr -dc a-z0-9 </dev/urandom | head -c 13; echo)
func_storage_account_name="funcaoairag${random_str}"
az storage account create \
	--name "${func_storage_account_name}" \
	--resource-group "${resource_group_name}" \
	--location "${region}" \
	--kind StorageV2 \
	--sku Standard_LRS \
	--identity-type SystemAssigned
echo func_storage_account_name="${func_storage_account_name}" >> .env
```

Your **.env** file should look as the following:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# cat .env
AZURE_OPENAI_ENDPOINT=<endpoint-url>
AZURE_OPENAI_KEY=<key-1-value>
AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=aoai-rag-oyd-embedding
AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME=<embedding-model-name>
AZURE_OPENAI_CHATGPT_DEPLOYMENT=aoai-rag-oyd-chat
AZURE_OPENAI_API_VERSION=<chat-model-api-version>
search_service_name=<service-name>
base_url=<url>
search_service_key=<primary-admin-key>
storage_account_name=<storage-account-name>
subscription_id=<subscription-id>
function_app=<function-app-name>
func_storage_account_name=<func-storage-account-name>
```

## 4. Configure Function App setting

Once last step, configuring the Function App. The function additionally needs to know the connection string from where to pull the data from (aka raw PDF files).

Run the command below to configure app settings.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
source .env
endpoint_suffix="core.windows.net"
storage_account_key=$(az storage account keys list \
	--account-name "${storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .[0].value)
func_storage_account_key=$(az storage account keys list \
	--account-name "${func_storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .[0].value)

az functionapp config appsettings set \
    --name "${function_app}" \
    --resource-group "${resource_group_name}" \
    --settings \
        AzureWebJobsStorage="DefaultEndpointsProtocol=https;AccountName=${func_storage_account_name};EndpointSuffix=${endpoint_suffix};AccountKey=${func_storage_account_key}" \
        FUNCTIONS_EXTENSION_VERSION="~4" \
        SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
        BLON_STORAGE_CONNECTION="DefaultEndpointsProtocol=https;AccountName=${storage_account_name};EndpointSuffix=${endpoint_suffix};AccountKey=${storage_account_key}"
```

## 5. Publish the function app

We're finally ready to publish the function itself! Run the command below to publish the function.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
(cd ./azure-function;
func azure functionapp publish \
    "${function_app}"
)
```

Let's validate that the function was published successfully. Open the Function app and under **Functions** section observe the there is a function present with the name **split_pdf**. Further, observe that it has **Blob** trigger.

![alt](../../images/document_data_management_4_pdf_document_processing_2.png)

---

Congratulation! You successfully created the PDF document processing components, and we're ready for the final part of the Document Data Processing - let's upload the PDF document and run the Azure AI Search indexer to populate the index with data!

---

[&laquo; Document Data Management: Azure AI Search](/azure-open-ai-rag-oyd-text-images/document_data_management/3_azure_ai_search/) | [Document Data Management: Populating Azure AI Index &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/5_populating_azure_ai_index/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

