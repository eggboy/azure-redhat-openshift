# Azure Red Hat OpenShift (ARO) with Managed Identities

This script automates the deployment of Azure Red Hat OpenShift clusters using managed identities instead of service principals.

## Prerequisites

- Azure CLI version 2.67.0 or higher
- `jq` command-line JSON processor
- An active Azure subscription with appropriate permissions
- (Optional) Pull secret from Red Hat (for enhanced cluster features)

## Quick Start

```bash
# Check dependencies
./deploy-aro-managed-identity.sh -x check-deps

# Install ARO cluster with default settings (public cluster)
./deploy-aro-managed-identity.sh -x install

# Show cluster information and credentials
./deploy-aro-managed-identity.sh -x show

# Destroy the cluster and all resources
./deploy-aro-managed-identity.sh -x destroy
```

## Command-Line Options

### Main Options

- `-x <action>` - Action to execute (required)
  - `install` - Creates ARO cluster with managed identities
  - `destroy` - Deletes ARO cluster and associated resources
  - `show` - Shows cluster information and credentials
  - `check-deps` - Checks if required dependencies are installed
  - `download-ext` - Downloads and installs ARO preview extension
  - `prepare-mi` - Creates managed identities and assigns roles

### Additional Options

- `-y` - Auto-approve mode (skip confirmation prompts for destructive operations)
- `-A <visibility>` - API server visibility: `Public` or `Private` (default: `Public`)
- `-I <visibility>` - Ingress visibility: `Public` or `Private` (default: `Public`)

## Configuration

The script can be configured using environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `LOCATION` | `malaysiawest` | Azure region for deployment |
| `RESOURCEGROUP` | `rg-aro` | Resource group name |
| `CLUSTER` | `sandbox-aro` | ARO cluster name |
| `CLUSTER_VERSION` | `4.19.20` | ARO version (can select during install) |
| `PULL_SECRET_FILE` | `pull-secret.txt` | Path to Red Hat pull secret file |

Example:
```bash
LOCATION=eastus RESOURCEGROUP=my-aro-rg CLUSTER=prod-aro ./deploy-aro-managed-identity.sh -x install
```

## Usage Examples

### Public Cluster (Default)

Deploy a standard ARO cluster with public API server and ingress:

```bash
./deploy-aro-managed-identity.sh -x install
```

### Fully Private Cluster

Deploy a private ARO cluster with private API server and private ingress:

```bash
./deploy-aro-managed-identity.sh -x install -A Private -I Private
```

This configuration is ideal for:
- Production environments requiring enhanced security
- Compliance requirements (PCI-DSS, HIPAA, etc.)
- Workloads that should not be exposed to the public internet

### Hybrid Configuration

Deploy with private API server but public ingress:

```bash
./deploy-aro-managed-identity.sh -x install -A Private -I Public
```

This allows:
- Cluster management from private networks only
- Applications accessible from the public internet

### Non-Interactive Destruction

Delete all resources without confirmation prompts (useful for automation):

```bash
./deploy-aro-managed-identity.sh -x destroy -y
```

### Custom Region and Resource Group

```bash
LOCATION=westus2 RESOURCEGROUP=aro-prod-rg CLUSTER=production-cluster \
  ./deploy-aro-managed-identity.sh -x install -A Private -I Private
```

## What Gets Created

The script creates the following Azure resources:

### Networking
- Virtual Network (`aro-vnet`) with address space 10.0.0.0/22
- Master subnet (10.0.0.0/23) for control plane nodes
- Worker subnet (10.0.2.0/23) for worker nodes

### Managed Identities
- `aro-cluster` - Main cluster identity
- `cloud-controller-manager` - Manages cloud resources
- `ingress` - Manages ingress controllers
- `machine-api` - Manages machine sets
- `disk-csi-driver` - Manages persistent disk volumes
- `cloud-network-config` - Manages network configuration
- `image-registry` - Manages internal image registry
- `file-csi-driver` - Manages file share volumes
- `aro-operator` - ARO-specific operations

### ARO Cluster
- OpenShift control plane (3 master nodes, Standard_D8as_v5)
- Worker nodes (compute nodes, Standard_D8as_v5)
- Integrated monitoring and logging
- Private or public endpoints (based on configuration)

