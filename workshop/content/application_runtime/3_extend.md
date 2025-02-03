---
title: 'Application Runtime: Extending With Your Own PDF'
---

In this section, you can truly experiment with the solution by bringing your own documents that you might consider for your application, and gauge the quality of responses and the overall solution.

To extend and include your PDF data in this RAG-based approach, there are three very simple steps:

1. Put your PDF document in this repositories **./sample-documents** directory.
2. Upload the document to your Azure Blob storage that was provisioned as part of the infrastructure deployment. Make sure instead of **myfile.pdf** you specify your file name.

    {{< copycode lang="bash" >}}
file_name="myfile.pdf" bash ./helper.sh upload-pdf
{{< /copycode >}} 

3. Run Azure AI Search indexer to index your document.

## Next Steps  
  
That's it! You can now go back to your **demo app**, which is already up and running, and start **asking questions** about the information contained in the PDF document you just uploaded and indexed. The responses will be **grounded in the content** of that document.  
  
Using the same approach, feel free to **index any additional PDF documents** you'd like to experiment with further!  **Happy experimenting!**

---

[&laquo; Setting Up Demo App](/azure-open-ai-rag-oyd-text-images/application_runtime/2_setting_up_demo_apps/) | [Chat History: Overview &raquo;](/azure-open-ai-rag-oyd-text-images/chat_history/1_overview/)
