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

{{< copycode lang="bash" >}}
random_str=$(tr -dc a-z0-9 &lt/dev/urandom | head -c 13; echo)

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
{{< /copycode >}} 

Before we can configure Azure AI Search, we need to add additional data to your **.env** configuration file. 

Navigate to Azure AI Search resource you just created and:

- Copy the **Url** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock"}
	base_url=<url>
	```
![alt](../../images/document_data_management_3_azure_ai_search_1.png)


<details>
  <summary><b>Get help!</b></summary>

Run the command below to get the URL to the resource group you created prior.

{{< copycode lang="bash" >}}
base_url="https://${search_service_name}.search.windows.net"
echo "base_url=${base_url}" >> .env
{{< /copycode >}} 
</details>


- In the left navigation bar, click **Settings** and after click **Keys**. Copy the **Primary admin key** and add to the **.env** file as

	```bash {class="bash-class" id="bash-codeblock"}
	search_service_key=<primary-admin-key>
	```

![alt](../../images/document_data_management_3_azure_ai_search_2.png)

<details>
  <summary><b>Get help!</b></summary>

Run the command below to get the URL to the resource group you created prior.

{{< copycode lang="bash" >}}
search_service_key=$(az search admin-key show \
	--service-name ${search_service_name} \
	--resource-group ${resource_group_name} \
	| jq -r .primaryKey)

echo "search_service_key=${search_service_key}" >> .env
{{< /copycode >}} 
</details>

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
``` 

## 2. Creating Azure Storage Account

Before configuring Azure AI Search, we first need to create an Azure Storage Account. This storage account will serve as the repository where Azure AI Search will load the PDF documents from. Additionally, it will act as the location where we will upload the PDF documents for processing.

Run the command below to create the storage account, and storage the storage account name to the **.env** config file.

{{< copycode lang="bash" >}}
random_str=$(tr -dc a-z0-9 &lt/dev/urandom | head -c 13; echo)
storage_account_name="aoairagoyd${random_str}"
az storage account create \
	--name "aoairagoyd${random_str}" \
	--resource-group "${resource_group_name}" \
	--location "${region}" \
	--kind StorageV2 \
	--sku Standard_LRS \
	--identity-type SystemAssigned

echo storage_account_name="${storage_account_name}" >> .env
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
``` 

Finally, create a storage account container that will serve as the source for Azure AI Search to retrieve the prepared data. This container will store the data that Azure AI Search will process during its operations.

{{< copycode lang="bash" >}}
# Get storage account key for authorization
storage_account_key=$(az storage account keys list \
	--account-name "${storage_account_name}" \
	--resource-group "${resource_group_name}" \
	| jq -r .[0].value)

az storage container create \
	--name "${container_name}" \
	--account-name "${storage_account_name}" \
	--account-key "${storage_account_key}"
{{< /copycode >}} 


## 3. Configuring Azure AI Search

To use Azure AI Search, we need to create an **index**, **indexer**, **data source**, and **skillset**. Let's quickly review what is each of those do.

**Data Source**  
In Azure AI Search, a data source serves as a connection point for indexers. It provides the necessary connection details to enable on-demand or scheduled data refreshes for a target index, pulling data from supported Azure data sources.

**Indexer**  
An indexer automates the process of indexing data from supported Azure data sources, such as Azure Storage, Azure SQL Database, and Azure Cosmos DB, among others. It leverages a predefined data source and index to create an indexing pipeline that extracts, transforms, and serializes the source data before passing it to the search service for ingestion. Additionally, for AI enrichment of images and unstructured text, indexers can incorporate a skillset, which defines the AI processing tasks to be applied during indexing.

**Index**  
A search index represents your searchable content, making it available to the search engine for various operations such as indexing, full-text search, vector search, hybrid search, and filtered queries. The index is defined by a schema, which specifies the structure of the data, including fields, types, and attributes. Once the schema is defined and saved to the Azure AI Search service, data import occurs as a subsequent step to populate the index with content.

**Skillset**  
A skillset in Azure AI Search is a reusable object that is linked to an indexer. It consists of one or more skills, which apply built-in AI capabilities (such as OCR, natural language processing, or entity recognition) or invoke external custom processing to enrich documents retrieved from an external data source. Skillsets allow you to enhance raw data by extracting meaningful information, transforming it into searchable content, and enabling advanced search and analysis capabilities.

Before creating the data source, you need to add your subscription ID to the **.env** configuration file. Use the command below to set your subscription ID.

{{< copycode lang="bash" >}}
subscription_id=$(az account show | jq -r .id)
echo "subscription_id=${subscription_id}" >> .env
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
``` 

### 3.1 Create data source

To create the Azure AI Search data source, we will use the following:  
  
- **subscription_id**: Retrieved from the **.env** file.    
- **resource_group_name**: Retrieved from the **.env** file.    
- **storage_account_name**: Retrieved from the **.env** file.    
- **index_name**: Loaded as an environment variable during the prerequisites step when you run **source helper.sh**.    
- Data source configuration template file, located at **bicep/helpers/datasource.json**.    

Feel free to open the file to take a closer look, either with your preferred text editor or by running the following command:

{{< copycode lang="bash" >}}
cat bicep/helpers/datasource.json
{{< /copycode >}} 

Observe that there is a resemblance between the variables listed above and the placeholder values in all caps within the template file. We'll be using a helper function to replace the placeholder values with the corresponding values from your **.env** configuration file and create the data source in your Azure AI Search.   
  
To create the data source, run the following command below. 

