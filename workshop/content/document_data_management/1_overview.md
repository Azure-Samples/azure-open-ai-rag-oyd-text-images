---
title: 'Document Data Management: Overview'
---

This section of the workshop is dedicated to developing the Document Data Management component.
 
### Solution Overview

[Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/overview) provides REST API access to OpenAI's powerful language models including o3-mini, o1, GPT-4o with Vision, GPT-4o mini, and Embeddings model series. These models can be easily adapted to your specific task including but not limited to content generation, summarization, image understanding, semantic search, and natural language to code translation.


[Azure AI Search](https://learn.microsoft.com/en-us/azure/search/search-what-is-azure-search) provides secure information retrieval at scale over user-owned content in traditional and generative AI search applications. Information retrieval is foundational to any app that surfaces text and vectors. Common scenarios include catalog or document search, data exploration, and increasingly feeding query results to prompts based on your proprietary grounding data for conversational and copilot search. 

[Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blobs-introduction) is Microsoft's object storage solution for the cloud. Blob Storage is optimized for storing massive amounts of unstructured data. Unstructured data is data that doesn't adhere to a particular data model or definition, such as text or binary data. 

[Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/functions-overview) is a serverless solution that allows you to write less code, maintain less infrastructure, and save on costs. Instead of worrying about deploying and maintaining servers, the cloud infrastructure provides all the up-to-date resources needed to keep your applications running. 


This solution utilizes several Azure services working together to enable efficient document management and retrieval:  
  
- **Azure OpenAI Models**: Used for text generation and creating embeddings.    
- **Azure AI Search**: Handles information retrieval, ensuring query results are grounded in your proprietary data.    
- **Azure Blob Storage**: Stores raw PDF files and the processed data used by Azure AI Search for efficient retrieval.    
- **Azure Functions**: Acts as a serverless component to process and prepare data for indexing in Azure AI Search.  

---

The following diagram illustrates the end-to-end process, starting from **PDF upload and vectorization** to **data indexing in Azure AI Search**, where it becomes ready to handle query requests effectively.  

![alt](https://github.com/Azure-Samples/azure-open-ai-rag-oyd-text-images/blob/workshop/docs/ArchOverview-Data-Mgmt-v2.png?raw=true)

The document data management flow operates as follows:

1. A raw PDF document file is uploaded to Azure Blob storage.
2. An event trigger in Azure Blob invokes an Azure Function, which then splits large PDFs, extracts text chunks, and maps images to the corresponding text chunks.
3. Once the Azure Function prepares the data, it uploads the prepaired data back to Azure Blob storage.
4. An index scheduler is then invoked to initiate the indexing process for the prepared data.
5. The prepared data is retrieved from Azure Blob by Azure AI Search.
6. Azure AI Search processes the text chunks in parallel, using the Azure OAI embedding model to vectorize the text.
7. The Azure AI Search index is populated with the prepared data and vectorized chunks. Additionally, it maps the relevant images to their corresponding text chunks using a custom index field.

---

[&laquo; Prerequisites](/azure-open-ai-rag-oyd-text-images/prerequisites) | [Document Data Management: Azure OpenAI &raquo;](/azure-open-ai-rag-oyd-text-images/document_data_management/2_azure_oai)
