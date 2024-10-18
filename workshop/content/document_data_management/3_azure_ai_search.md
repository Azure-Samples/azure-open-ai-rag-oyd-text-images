---
title: Deploying Azure AI Search resource and configuring the search index
---

## Page content
- [1. Create and deploy an Azure OpenAI Service resource](#1-create-and-deploy-an-azure-openai-service-resource)
- [2. Creating Azure Storage Account](#2-creating-azure-storage-account)
- [3. Configuring Azure AI Search](#3-configuring-azure-ai-search)
  - [3.1 Create data source](#31-create-data-source)
  - [3.2 Create index](#32-create-index)
    - [3.2.1 Vector search](#321-vector-search)
    - [3.2.2 Semantic ranker](#322-semantic-ranker)
  - [3.3 Create skillset](#33-create-skillset)
  - [3.4 Create indexer](#34-create-indexer)

## 1. Create and deploy an Azure OpenAI Service resource


```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
random_str=$(tr -dc a-z0-9 </dev/urandom | head -c 13; echo)
search_service_name="${resource_group_name}-${random_str}"
az search service create \
	--name "${search_service_name}" \
	--resource-group "${resource_group_name}" \
	--sku basic \
	--semantic-search standard \
	--identity-type SystemAssigned \
	--partition-count 1 \
	--replica-count 1

# add search service name to the .env config file
echo search_service_name="${search_service_name}" >> .env
```


Before we can configure Azure AI Search, we need to add additional data to your **.env** configuration file. 

Navigate to Azure AI Search resource you just created and:

- Copy the **Url** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
		base_url=<url>
	```
![alt](../../images/document_data_management_3_azure_ai_search_1.png)


<details>
  <summary><b>Get help!</b></summary>

Run the command below to get the URL to the resource group you created prior.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
base_url="https://${search_service_name}.search.windows.net"
echo "base_url=${base_url}" >> .env
```
</details>


- In the left navigation bar, click **Settings** and after click **Keys**. Copy the **Primary admin key** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
		search_service_key=<primary-admin-key>
	```

![alt](../../images/document_data_management_3_azure_ai_search_2.png)

<details>
  <summary><b>Get help!</b></summary>

Run the command below to get the URL to the resource group you created prior.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
search_service_key=$(az search admin-key show \
	--service-name ${search_service_name} \
	--resource-group ${resource_group_name} \
	| jq -r .primaryKey)

echo "search_service_key=${search_service_key}" >> .env
```
</details>

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
```

Lastly, create a storage account container from where Azuer AI Search will be pulling the prepaired data from.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# Get storage account key for authorization
storage_account_key=$(az storage account keys list \
	--account-name "${storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .[0].value)

az storage container create \
	--name "${container_name}" \
	--account-name "${storage_account_name}" \
	--account-key "${storage_account_key}"
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
storage_account_name=<storage-account-name>
subscription_id=<subscription-id>
```

### 3.1 Create data source

To create the Azure AI Search data source, we'll use:

- **subscription_id**: we'll be looking it up from the **.env** file
- **resource_group_name**: we'll be looking it up from the **.env** file
- **storage_account_name**: we'll be looking it up from the **.env** file
- **index_name**: which is loaded as environment variable from prerequisites step when you run **source helper.sh**
- data source configuration template file, which is located under **bicep/helpers/datasource.json**

Feel free open the file to have a closer look, either using the prefer editor of your choice, or by running the following command:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
cat bicep/helpers/datasource.json
```

Observe that there is a resemblance between the variables listed above and placeholder values in all caps in the template file. We'll be using a helper funtion, which will replace the placeholder values with values from your **.env** configuration file and create the data source in your Azure AI Search. To create the data source, run the following command below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh create-ai-search-data-source
```

Let's validate that the data source was created successfully. In Azure portal, open the Azure AI Search resource and

- Click **Search management**, and after click **Data sources**
- Validate that you see the new data source.

![alt](../../images/document_data_management_3_azure_ai_search_3.png)


### 3.2 Create index

To create the Azure AI Search index, we'll use:

- **AZURE_OPENAI_ENDPOINT**: Azure OpenAI endpoint, as Azure AI Search will be making the request to Azure Open AI on your behave. We'll be looking it up from the **.env** file
- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_KEY**: Azure OpenAI API key, for Azure AI Search to be able to authorize the requirest to Azure Open AI. We'll be looking it up from the **.env** file
- **index_name**: which is loaded as environment variable from prerequisites step when you run **source helper.sh**
- index configuration template file, which is located under **bicep/helpers/index.json**

Feel free open the file to have a closer look, either using the prefer editor of your choice, or by running the following command:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
cat bicep/helpers/index.json
```

Similar to the data source helper function, the above values will be used to replace the placeholder values in the template file.


To create the index, run the following command below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh create-ai-search-index
```

Let’s validate that the index was created successfully. Inside the Azure AI Search resource:

- Click **Search management**, and after click **Indexes**
- Validate that you see the new index.

![alt](../../images/document_data_management_3_azure_ai_search_4.png)

Open the index and navigate to **Semantic configuration** first, and after to **Vector profiles**. As you see, both is configured. Let's have a closer look what those are and what they do.

![alt](../../images/document_data_management_3_azure_ai_search_5.png)

#### 3.2.1 Vector search

Vector search is an approach in information retrieval that supports indexing and query execution over numeric representations of content. Because the content is numeric rather than plain text, matching is based on vectors that are most similar to the query vector, which enables matching across:

- Semantic or conceptual likeness ("dog" and "canine", conceptually similar yet linguistically distinct)
- Multilingual content ("dog" in English and "hund" in German)
- Multiple content types ("dog" in plain text and a photograph of a dog in an image file)

#### 3.2.2 Semantic ranker

Semantic ranker is a collection of query-side capabilities that improve the quality of an initial [BM25-ranked](https://learn.microsoft.com/en-us/azure/search/index-similarity-and-scoring) or [RRF-ranked](https://learn.microsoft.com/en-us/azure/search/hybrid-search-ranking) search result for text-based queries, vector queries, and hybrid queries. When you enable it on your search service, semantic ranking extends the query execution pipeline in two ways:

- First, it adds secondary ranking over an initial result set that was scored using BM25 or Reciprocal Rank Fusion (RRF). This secondary ranking uses multi-lingual, deep learning models adapted from Microsoft Bing to promote the most semantically relevant results.

- Second, it extracts and returns captions and answers in the response, which you can render on a search page to improve the user's search experience.


### 3.3 Create skillset

To create the Azure AI Search skillset, we'll use:

- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_KEY**: Azure OpenAI API key, for Azure AI Search to be able to authorize the requirest to Azure Open AI. We'll be looking it up from the **.env** file
- **index_name**: which is loaded as environment variable from prerequisites step when you run **source helper.sh**
- skillset configuration template file, which is located under **bicep/helpers/skillset.json**

Feel free open the file to have a closer look, either using the prefer editor of your choice, or by running the following command:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
cat bicep/helpers/skillset.json
```

Similar to the previous helper functions, the above values will be used to replace the placeholder values in the template file.


To create the skillset, run the following command below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh create-ai-search-skillset
```

Let’s validate that the skillset was created successfully. Inside the Azure AI Search resource:

- Click **Search management**, and after click **Skillsets**
- Validate that you see the new index.

![alt](../../images/document_data_management_3_azure_ai_search_6.png)

Open the skillset and observe the **skills**. As you might have already noticed when looking at the local skillset template file, there is only one skillset configured, which is the **AzureOpenAIEmbeddingSkill** skillset. Let's have a closer look what this skillset is doing exactly.

**Azure OpenAI Embedding skill**

The Azure OpenAI Embedding skill connects to a deployed embedding model on your Azure OpenAI resource to generate embeddings during indexing.

![alt](../../images/document_data_management_3_azure_ai_search_7.png)

### 3.4 Create indexer

Before we can create the indexer, we need to give the Azure AI Search system assigned identity the permissions to access the storage blob, so the indexer can pull the data and populate the index. Run the following command to assign built-in Storage Blob Data Reader role.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
# This is the built-in Storage Blob Data Reader role. 
# See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-reader
role="2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
scope=$(az storage account show \
	--name "${storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .id)
assignee=$(az search service show \
	--name "${search_service_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .identity.principalId)

# Assign built-in Storage Blob Data Reader role to the 
# Azure AI Search system assigned identity.
az role assignment create \
	--role "${role}" \
	--scope "${scope}" \
	--assignee "${assignee}"
```

Now we are ready for the last step in setting up Azure AI Search is to create the indexer. To create the Azure AI Search skillset, we'll use:

- **AZURE_OPENAI_ENDPOINT**: Azure OpenAI endpoint, as Azure AI Search will be making the request to Azure Open AI on your behave. We'll be looking it up from the **.env** file
- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name, we'll be looking it up from the **.env** file
- **AZURE_OPENAI_KEY**: Azure OpenAI API key, for Azure AI Search to be able to authorize the requirest to Azure Open AI. We'll be looking it up from the **.env** file
- **index_name**: which is loaded as environment variable from prerequisites step when you run **source helper.sh**
- indexer configuration template file, which is located under **bicep/helpers/indexer.json**

Feel free open the file to have a closer look, either using the prefer editor of your choice, or by running the following command:

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
cat bicep/helpers/indexer.json
```

Similar to the previous helper functions, the above values will be used to replace the placeholder values in the template file.

To create the indexer, run the following command below.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
bash ./helper.sh create-ai-search-indexer
```

Let’s validate that the indexer was created successfully. Inside the Azure AI Search resource:

- Click **Search management**, and after click **Indexers**
- Validate that you see the new indexer.

![alt](../../images/document_data_management_3_azure_ai_search_8.png)

Also, observe that there aren't any documents that were processed, evidently be *0/0* in both **Docs succeeded** and **Error/Warning**, even though the indexer did run a job upon index creation.

---

**Congratulation!** You successfully configured Azure Open AI resource, and it's ready to load some PDF data, use Azure OpenAI search to create the embedding, and populate the index!

Before we can populate the index, we needed to upload the raw PDFs and prepair for the indexer to be able to embed and popular the index - which is exactly what we'll be doing next!

---

[&laquo; Document Data Management: Azure OpenAI](/azure-open-ai-rag-oyd-text-images/document_data_management/2_azure_oai/) | [Document Data Management: PDF Document Processing &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/4_pdf_document_processing/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>
