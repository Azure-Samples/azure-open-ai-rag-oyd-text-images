---
title: Use Case Overview
---


**Create and deploy an Azure OpenAI Service resource**

This article describes how to get started with Azure OpenAI Service and provides step-by-step instructions to create a resource and deploy a model. You can create resources in Azure in several different ways:

The Azure portal
The REST APIs, the Azure CLI, PowerShell, or client libraries
Azure Resource Manager (ARM) templates
In this article, you review examples for creating and deploying resources in the Azure portal and with the Azure CLI.

### Prerequisites
An Azure subscription. Create one for free.
Access permissions to create Azure OpenAI resources and to deploy models.
Create a resource
The following steps show how to create an Azure OpenAI resource in the Azure portal.

Identify the resource
Sign in with your Azure subscription in the Azure portal.

Select Create a resource and search for the Azure OpenAI. When you locate the service, select Create.

Screenshot that shows how to create a new Azure OpenAI Service resource in the Azure portal.

On the Create Azure OpenAI page, provide the following information for the fields on the Basics tab:

Field	Description
Subscription	The Azure subscription used in your Azure OpenAI Service onboarding application.
Resource group	The Azure resource group to contain your Azure OpenAI resource. You can create a new group or use a pre-existing group.
Region	The location of your instance. Different locations can introduce latency, but they don't affect the runtime availability of your resource.
Name	A descriptive name for your Azure OpenAI Service resource, such as MyOpenAIResource.
Pricing Tier	The pricing tier for the resource. Currently, only the Standard tier is available for the Azure OpenAI Service. For more info on pricing visit the Azure OpenAI pricing page

---

<img src="/images/ArchOverviewOYD-v2.png" alt="ArchOverviewOYD-v2" width="640" height="auto">
<!-- ![alt](/images/ArchOverviewOYD-v2.png) -->

<hr />

Building your own digital garden is not a fad. It's a necessity. Tools like Roam Research, Obsidian and Notion provided means to interlink content, even over a graphical way. Still not sold? Check out [The Digital Garden](https://dev.to/jbranchaud/the-digital-garden-l10) by Josh Branchaud.

Start collecting your ideas 💡, curate thought provoking & interesting content 💬&nbsp; and learn.

→ [Go to Documentations](/aoai)