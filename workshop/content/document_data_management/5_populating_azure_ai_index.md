---
title: Populating Azure AI Index
---

## Page content

## 1. Upload the PDF document

Befoer we can populate the Azure AI index, we need first to upload a PDF document to the storage account.

The git repository comes with a small sample PDF document, a snipped from our Azure AKS service. You can locate and view the PDF under **./sample-documents/Azure-Kubernetes-Service.pdf**. Later, you will learn how you can index your own PDF documents using this solution, but for now we'll start with this sample PDF.

Run the command below to upload the sample PDF document.

{{< copycode lang="bash" >}}
bash ./helper.sh upload-pdf
{{< /copycode >}} 

Let's validate that the PDF was indeed uploaded to the storage account. Open the storage account and

1. Click **Storage browser**
2. Click **Blob containers** and **data**

Observe that there is **raw_data** directory. Now click at the directory and validate that the **Azure-Kubernetes-Service.pdf** file is present.

<details>
  <summary><b>Get help!</b></summary>

If you're unsure which storage account it is to look for the PDF document, run the command below!

{{< copycode lang="bash" >}}
echo "${storage_account_name}"
{{< /copycode >}} 
</details>

![alt](../../images/document_data_management_5_populating_azure_ai_index_1.png)


At this point the data source already be prepaired, and most likely you also saw the **prepaired_data** directory.

Go back to the **data** container and open the **prepaired_data** directory. Observe:

1. There is an **image** directory
2. There is a **text** directory

![alt](../../images/document_data_management_5_populating_azure_ai_index_2.png)

Click at the **text** directory and observe that there is the **Azure-Kubernetes-Service.json** file. Let's download it and look at the JSON object structure. Run the below command to download the file.

{{< copycode lang="bash" >}}
storage_account_key=$(az storage account keys list \
    --account-name "${storage_account_name}" \
    --resource-group "${resource_group_name}" \
    --output tsv \
    --query "[0].value")

az storage blob download \
    --account-name "${storage_account_name}" \
    --container-name data \
    --name "prepaired_data/text/Azure-Kubernetes-Service.json" \
    --account-key "${storage_account_key}" | json_pp
{{< /copycode >}} 

Observe that the structure of the object is an array and each object there is a content chunk, and an array of image url. Meaning, there could be zero to many images that are mapped to a chunk of text, and an object will be mapped to the object in Azure AI Search index. We'll look at it a bit closer once we populate the index.

Before we run the indexer, let's also validate that the images are also present in the **image** directory. 

1. Go back to **prepaired_data** directory, and open the **image** directory.
2. Click at the **Azure-Kubernetes-Service** directory
3. Observe there are ***.png** image files.

Feel free to download any and open on your local machine.

## 2. Run indexer

Now that we know the prepaired data is ready, we're also to finally run the indexer and populate the index!

Run the below command to run the indexer.

{{< copycode lang="bash" >}}
bash ./helper.sh run-indexer
{{< /copycode >}} 

Let's validate the indexer ran sucessully. Open the Azure AI Search resource and

1. Click **Search management** and than click **Indexers**
2. Observe the **Status** is **Success**
3. Also observe the **Docs succeded** isn't zero anymore but is **8/8**
4. Lastly, observe that under **Error/Warning** it's **0/0**, meaning all chunks are indexed successfully.

![alt](../../images/document_data_management_5_populating_azure_ai_index_3.png)

Let's explore further details about the indexer process. Click at **search-aoai-emb-indexer** to see more details.

In this view you can see further helpful details, such as:

1. Indexer runs over time and status of each run
2. Duration of each run and number of docs that succeded or had error or warning.
3. In case there are error or warnings, you could click at the status of the individual run, **Success** in our case, and see further details about the errors and warnings.

![alt](../../images/document_data_management_5_populating_azure_ai_index_4.png)

## 3. Query Azure Ai Search index using the build-in Search feature 

Azure AI Search comes with build-in search feature, let's try it out. From the Azure AI Search resource:

1. Click **Search management** and after click **Indexes**
2. Click at the **search-aoai-emb** index name
3. In **Search explorer**, enter **kubernetes** and click the **Search** button.
4. Observe that in the **Results** you see relevant search result to the search query (aka **kubernetes**).

![alt](../../images/document_data_management_5_populating_azure_ai_index_5.png)

You can also write advance queries using the search explorer, to do so

1. Click **View** and select **JSON view**
2. Observe that the simple input field changed to **JSON query editor**, where you can write more complex queries using the [lucene query syntax](https://learn.microsoft.com/en-us/azure/search/query-lucene-syntax).

![alt](../../images/document_data_management_5_populating_azure_ai_index_6.png)

---

Congratulations! You successfully populated the Azure AI Search index, and with that completed the Document Data Management section!

---

[&laquo; Document Data Management: PDF Document Processing](/azure-open-ai-rag-oyd-text-images/document_data_management/4_pdf_document_processing/) | [Application Runtime: Overview &raquo;](/azure-open-ai-rag-oyd-text-images/application_runtime/1_overview/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

