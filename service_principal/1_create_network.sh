#!/bin/bash

export LOCATION=swedencentral
export CLUSTER_NAME=jayaro7
export RESOURCEGROUP=rg-openshift-dev7

az group create --name $RESOURCEGROUP --location $LOCATION

az network vnet create \
 --resource-group $RESOURCEGROUP \
 --location $LOCATION \
 --name vnet-${CLUSTER_NAME} \
 --address-prefixes 10.0.0.0/22

az network vnet subnet create \
 --resource-group $RESOURCEGROUP \
 --vnet-name vnet-${CLUSTER_NAME} \
 --name snet-master \
 --address-prefixes 10.0.0.0/23

az network vnet subnet create \
 --resource-group $RESOURCEGROUP \
 --vnet-name vnet-${CLUSTER_NAME} \
 --name snet-worker \
 --address-prefixes 10.0.2.0/23

az network vnet subnet update \
  --name snet-master \
  --resource-group $RESOURCEGROUP \
  --vnet-name vnet-${CLUSTER_NAME} \
  --disable-private-link-service-network-policies true
