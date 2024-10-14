---
title: Use Case Overview
# date: 2021-12-19
---

In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.

 

Customers have PDF documents with text and embedded figures which could be images or diagrams holding valuable information that they would like to use as a context to the LLM to answer a given user query. Parsing those PDFs to implement an efficient RAG solution is challenging, especially when the customer wants to maintain the relationship between the text and extracted image context used to answer the user query.  Also, referencing the image as part of the citation which answers the user query is also challenging if the images are not extracted and are retrievable. This blog post is addressing the challenge of extracting PDF content with text and images as part of the RAG solution, where the relationship between the searchable text context with any of its extracted images is maintained so that the images can be retrieved as references within the citations.

 

Below we outline a simple architecture to build a RAG application on PDF data, where the extracted image content within the PDF is also retrievable as part of the LLM output as part of citation references. 

 

## Workshop Steps to Build the Solution
 

### 1. Document Data Management
 
Step 1.1: Creating Azure OpenAI Chat and Embedding Model

To begin, we utilize Azure OpenAI for text generation and embeddings. By navigating to the Azure portal, we create an Azure OpenAI service and configure it to use models such as GPT-4, GPT-3.5-Turbo, or the Embeddings model series. This setup includes generating the necessary API keys for accessing these powerful language models.

Step 1.2: Creating and Configuring Azure AI Search

Next, we set up Azure AI Search for efficient information retrieval. This involves creating a new Azure AI Search service within the Azure portal and configuring the search index schema to include fields for text chunks and their associated images. Enabling semantic search capabilities further enhances the query processing power of our application.

Step 1.3: Creating Azure Function and Azure Blob

To automate the processing of PDF documents, we set up an Azure Blob Storage account to store both raw and processed PDF data. We then create an Azure Function that triggers upon new PDF uploads to Azure Blob Storage. This function is responsible for splitting PDFs into text chunks, extracting images, and mapping these images to the corresponding text chunks. Once this data is prepared, the function uploads it back to Azure Blob Storage.

Step 1.4: Uploading PDF Document and Running AI Search Indexer

With our Azure Function in place, we upload a sample PDF document to the designated Azure Blob Storage container. The Azure Function processes the document, splitting it into manageable text chunks and extracting images. We then configure and run the Azure AI Search indexer to ingest the prepared data, effectively populating the search index and making the data ready for retrieval.

### 2. Application Runtime
 
Step 2.1: Configuring and Running the Demo Application

We proceed by setting up and running a demo application to handle user queries. This involves deploying a server-side AI chatbot application that forwards user queries to Azure OpenAI. The chatbot is integrated with Azure AI Search to retrieve relevant text and images based on the user's query. The application generates responses and sends them back to the client-side interface, ensuring that image citations are included where applicable.

Step 2.2: Extending AI Search Index with Further/Custom Documents

To broaden the scope of our application, we can extend the AI Search index by adding more documents. This involves uploading additional PDF documents to Azure Blob Storage and allowing the Azure Function to process these new documents. Running the AI Search indexer again updates the search index with the new content. We then test the demo application to confirm that it can retrieve information from the extended index, ensuring a robust and scalable solution.

### 3. Chat History
 
Step 3.1: Extending the Solution by Adding User Chat History Functionality

To enhance the application further, we can implement a feature to store and retrieve user chat history. This involves setting up a database, such as Azure Cosmos DB, to log each user interaction, including their queries and the corresponding responses. We modify the server-side AI chatbot application to save this interaction data and provide an interface in the client-side application for users to view their chat history. This ensures that past interactions are accessible, providing context for future queries and enhancing the overall user experience.

---

[< Home](/azure-open-ai-rag-oyd-text-images) | [Prerequisites >](/azure-open-ai-rag-oyd-text-images/prerequisites)
