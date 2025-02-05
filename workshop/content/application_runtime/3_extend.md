---
title: 'Application Runtime: Extending With Your Own PDF'
---

In this section, you can truly experiment with the solution by bringing your own documents that you might consider for your application, and gauge the quality of responses and the overall solution.

If you're continuing from the previous section, [setting up demo app](/azure-open-ai-rag-oyd-text-images/application_runtime/2_setting_up_demo_apps/#4-start-the-demo-app) , you’re likely still running the demo app process in your terminal. In this case, you'll need to stop it before proceeding with the upcoming CMD commands. Alternatively, you can open a new terminal, exec into the running Docker container, and source the **helper.sh** file, just as you did in the [prerequisites](/azure-open-ai-rag-oyd-text-images/prerequisites/#exec-into-the-docker-container) section. 


## 1. Upload new PDF documents

To extend and include your PDF data in this RAG-based approach, there are three very simple steps:

1. Put your PDF document in this repositories **./sample-documents** directory.
2. Upload the document to your Azure Blob storage that was provisioned as part of the infrastructure deployment. Make sure instead of **myfile.pdf** you specify your file name.

    {{< copycode lang="bash" >}}
file_name="myfile.pdf" bash ./helper.sh upload-pdf
{{< /copycode >}} 

1. Run Azure AI Search indexer to index your document.

## 2. Run indexer

Remember, after uploading new PDF documents, it's necessary to run the indexer again to update the index with the new data!

Run the below command to run the indexer.

{{< copycode lang="bash" >}}
bash ./helper.sh run-indexer
{{< /copycode >}} 

## Chat with your newly uploaded documents

If you stopped your demo app process as mentioned at the beginning of this section, use the command below to restart the demo app.

{{< copycode lang="bash" >}}
bash ./helper.sh run-demo-app
{{< /copycode >}} 
  
That's it! You can now go back to your **demo app**, which is already up and running, and start **asking questions** about the information contained in the PDF document you just uploaded and indexed. The responses will be **grounded in the content** of that document.  
  
Using the same approach, feel free to **index any additional PDF documents** you'd like to experiment with further!  **Happy experimenting!**

### Note

The **Tokens per Minute Rate Limit** for both models was not configured to be very high. If you experience throttling while interacting with your documents and encounter errors with messages similar to the one below, consider increasing the rate limits for each model to resolve the issue. For more information about quotas, refer to [manage Azure OpenAI Service quota](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/quota).

```json {class="json-class" id="bash-codeblock"}
{
   "error" : {
      "code" : "429",
      "message" : "Rate limit is exceeded. Try again in 2 seconds."
   }
}
```

---

[&laquo; Setting Up Demo App](/azure-open-ai-rag-oyd-text-images/application_runtime/2_setting_up_demo_apps/) | [Chat History: Overview &raquo;](/azure-open-ai-rag-oyd-text-images/chat_history/1_overview/)
