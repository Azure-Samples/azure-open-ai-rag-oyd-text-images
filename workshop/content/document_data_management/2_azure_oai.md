---
title: Deploying Azure OpenAI resource and models
# date: 2021-12-19
# showthedate: false
# images: 
# - https://raw.githubusercontent.com/apvarun/digital-garden-hugo-theme/main/images/digital-garden-logo.png
---

## 1. Create and deploy an Azure OpenAI Service resource


&laquo;HI&raquo;

> Hi

[Hi >>]()

[Hi >]()

&rsquo;Hi&rsquo;

{{< highlight go >}} A bunch of code here {{< /highlight >}}


<!-- [Let's deploy!!!](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=cli) -->

We will start of by creating Azure Open AI resource in the new resource group you created in [Prerequisites](/azure-open-ai-rag-oyd-text-images/prerequisites#create-azure-resource-group) section. Please run the following connact to create the resource.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
az cognitiveservices account create \
  --name "${resource_group_name}" \
  --resource-group "${resource_group_name}" \
  --location "${region}" \
  --kind OpenAI \
  --sku s0 \
  --yes
```

Let's verify that  Azure OpenAI Service resource was created successfully. Navigate to Azure portal and open the resource group - observe the Azure OpenAI **aoai-rag-oyd** resource is created.

<details>
  <summary><b>Get help!</b></summary>

Run the command below to get the URL to the resource group you created prior.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
domain=$(az rest --method get --url https://graph.microsoft.com/v1.0/domains --query 'value[?isDefault].id' -o tsv)
subscription_id=$(az account show | jq -r .id)
url="https://ms.portal.azure.com/#@${domain}/resource/subscriptions/${subscription_id}/resourceGroups/${resource_group_name}/overview"

# URL to the Azure resource group to see the created resources in it.
echo "${url}"
```
</details>

![alt](../../images/document_data_management_2_azure_oai_1.png)


## 2. Retrieve information about the resource

After you create the resource, you can use different commands to find useful information about your Azure OpenAI Service instance. The following examples demonstrate how to retrieve the REST API endpoint base URL and the access keys for the new resource.

> Please create ".env" file in root directory of the git repository. We will use this file to collect data for later use.

We need to retreive the **Endpoint** and **Key** from the Azure Open AI resource, which you'll use later to setup Azure AI Search, and for the demo application.

Open the Azure Open AI resource and:
- Nagivate to **Resource Management**
- Click **Keys and Endpoint**

### 2.1 Get the Azure OpenAI endpoint URL

You should see the **Endpoint** value. Copy the value and paste it into the **.env** file in the project root directory. It should look as the following:


```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# cat .env
AZURE_OPENAI_ENDPOINT=<endpoint-url>
```

<details>
  <summary><b>Get help!</b></summary>

The endpoint value is in the properties object of the Azure OpenAI Service resource. Run the command below to retreive the endpoint URL.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
AZURE_OPENAI_ENDPOINT=$(az cognitiveservices account show \
  --name "${resource_group_name}" \
  --resource-group  "${resource_group_name}" \
  | jq -r .properties.endpoint)

# write the Azure OpenAI endpoint URL to config file
echo "AZURE_OPENAI_ENDPOINT=${AZURE_OPENAI_ENDPOINT}" >> .env
```
</details>

### 2.2 Get the Azure OpenAI API key

On the same **Keys and Endpoint** setting page, you should see the **KEY 1** value. Copy the value and paste it into the **.env** file in the project root directory. Your **.env** file should look as the following:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# cat .env
AZURE_OPENAI_ENDPOINT=<endpoint-url>
AZURE_OPENAI_KEY=<key-1-value>
```

<details>
  <summary><b>Get help!</b></summary>

The **KEY 1** value is assigned to the **key1** property of the Azure OpenAI Service resource. Run the command below to retreive the endpoint URL.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
	--name "${resource_group_name}" \
    --resource-group "${resource_group_name}" \
    | jq -r .key1)

# write the Azure OpenAI key to config file
echo "AZURE_OPENAI_KEY=${AZURE_OPENAI_KEY}" >> .env
```
</details>


## 3. Create Azure Open AI chat and embedding models

Azure AI search depends on the Azure Open AI embedding model to convert plain text to a vector embedding. The demo application depends on Azure Open AI chat model so end-users can chat with your PDF documents. Therefore we needs to create both models.

### 3.1. Create Azure Open AI embedding model

To create an embedding model, run the comand below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
az cognitiveservices account deployment create \
	--name "${resource_group_name}" \
	--resource-group  "${resource_group_name}" \
	--deployment-name "${model_deployment_name_embedding}" \
	--model-name "${model_name_embedding}" \
	--model-version "${model_version_embedding}" \
	--model-format OpenAI \
	--sku-capacity "1" \
	--sku-name "Standard"
```

Let's validate that the embedding model was created successfully. Open the Azure OpenAi Studio in the left navigation bar, under **Shared resources**, click **Deployments**.

<details>
  <summary><b>Get help!</b></summary>

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
id=$(az cognitiveservices account deployment show \
	--name "${resource_group_name}" \
	--resource-group "${resource_group_name}" \
	--deployment-name ${model_deployment_name_embedding} \
	| jq -r .id)
url="https://oai.azure.com/resource/deployments?wsid=${id}"

# URL to the Azure OpenAI Studio deployments view.
echo "${url}"
```
</details>


![alt](../../images/document_data_management_2_azure_oai_2.png)

We also need the embedding model and deployment name for later for Azure AI Search to have the permissions to call it during the indexing process. Also the demo application will need the deployment name as part of the configuration to configure the Azure OpenAI. Run the following command to add those to the **.env** file.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
echo "AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=${model_deployment_name_embedding}" >> .env
echo "AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME=${model_name_embedding}" >> .env
```

Your **.env** file should look as the following:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# cat .env
AZURE_OPENAI_ENDPOINT=<endpoint-url>
AZURE_OPENAI_KEY=<key-1-value>
AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=aoai-rag-oyd-embedding
AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME=<embedding-model-name>
```

### 3.2. Create Azure Open AI chat model

To create a chat model, run the comand below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
az cognitiveservices account deployment create \
	--name "${resource_group_name}" \
	--resource-group  "${resource_group_name}" \
	--deployment-name "${model_deployment_name_chat}" \
	--model-name "${model_name_chat}" \
	--model-version "${model_version_chat}" \
	--model-format OpenAI \
	--sku-capacity "1" \
	--sku-name "Standard"
```

Let's validate that the chat model was created successfully. Under the same **Deployments** view, click **refresh** and validate that there chat model is present.

From the chat model, we need the deployment name and api version for later use for deo application to be able to connect to the chat model. Run the following command to add those to the **.env** file.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
echo "AZURE_OPENAI_CHATGPT_DEPLOYMENT=${model_deployment_name_chat}" >> .env
echo "AZURE_OPENAI_API_VERSION=${model_version_chat}" >> .env
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
```

---

**Congratulation!** You successfully deployed Azure Open AI resource, and deployed the embedding and the chat models! Next we will deploy and configure Azure AI Search.

---

[<  Document Data Management: Workshop Overview](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/) | [Document Data Management: Azure AI Search >](/azure-open-ai-rag-oyd-text-images/document_data_management/3_azure_ai_search/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

