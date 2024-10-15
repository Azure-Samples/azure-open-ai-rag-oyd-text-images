---
title: Deploying Azure AI Search
# date: 2021-12-19
# showthedate: false
# images: 
# - https://raw.githubusercontent.com/apvarun/digital-garden-hugo-theme/main/images/digital-garden-logo.png
---

## Create and deploy an Azure OpenAI Service resource

<!-- [Let's deploy!!!](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource?pivots=cli) -->

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
  az cognitiveservices account create \
    --name "${resource_group_name}" \
    --resource-group "${resource_group_name}" \
    --location "${region}" \
    --kind OpenAI \
    --sku s0 
    --yes
```

## Retrieve information about the resource

After you create the resource, you can use different commands to find useful information about your Azure OpenAI Service instance. The following examples demonstrate how to retrieve the REST API endpoint base URL and the access keys for the new resource.

## Get the endpoint URL

The endpoint value is in the properties object of the Azure OpenAI Service resource. Run the command below to retreive the endpoint URL.

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
  az cognitiveservices account show \
    --name "${resource_group_name}" \
    --resource-group  "${resource_group_name}" \
    | jq -r .properties.endpoint
```

<details>
  <summary><b>See solution!</b></summary>

```bash {class="bash-class" id="bash-codeblock" lineNos=inline tabWidth=2}
  az TEST cognitiveservices account show \
    --name "${resource_group_name}" \
    --resource-group  "${resource_group_name}" \
    | jq -r .properties.endpoint
```
</details>

---

[< Workshop Overview](/azure-open-ai-rag-oyd-text-images/workshop_overview/) | [Document Data Management: Overview >](/azure-open-ai-rag-oyd-text-images/document_data_management/1_overview/)

<div class="meta_for_parser tablespecs" style="visibility:hidden">In today's era of Generative AI, customers can unlock valuable insights from their unstructured or structured data to drive business value. By infusing AI into their existing or new products, customers can create powerful applications, which puts the power of AI into the hands of their users. For these Generative AI applications to work on customers data, implementing efficient RAG (Retrieval augment generation) solution is key to make sure the right context of the data is provided to the LLM based on the user query.</div>