{{< copycode lang="bash" >}}
bash ./helper.sh create-ai-search-data-source
{{< /copycode >}} 

Let's validate that the data source was created successfully. In the Azure portal, open the Azure AI Search resource and follow the steps below. 

- Click **Search management**, and after click **Data sources**
- Validate that you see the new data source.

![alt](../../images/document_data_management_3_azure_ai_search_3.png)


### 3.2 Create index

To create the Azure AI Search index, we'll use the following:  
  
- **AZURE_OPENAI_ENDPOINT**: Azure OpenAI endpoint, as Azure AI Search will be making requests to Azure OpenAI on your behalf. Retrieved from the **.env** file.    
- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_KEY**: Azure OpenAI API key, allowing Azure AI Search to authorize requests to Azure OpenAI. Retrieved from the **.env** file.    
- **index_name**: Loaded as an environment variable during the prerequisites step when you run **source helper.sh**.    
- Index configuration template file, located at **bicep/helpers/index.json**.    
  
Feel free to open the file to take a closer look, either using your preferred editor or by running the following command:  

{{< copycode lang="bash" >}}
cat bicep/helpers/index.json
{{< /copycode >}} 

Similar to the data source helper function, the above values will be used to replace the placeholder values in the template file.

To create the index, run the following command below.

{{< copycode lang="bash" >}}
bash ./helper.sh create-ai-search-index
{{< /copycode >}} 

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

To create the Azure AI Search skillset, we'll use the following:  
  
- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_KEY**: Azure OpenAI API key, allowing Azure AI Search to authorize requests to Azure OpenAI. Retrieved from the **.env** file.    
- **index_name**: Loaded as an environment variable during the prerequisites step when you run **source helper.sh**.    
- Skillset configuration template file, located at **bicep/helpers/skillset.json**.    
  
Feel free to open the file to take a closer look, either using the preferred editor of your choice or by running the following command:  

{{< copycode lang="bash" >}}
cat bicep/helpers/skillset.json
{{< /copycode >}} 

Similar to the previous helper functions, the above values will be used to replace the placeholder values in the template file.

To create the skillset, run the following command below.

{{< copycode lang="bash" >}}
bash ./helper.sh create-ai-search-skillset
{{< /copycode >}} 

Let’s validate that the skillset was created successfully. Inside the Azure AI Search resource:

- Click **Search management**, and after click **Skillsets**
- Validate that you see the new index.

![alt](../../images/document_data_management_3_azure_ai_search_6.png)

Open the skillset and observe the **skills**. As you might have already noticed when looking at the local skillset template file, there is only one skillset configured, which is the **AzureOpenAIEmbeddingSkill** skillset. Let's take a closer look at what this skillset is doing exactly.

**Azure OpenAI Embedding skill**

The Azure OpenAI Embedding skill connects to a deployed embedding model on your Azure OpenAI resource to generate embeddings during indexing.

![alt](../../images/document_data_management_3_azure_ai_search_7.png)

### 3.4 Create indexer

Before we can create the indexer, we need to grant the Azure AI Search system-assigned identity the necessary permissions to access the storage blob. This will allow the indexer to pull data from the storage blob and populate the index.

{{< copycode lang="bash" >}}
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
{{< /copycode >}} 

Now we are ready for the final step in setting up Azure AI Search: creating the indexer. To create the Azure AI Search indexer, we'll use the following:  
  
- **AZURE_OPENAI_ENDPOINT**: Azure OpenAI endpoint. Azure AI Search will use this endpoint to make requests to Azure OpenAI on your behalf. Retrieved from the **.env** file.    
- **AZURE_OPENAI_CHATGPT_EMBEDDING_MODEL_NAME**: Azure OpenAI embedding deployment name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT**: Azure OpenAI embedding model name. Retrieved from the **.env** file.    
- **AZURE_OPENAI_KEY**: Azure OpenAI API key. Azure AI Search uses this key to authorize requests to Azure OpenAI. Retrieved from the **.env** file.    
- **index_name**: The index name, loaded as an environment variable during the prerequisites step when you run **source helper.sh**.    
- Indexer configuration template file, located at **bicep/helpers/indexer.json**.  
  
Feel free to open the configuration template file to take a closer look, either using your preferred editor or by running the following command:  
  

{{< copycode lang="bash" >}}
cat bicep/helpers/indexer.json
{{< /copycode >}} 

Similar to the previous helper functions, the above values will be used to replace the placeholder values in the template file.  
  
To create the indexer, run the following command below.

{{< copycode lang="bash" >}}
bash ./helper.sh create-ai-search-indexer
{{< /copycode >}}

Let’s validate that the indexer was created successfully. Inside the Azure AI Search resource:

- Click **Search management**, and after click **Indexers**
- Validate that you see the new indexer.

![alt](../../images/document_data_management_3_azure_ai_search_8.png)

Also, observe that there aren't any documents that were processed, evidently by *0/0* in both **Docs succeeded** and **Error/Warning**, even though the indexer did run a job upon index creation.

---

**Congratulation!** You've successfully configured your Azure OpenAI resource, and it is now ready to handle PDF data, use Azure OpenAI Search to create embeddings, and populate the index!

Before we can populate the index, we needed to upload the raw PDFs and prepair for the indexer to be able to embed and popular the index - which is exactly what we'll be doing next!

---

[&laquo; Document Data Management: Azure OpenAI](/azure-open-ai-rag-oyd-text-images/document_data_management/2_azure_oai/) | [Document Data Management: PDF Document Processing &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/4_pdf_document_processing/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>