## Private Cluster Considerations

When deploying a private ARO cluster (`-A Private`):

### Access Requirements
- You'll need a VPN, ExpressRoute, or Azure Bastion to access the cluster
- The API server will only be accessible from within the virtual network or peered networks
- Use Azure Bastion or a jump box to access the cluster initially

### Post-Deployment Setup
After creating a private cluster, you'll need network connectivity:

```bash
# Option 1: Create a jumpbox VM in the same VNet
az vm create \
  --resource-group rg-aro \
  --name aro-jumpbox \
  --image Ubuntu2204 \
  --vnet-name aro-vnet \
  --subnet master \
  --admin-username azureuser \
  --generate-ssh-keys

# Option 2: Set up VNet peering to your hub network
az network vnet peering create \
  --name aro-to-hub \
  --resource-group rg-aro \
  --vnet-name aro-vnet \
  --remote-vnet /subscriptions/<subscription-id>/resourceGroups/<hub-rg>/providers/Microsoft.Network/virtualNetworks/<hub-vnet> \
  --allow-vnet-access
```

### Accessing Private Clusters

Once you have network connectivity:

```bash
# Get cluster credentials
./deploy-aro-managed-identity.sh -x show

# Login to OpenShift
oc login <api-server-url> -u kubeadmin -p <password>
```

## Version Selection

During installation, the script will:
1. Fetch available ARO versions for your region
2. Display them in a numbered list
3. Prompt you to select a version (or press Enter to use default)

```
Available ARO versions for malaysiawest:
     1  4.19.20
     2  4.18.15
     3  4.17.30
Current default: 4.19.20
Enter the number of the version to use (or press Enter to keep default):
```

## Troubleshooting

### Insufficient Quota

If you see quota errors:
```
Insufficient quota: Need 44 cores, available: 24
```

Request a quota increase for "Standard DSv5 Family vCPUs" in your region via Azure Portal.

### Extension Issues

If you encounter extension-related errors:
```bash
# Download and install the latest ARO extension
./deploy-aro-managed-identity.sh -x download-ext
```

### Role Assignment Propagation

The script includes 30-second delays for identity propagation, but if you encounter permission errors, role assignments may need more time to propagate (up to 5 minutes in some cases).

### Checking Cluster Status

```bash
# Show cluster information
./deploy-aro-managed-identity.sh -x show

# Check in Azure Portal
az aro show --name sandbox-aro --resource-group rg-aro

# Watch cluster provisioning
az aro show --name sandbox-aro --resource-group rg-aro --query provisioningState
```

## Clean Up

To remove all resources:

```bash
# With confirmation prompts
./deploy-aro-managed-identity.sh -x destroy

# Without confirmation (automated)
./deploy-aro-managed-identity.sh -x destroy -y
```

This will delete:
- ARO cluster
- All managed identities
- The entire resource group including networking resources

## Security Best Practices

1. **Use Private Clusters for Production**: Deploy with `-A Private -I Private`
2. **Rotate Credentials**: Regularly rotate the kubeadmin password
3. **Enable Azure AD Integration**: Configure Azure AD authentication after deployment
4. **Network Segmentation**: Use Network Security Groups (NSGs) for additional security
5. **Pull Secrets**: Always use a pull secret for production deployments

## Getting Pull Secret

1. Visit [Red Hat Hybrid Cloud Console](https://console.redhat.com/openshift/install/azure/aro-provisioned)
2. Login with your Red Hat account
3. Download the pull secret
4. Save it as `pull-secret.txt` in the same directory as the script

## Additional Resources

- [Azure Red Hat OpenShift Documentation](https://docs.microsoft.com/azure/openshift/)
- [OpenShift Documentation](https://docs.openshift.com/)
- [ARO Private Cluster Documentation](https://docs.microsoft.com/azure/openshift/howto-create-private-cluster)

## Support

For issues related to:
- **This script**: Open an issue in the repository
- **ARO service**: Contact Microsoft Azure Support
- **OpenShift**: Refer to Red Hat OpenShift documentation
