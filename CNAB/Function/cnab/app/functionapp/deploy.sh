#!/bin/bash

# Required to run: 
#   - az cli
#   - func cli (Azure Functions Core Tools)
#   - $APPNAME
#   - Azure service principal creds: $APPID, $PASSWORD, $TEANANT_ID

# Function app and storage account names must be unique.
functionAppName=$APPNAME
storageName=storage$APPNAME
resourceGroupName=resourcegroup$APPNAME
location=eastus

# Login to Azure
az login --service-principal --username "$APP_ID" --password "$PASSWORD" --tenant "$TENANT_ID" 

# Create a resource group.
az group create --name $resourceGroupName --location $location

# Create an Azure storage account in the resource group.
az storage account create \
  --name $storageName \
  --location $location \
  --resource-group $resourceGroupName \
  --sku Standard_LRS

# Create an Azure Cosmos DB database using the same function app name.
az cosmosdb create \
  --name $functionAppName \
  --resource-group $resourceGroupName \

# Get the Azure Cosmos DB connection string.
endpoint=$(az cosmosdb show \
  --name $functionAppName \
  --resource-group $resourceGroupName \
  --query documentEndpoint \
  --output tsv)

key=$(az cosmosdb list-keys \
  --name $functionAppName \
  --resource-group $resourceGroupName \
  --query primaryMasterKey \
  --output tsv)

az cosmosdb database create \
  --db-name test \
  --name $functionAppName \
  --key $key \
  --url-connection $endpoint

az cosmosdb collection create \
  --collection-name Items \
  --db-name test \
  --name $functionAppName \
  --key $key \
  --url-connection $endpoint

# Create a serverless function app in the resource group.
az functionapp create \
    --resource-group $resourceGroupName \
    --consumption-plan-location $location \
    --os-type Linux \
    --name $functionAppName \
    --storage-account  $storageName \
    --runtime python


connectionstring=AccountEndpoint="$endpoint"";AccountKey=""$key"";"

# Configure function app settings to use the Azure Cosmos DB connection string.
az functionapp config appsettings set \
  --name $functionAppName \
  --resource-group $resourceGroupName \
  --setting CosmosConnectionString=$connectionstring

# Deploy the function app project
func azure functionapp publish $functionAppName