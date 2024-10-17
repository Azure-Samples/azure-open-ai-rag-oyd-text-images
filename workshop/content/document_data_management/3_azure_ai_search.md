---
title: Deploying Azure AI Search resource and configuring the search index
---

## 1. Create and deploy an Azure OpenAI Service resource


```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
random_str=$(tr -dc a-z0-9 </dev/urandom | head -c 13; echo)
az search service create \
	--name "${resource_group_name}-${random_str}" \
	--resource-group "${resource_group_name}" \
	--sku basic \
	--semantic-search standard \
	--partition-count 1 \
	--replica-count 1
```

<!-- base_url  
search_service_key  
subscription_id

subscription_id=$(az account show | jq -r .id) -->

Before we can configure Azure AI Search, we need to add additional data to your **.env** configuration file. 

Navigate to Azure AI Search resource you just created and:

- Copy the service name and add to the **.env** file as 

	```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
	search_service_name=<service-name>
	```
- Copy the **Url** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
		base_url=<url>
	```
![alt](../../images/document_data_management_3_azure_ai_search_1.png)

- In the left navigation bar, click **Settings** and after click **Keys**. Copy the **Primary admin key** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
		search_service_key=<primary-admin-key>
	```

![alt](../../images/document_data_management_3_azure_ai_search_2.png)


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
```

## 2. Creating Azure Storage Account

Before we can configure Azure AI Search, we need to create an Azure Storage Account, as we need a place for Azure AI Search to load the PDF documents from. With that, this storage account will also be the place where we'll upload PDF documents.

Run the command below to create the storage account, and storage the storage account name to the **.env** config file.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
random_str=$(tr -dc a-z0-9 </dev/urandom | head -c 13; echo)
storage_account_name="aoairagoyd${random_str}"
az storage account create \
	--name "aoairagoyd${random_str}" \
	--resource-group "${resource_group_name}" \
	--location "${region}" \
	--kind StorageV2 \
	--sku Standard_LRS \
	--identity-type SystemAssigned

echo storage_account_name="${storage_account_name}" >> .env
```


## 3. Configuring Azure AI Search

To use Azure AI Search, we need to create an **index**, **indexer**, **data source**, and **skillset**. Let's quickly review what is each of those do.

**Data Source**  
In Azure AI Search, a data source is used with indexers, providing the connection information for on demand or scheduled data refresh of a target index, pulling data from supported Azure data sources.

**Indexer**  
An indexer automates indexing from supported Azure data sources such as Azure Storage, Azure SQL Database, and Azure Cosmos DB to name a few. Indexers use a predefined data source and index to establish an indexing pipeline that extracts and serializes source data, passing it to a search service for data ingestion. For AI enrichment of image and unstructured text, indexers can also accept a skillset that defines AI processing.

**Index**  
a search index is your searchable content, available to the search engine for indexing, full text search, vector search, hybrid search, and filtered queries. An index is defined by a schema and saved to the search service, with data import following as a second step.

**Skillset**  
A skillset is a reusable object in Azure AI Search that's attached to an indexer. It contains one or more skills that call built-in AI or external custom processing over documents retrieved from an external data source.

Before we can start creating the data source, we need to add your subscription id to the **.env** configuration file. Run the command below to the subscription id.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
subscription_id=$(az account show | jq -r .id)
echo "subscription_id=${subscription_id}" >> .env
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
subscription_id=<subscription-id>
```

### 3.1 Create data source



---

[&laquo; Document Data Management: Azure OpenAI](/azure-open-ai-rag-oyd-text-images/document_data_management/2_azure_oai/) | [Document Data Management: PDF Document Processing &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

