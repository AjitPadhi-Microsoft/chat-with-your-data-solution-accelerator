metadata name = 'workbook'
metadata description = 'AVM WAF-compliant Workbook deployment using Microsoft.Insights resource type. Ensures governance, observability, tagging, and consistency with other monitoring resources.'

// ========== //
// Parameters //
// ========== //

@description('Required. The friendly display name for the workbook. Must be unique within the resource group.')
param workbookDisplayName string

@description('Optional. The gallery category under which the workbook will appear. Supported values: workbook, tsg, etc.')
param workbookType string = 'workbook'

@description('Optional. Resource ID of the source this workbook is associated with. Example: Log Analytics workspace or App Insights instance.')
param workbookSourceId string = 'azure monitor'

@description('Required. Unique GUID for this workbook instance. Acts as the resource name.')
param workbookId string

@description('Optional. Azure region where the workbook is deployed. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Optional. Tags to apply to the workbook resource for governance, cost tracking, and compliance.')
param tags object = {}

@description('Required. Name of the App Service Plan hosting the workloads.')
param hostingPlanName string

@description('Required. Name of the Function App (backend) resource.')
param functionName string

@description('Required. Name of the frontend web App Service.')
param websiteName string

@description('Required. Name of the admin web App Service.')
param adminWebsiteName string

@description('Required. Name of the Event Grid System Topic resource.')
param eventGridSystemTopicName string

@description('Required. Resource ID of the Log Analytics workspace for query references.')
param logAnalyticsResourceId string

@description('Required. Name of the Azure OpenAI resource.')
param azureOpenAIResourceName string

@description('Required. Name of the Azure AI Search resource. Empty string if not using CosmosDB.')
param azureAISearchName string

@description('Required. Name of the Storage Account resource.')
param storageAccountName string

// ======== //
// Resource //
// ======== //

var wookbookContents = loadTextContent('../../../workbooks/workbook.json')
var wookbookContentsSubReplaced = replace(wookbookContents, '{subscription-id}', subscription().id)
var wookbookContentsRGReplaced = replace(wookbookContentsSubReplaced, '{resource-group}', resourceGroup().name)
var wookbookContentsAppServicePlanReplaced = replace(wookbookContentsRGReplaced, '{app-service-plan}', hostingPlanName)
var wookbookContentsBackendAppServiceReplaced = replace(
  wookbookContentsAppServicePlanReplaced,
  '{backend-app-service}',
  functionName
)
var wookbookContentsWebAppServiceReplaced = replace(
  wookbookContentsBackendAppServiceReplaced,
  '{web-app-service}',
  websiteName
)
var wookbookContentsAdminAppServiceReplaced = replace(
  wookbookContentsWebAppServiceReplaced,
  '{admin-app-service}',
  adminWebsiteName
)
var wookbookContentsEventGridReplaced = replace(
  wookbookContentsAdminAppServiceReplaced,
  '{event-grid}',
  eventGridSystemTopicName
)
var wookbookContentsLogAnalyticsReplaced = replace(
  wookbookContentsEventGridReplaced,
  '{log-analytics-resource-id}',
  logAnalyticsResourceId
)
var wookbookContentsOpenAIReplaced = replace(wookbookContentsLogAnalyticsReplaced, '{open-ai}', azureOpenAIResourceName)
var wookbookContentsAISearchReplaced = replace(wookbookContentsOpenAIReplaced, '{ai-search}', azureAISearchName)
var workbookContents = replace(
  wookbookContentsAISearchReplaced,
  '{storage-account}',
  storageAccountName
)

resource workbook_resource 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookId
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: workbookDisplayName
    serializedData: workbookContents
    version: '1.0'
    sourceId: workbookSourceId
    category: workbookType
  }
}

// ======= //
// Outputs //
// ======= //

@description('The full resource ID of the deployed workbook.')
output workbookResourceId string = workbook_resource.id
