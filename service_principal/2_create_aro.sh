export LOCATION=southeastasia
export CLUSTER_NAME=jayaro7
export RESOURCEGROUP=rg-openshift-dev7
export VNET_ID="/subscriptions/${SUBSCRIPTION}/resourceGroups/${RESOURCEGROUP}/providers/Microsoft.Network/virtualNetworks/vnet-jayaro"

az aro create \
  --resource-group ${RESOURCEGROUP} \
  --location ${LOCATION} \
  --name ${CLUSTER_NAME} \
  --vnet vnet-jayaro7 \
  --master-subnet snet-master \
  --worker-subnet snet-worker \
  --master-vm-size Standard_D8as_v5 \
  --worker-vm-size Standard_D8as_v5 \
  --version 4.17.27
