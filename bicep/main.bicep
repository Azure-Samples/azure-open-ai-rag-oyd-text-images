// ======================== Storage Account ========================
param location string = resourceGroup().location
param containerName string = 'data'

@minLength(3)
@maxLength(24)
param searchStorageAccountName string = '${uniqueString(guid(subscription().subscriptionId, resourceGroup().name))}service'

// https://stackoverflow.com/questions/77828521/using-bicep-to-create-a-storage-account-that-requires-a-private-endpoint-and-a-c
resource searchStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: searchStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2019-06-01' = {
  name: 'default'
  parent: searchStorageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: containerName
  parent: blobService
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}

// ======================== AI Search ========================
@description('Service name must only contain lowercase letters, digits or dashes, cannot use dash as the first two or last one characters, cannot contain consecutive dashes, and is limited between 2 and 60 characters in length.')
@minLength(2)
@maxLength(50)
param searchServiceName string = '${uniqueString(resourceGroup().id)}service'

@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
@description('The pricing tier of the search service you want to create (for example, basic or standard).')
param searchServiceSku string = 'basic'

@description('Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier).')
@minValue(1)
@maxValue(12)
param searchServiceReplicaCount int = 1

@description('Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param searchServicePartitionCount int = 1
param semanticSearch string = 'standard'

@description('Applicable only for SKUs set to standard3. You can set this property to enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU.')
@allowed([
  'default'
  'highDensity'
])
param searchServiceHostingMode string = 'default'

@description('This is the built-in Storage Blob Data Reader role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor')
resource blobContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
}

resource indexContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: searchStorageAccount
  name: guid(searchService.name, searchStorageAccount.name)
  properties: {
    roleDefinitionId: blobContributorRoleDefinition.id
    principalId: searchService.identity.principalId
  }
}

 // Storage Blob Data Reader
resource searchService 'Microsoft.Search/searchServices@2024-03-01-preview' = {
  name: searchServiceName
  location: location
  sku: {
    name: searchServiceSku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: searchServiceReplicaCount
    partitionCount: searchServicePartitionCount
    hostingMode: searchServiceHostingMode
    authOptions: {
      aadOrApiKey: {
          aadAuthFailureMode: 'http403'
      }
    }
    semanticSearch: semanticSearch
  }
}

// ======================== Azure Function ========================

@description('The name of the Azure Function app.')
param functionAppName string = 'func-${uniqueString(resourceGroup().id)}'

var functionStorageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: functionAppName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
  }
  properties: {
    computeMode: 'Dynamic'
    reserved: true
  }
}

resource insight 'Microsoft.Insights/components@2020-02-02' = {
  name: functionAppName
  location: location
  tags: {
    'hidden-link:${resourceId('Microsoft.Web/sites', functionAppName)}': 'Resource'
  }
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

@description('This is the built-in Storage Blob Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor')
resource funcContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource blobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: resourceGroup()
  name: guid(site.name, searchStorageAccountName)
  properties: {
    roleDefinitionId: funcContributorRoleDefinition.id
    principalId: site.identity.principalId
  }
}

param functionWorkerRuntime string = 'python'
param linuxFxVersion string = 'python|3.11'

resource site 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    reserved: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', functionAppName), '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'BLON_STORAGE_CONNECTION'
          value: 'DefaultEndpointsProtocol=https;AccountName=${searchStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${searchStorageAccount.listKeys().keys[0].value}'
        }
      ]
    }
  }
  dependsOn: [
    insight
  ]
}


// ======================== Azure Function ========================

output region string = resourceGroup().location
output resource_group string = resourceGroup().name
output search_service_name string = searchService.name
output search_service_key string = searchService.listAdminKeys().primaryKey
output subscription_id string = subscription().subscriptionId
output storage_account_name string = searchStorageAccount.name
output function_app string = functionAppName
