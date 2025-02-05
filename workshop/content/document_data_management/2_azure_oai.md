---
title: Deploying Azure OpenAI resource and models
# date: 2021-12-19
# showthedate: false
# images: 
# - https://raw.githubusercontent.com/apvarun/digital-garden-hugo-theme/main/images/digital-garden-logo.png
---

## Page content
- [1. Create and deploy an Azure OpenAI Service resource](#1-create-and-deploy-an-azure-openai-service-resource)
- [2. Retrieve information about the resource](#2-retrieve-information-about-the-resource)
  - [2.1 Get the Azure OpenAI endpoint URL](#21-get-the-azure-openai-endpoint-url)
  - [2.2 Get the Azure OpenAI API key](#22-get-the-azure-openai-api-key)
- [3. Create Azure Open AI chat and embedding models](#3-create-azure-open-ai-chat-and-embedding-models)
  - [3.1. Create Azure Open AI embedding model](#31-create-azure-open-ai-embedding-model)
  - [3.2. Create Azure Open AI chat model](#32-create-azure-open-ai-chat-model)
- [4. (Optional) Try the chat model in Azure OpenAI Studio playground](#4-optional-try-the-chat-model-in-azure-openai-studio-playground)

## 1. Create and deploy an Azure OpenAI Service resource

We’ll begin by creating an **Azure OpenAI resource** within the new resource group you created in the [Prerequisites](/azure-open-ai-rag-oyd-text-images/prerequisites#create-azure-resource-group) section. Please execute the following command to create the resource: 

{{< copycode lang="bash" >}} 
az cognitiveservices account create \
  --name "${resource_group_name}" \
  --resource-group "${resource_group_name}" \
  --location "${region}" \
  --kind OpenAI \
  --sku s0 \
  --custom-domain "${resource_group_name}" \
  --yes
{{< /copycode >}}  

To ensure the Azure OpenAI Service resource was created successfully, navigate to the Azure portal and access the resource group. Check that the Azure OpenAI resource named **aoai-rag-oyd** is present.

<details>
  <summary><b>Get help!</b></summary>

Run the following command to retrieve the URL for the resource group you created earlier:

{{< copycode lang="bash" >}}

domain=$(az rest --method get --url https://graph.microsoft.com/v1.0/domains --query 'value[?isDefault].id' -o tsv)
subscription_id=$(az account show | jq -r .id)
url="https://ms.portal.azure.com/#@${domain}/resource/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/overview"

# URL to the Azure resource group to see the created resources in it.
echo "${url}"
{{< /copycode >}}

</details>

![alt](../../images/document_data_management_2_azure_oai_1.png)


## 2. Retrieve information about the resource

After creating the Azure OpenAI Service resource, you can use various commands to gather useful details about your instance. Below are examples of commands to retrieve the REST API endpoint base URL and the access keys for your new resource.  

> To store environment variables for later use, create a ".env" file in the root directory of your Git repository. This file will be used to securely collect and manage sensitive data like API keys, endpoints, and other configuration details.  

{{< copycode lang="bash" >}}
touch .env
{{< /copycode >}}

To set up **Azure AI Search** and use these credentials in the demo application, you need to retrieve the **Endpoint** and **Key** from your Azure OpenAI resource. Follow the steps below to fetch this information.  

Open the Azure Open AI resource and:
- Nagivate to **Resource Management**
- Click **Keys and Endpoint**

### 2.1 Get the Azure OpenAI endpoint URL

You should see the **Endpoint** value. Copy the value and paste it into the **.env** file in the project root directory. It should look as the following:

After retrieving the **Endpoint** value from your Azure OpenAI resource, copy the value and paste it into the **.env** file located in the root directory of your project. Your **.env** file should look as following:

**Command:**

{{< copycode lang="bash" >}}
cat .env
{{< /copycode >}} 

**Example output:**

<!-- ```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
AZURE_OPENAI_ENDPOINT=<endpoint-url>
```  -->

```bash {class="bash-class" id="bash-codeblock"}
AZURE_OPENAI_ENDPOINT=<endpoint-url>
``` 

<details>
  <summary><b>Get help!</b></summary>

The endpoint value is in the properties object of the Azure OpenAI Service resource. Run the command below to retreive the endpoint URL.

{{< copycode lang="bash" >}}
AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name "${resource_group_name}" \
  --resource-group  "${resource_group_name}" \
  | jq -r .properties.endpoint)

# write the Azure OpenAI endpoint URL to config file
echo "AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}" >> .env
{{< /copycode >}}

</details>

### 2.2 Get the Azure OpenAI API key

On the same **Keys and Endpoint** setting page, you should see the **KEY 1** value. Copy the value and paste it into the **.env** file in the project root directory. Your **.env** file should look as the following:

**Command:**

{{< copycode lang="bash" >}}
cat .env
{{< /copycode >}} 

**Example output:**

```bash {class="bash-class" id="bash-codeblock"}
AZURE_OPENAI_ENDPOINT=<endpoint-url>
AZURE_OPENAI_KEY=<key-1-value>
``` 

<details>
  <summary><b>Get help!</b></summary>

The **KEY 1** value is assigned to the **key1** property of the Azure OpenAI Service resource. Run the command below to retreive the endpoint URL.

{{< copycode lang="bash" >}}
AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
	--name "${resource_group_name}" \
    --resource-group "${resource_group_name}" \
    | jq -r .key1)

# write the Azure OpenAI key to config file
echo "AZURE_OPENAI_KEY=${AZURE_OPENAI_KEY}" >> .env
{{< /copycode >}} 

</details>


## 3. Create Azure Open AI chat and embedding models

To set up **Azure AI Search** and the **demo application**, you need to create two Azure OpenAI models:  
  
1. **Embedding Model**: Converts plain text into vector embeddings, which are essential for Azure AI Search.  
2. **Chat Model**: Powers the demo application, allowing end-users to interact with PDF documents through chat.  
  

### 3.1. Create Azure Open AI embedding model

To create an embedding model, run the comand below.

{{< copycode lang="bash" >}}
az cognitiveservices account deployment create \
	--name "${resource_group_name}" \
	--resource-group  "${resource_group_name}" \
	--deployment-name "${model_deployment_name_embedding}" \
	--model-name "${model_name_embedding}" \
	--model-version "${model_version_embedding}" \
	--model-format OpenAI \
	--sku-capacity "10" \
	--sku-name "Standard"
{{< /copycode >}} 

Let's validate that the embedding model was created successfully. Open the Azure OpenAI Studio in the left navigation bar, under **Shared resources**, click **Deployments**.

<details>
  <summary><b>Get help!</b></summary>

{{< copycode lang="bash" >}}
id=$(az cognitiveservices account deployment show \
	--name "${resource_group_name}" \
	--resource-group "${resource_group_name}" \
	--deployment-name ${model_deployment_name_embedding} \
	| jq -r .id)
url="https://oai.azure.com/resource/deployments?wsid=${id}"

# URL to the Azure OpenAI Studio deployments view.
echo "${url}"
{{< /copycode >}} 

</details>


![alt](../../images/document_data_management_2_azure_oai_2.png)

We need the embedding model and its deployment name to enable Azure AI Search to access it during the indexing process. Additionally, the demo application requires the deployment name as part of its configuration to set up Azure OpenAI. Use the following command to add these details to the **.env** file.

{{< copycode lang="bash" >}}
echo "AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=${model_deployment_name_embedding}" >> .env
echo "AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME=${model_name_embedding}" >> .env
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
``` 


### 3.2. Create Azure Open AI chat model

To create a chat model, run the comand below.

{{< copycode lang="bash" >}}
az cognitiveservices account deployment create \
	--name "${resource_group_name}" \
	--resource-group  "${resource_group_name}" \
	--deployment-name "${model_deployment_name_chat}" \
	--model-name "${model_name_chat}" \
	--model-version "${model_version_chat}" \
	--model-format OpenAI \
	--sku-capacity "10" \
	--sku-name "Standard"
{{< /copycode >}} 


Let's validate that the chat model was created successfully. Under the same **Deployments** view, click **refresh** and validate that there chat model is present.

From the chat model, we need the deployment name and api version for later use for deo application to be able to connect to the chat model. Run the following command to add those to the **.env** file.

{{< copycode lang="bash" >}}
echo "AZURE_OPENAI_CHATGPT_DEPLOYMENT=${model_deployment_name_chat}" >> .env
echo "AZURE_OPENAI_API_VERSION=${model_version_chat}" >> .env
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
``` 

## 4. (Optional) Try the chat model in Azure OpenAI Studio playground

Now that the chat model has been successfully deployed, you can test it in the playground! In the left navigation menu, navigate to **Playground** and select **Chat**. A chat interface with a free-form text input box will appear. Enter your query in the text box and press Enter to interact with the model.

![alt](../../images/document_data_management_2_azure_oai_3b.png)

---

**Congratulations!** You have successfully deployed the Azure OpenAI resource along with the embedding and chat models! Next, we will move on to deploying and configuring Azure AI Search.

---

[&laquo; Document Data Management: Workshop Overview](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/) | [Document Data Management: Azure AI Search &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/3_azure_ai_search/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

