---
title: 'Application Runtime: Setting Up Demo App'
---

## Page content
1. [Set last variable and validate your .env file](#1-set-last-variable-and-validate-your-env-file)
2. [Create demo application .env file](#2-create-demo-application-env-file)
3. [Installing demo application dependencies](#3-installing-demo-application-dependencies)
4. [Start the demo app](#4-start-the-demo-app)
5. [Try the demo app](#5-try-the-demo-app)

---

## 1. Set last variable and validate your .env file

We need an **Azure Blob SAS token** so the demo app can pull relevant images whenever they are identified in the query response. Run the following command:

{{< copycode lang="bash" >}}
bash ./helper.sh get-blob-sas
{{< /copycode >}} 

## Verify Environment Variables
 
Let’s verify that all necessary variables are set for the demo app to be configured successfully. Run the command below and ensure that every variable appears in your output as shown in the example below.

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
sas_token=<azure-blob-sas-token>
```

## 2. Create demo application .env file

Create .env file for the demo app

{{< copycode lang="bash" >}}
bash ./helper.sh create-dot-env-demo-app
{{< /copycode >}} 

The **.env** file for the demo app is located in the **./demo-app** directory. Run the following command to validate that the file was created successfully and contains all the required variables with assigned values.


**Command:**

{{< copycode lang="bash" >}}
cat .env
{{< /copycode >}} 

**Example output:**

```bash {class="bash-class" id="bash-codeblock"}
AZURE_OPENAI_ENDPOINT=https://la-openai-test.openai.azure.com/
AZURE_OPENAI_KEY=ca2195a42c5e4714ac9b2b49bb52aab6
AZURE_OPENAI_CHATGPT_DEPLOYMENT=test-gpt4o
AZURE_OPENAI_API_VERSION=2024-04-01-preview
AZURE_OPENAI_CHATGPT_EMBEDDING_DEPLOYMENT=embedding-model
SEARCH_ENDPOINT=https://6sglalvnynqxsservice.search.windows.net
SEARCH_INDEX=search-aoai-emb
SEARCH_API_KEY=tKETEOqUBp6bfmiDVKPIXgZ92u2DSWzdERZ8Yjpn2QAzSeBYZjmW
SEARCH_SEMANTIC_CONFIGURATION=search-aoai-emb-semantic-configuration
SEARCH_QUERY_TYPE=vector_semantic_hybrid
BLOB_SAS_TOKEN="<azure-blob-sas-token>"
```

## 3. Installing demo application dependencies

Install demo app python dependencies

{{< copycode lang="bash" >}}
bash ./helper.sh install-demo-app-dependencies
{{< /copycode >}} 

## 4. Start the demo app

Run the demo app.

{{< copycode lang="bash" >}}
bash ./helper.sh run-demo-app
{{< /copycode >}} 

A clear sign your application is running successfully is when you see output similar to the following:

```bash {class="bash-class" id="bash-codeblock"}
You can now view your Streamlit app in your browser.

Local URL: http://localhost:8501
Network URL: http://<IP-ADDRESS>:8501
External URL: http://<IP-ADDRESS>:8501
```

## 5. Try the demo app

Open the demo app in your browser **http://localhost:8501**. In chat window, type **"Tell me about Kubernetes"**. You should see a response and an overall demo app UI view similar to the image below.

Upon successful chat query response, you should be a text response with an image, a high level archtecture about AKS similar to the image shown below.

<img src="https://github.com/Azure-Samples/azure-open-ai-rag-oyd-text-images/blob/workshop/images/demo_app_chat_view.png?raw=true" alt="drawing" width="800"/>

**Congratulations!** You successfully executed end-to-end demo, and the request made through each component of the solution. Ab next, you'll learn how to extend it and bring your own data.

---

[&laquo; Application Runtime: Overview](/azure-open-ai-rag-oyd-text-images/application_runtime/1_overview/) | [Application Runtime: Extending With Your Own PDF &raquo;](/azure-open-ai-rag-oyd-text-images/application_runtime/3_extend/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>