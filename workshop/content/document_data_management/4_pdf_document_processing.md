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

In this section, we will learn about PDF document processing. Here’s an overview of the steps:  
  
1. **Create an Azure Function App**: Host code for pre-processing tasks like breaking PDFs into smaller text chunks.    
2. **Set Up an Azure Storage Account**: Upload and store the PDFs, source code, and other necessary files.    
3. **Publish the Function App**: Configure it to listen to Azure Blob Storage events, triggering automatically when a new PDF is uploaded.    
  
By the end of this section, you'll understand how to set up these components to efficiently process PDF documents.  

## 1. Create Azure Function app

Our first step involves creating an Azure Function App. This app will host the code responsible for pre-processing PDFs by breaking them into smaller text chunks. Additionally, we need to create an Azure App Service plan, which determines the pricing tier and, consequently, the features and cost of the plan.  
  
Run the command below to create the Azure App Service plan, the Azure Function App, and store the function app name in the **.env** configuration file: 

{{< copycode lang="bash" >}}
appservice_plan_name="${resource_group_name}"
az appservice plan create \
    --name "${appservice_plan_name}" \
    --resource-group "${resource_group_name}" \
    --location "${region}" \
    --sku B1 \
    --is-linux

random_str=$(tr -dc a-z0-9 &lt/dev/urandom | head -c 13; echo)
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
{{< /copycode >}}

Your **.env** file should look as the following:

**Command:**

{{< copycode lang="bash" >}}
cat .env
{{< /copycode >}} 

**Example output:**

```bash {class="bash-class" id="bash-codeblock"}
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

The function will require a few permissions to perform two essential tasks:    
1. **Read PDFs from Azure Blob Storage.**    
2. **Write the processed text chunks and images back to Azure Blob Storage.**    
  
This means the function needs **read/write permissions** for the specific Azure Storage Account used for uploading PDFs. We will assign the built-in **Storage Blob Data Contributor** role to the function app's **system-assigned identity** to grant these permissions.  
  
A **system-assigned identity** is an identity created and managed by the Function App resource itself. Whenever there is a case to grant permission to a system assigend permissions, you can find the system assign identity ID (e.g. object ID) under the Function app resource -> **Settings** -> **Identity** -> **System assigned**. In our case, we'll use the cli command to retreive the object ID for the role assignment.
  
In our case, we'll retrieve the Object ID for the role assignment using a CLI command.  

![alt](../../images/document_data_management_4_pdf_document_processing_1.png)

Run the command below to create the role assignment, scoping the permission only to the one storage account.

{{< copycode lang="bash" >}}
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
{{< /copycode >}} 

## 3. Create Storage Account to host function source code

Before deploying the function code, we need to create an Azure Storage Account to upload the source code and perform a remote deployment. This allows the code build and deployment to occur directly on Azure instead of your local machine.  
  
Run the command below to create the storage account and save the storage account name in the **.env** configuration file.  

{{< copycode lang="bash" >}}
random_str=$(tr -dc a-z0-9 &lt/dev/urandom | head -c 13; echo)
func_storage_account_name="funcaoairag${random_str}"
az storage account create \
	--name "${func_storage_account_name}" \
	--resource-group "${resource_group_name}" \
	--location "${region}" \
	--kind StorageV2 \
	--sku Standard_LRS \
	--identity-type SystemAssigned
echo func_storage_account_name="${func_storage_account_name}" >> .env
{{< /copycode >}} 

Your **.env** file should look as the following:

**Command:**

{{< copycode lang="bash" >}}
cat .env
{{< /copycode >}} 

**Example output:**

```bash {class="bash-class" id="bash-codeblock"}
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

One last step is configuring the Function App. The function also needs the connection string for the Azure Storage Account to access the raw PDF files.   

Run the command below to configure app settings.

{{< copycode lang="bash" >}}
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
{{< /copycode >}} 

## 5. Publish the function app

We're finally ready to publish the function itself! Run the command below to publish the function.

{{< copycode lang="bash" >}}
(cd ./azure-function;
func azure functionapp publish \
    "${function_app}"
)
{{< /copycode >}} 

To validate that the function was published successfully, follow these steps:  
  
1. Open the **Function App** in the Azure Portal.  
2. Navigate to the **Functions** section.  
3. Verify that a function named **split_pdf** is present.  
4. Confirm that the function is configured with a **Blob** trigger.  
  
If all of the above are correct, the deployment was successful.

![alt](../../images/document_data_management_4_pdf_document_processing_2.png)

---

**Congratulations!** You have successfully created the PDF document processing components. Now, we’re ready for the final step of the Document Data Processing workflow:    
  
1. **Upload the PDF document** to the Azure Blob Storage.    
2. **Run the Azure AI Search indexer** to process the document and populate the search index with the extracted data.    
  
---

[&laquo; Document Data Management: Azure AI Search](/azure-open-ai-rag-oyd-text-images/document_data_management/3_azure_ai_search/) | [Document Data Management: Populating Azure AI Index &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/5_populating_azure_ai_index/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

