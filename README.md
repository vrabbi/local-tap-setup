# Local TAP Installation
This repo contains a script for managing a local TAP installation on a TCE Unmanaged Cluster.

# Pre-Reqs

## Instalations
In order to use this script you must have the following installed on your system:
1. Docker
2. Kubectl
3. jq
  
## Resources
You also need the following minimum resources:
* CPU: 8 cores
* RAM: 8 GB
* Free Disk Space: 20 GB
  
## Preperation
1. You must relocate the TAP Package Repository to a registry of your choosing
* You can do this following the [Official TAP Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-install.html#relocate-images-to-a-registry-0)
* The repo you relocate to should be a public repo that doesnt require authentication
  
2. Get a cup of coffee as the installation will take a few minutes  
  
## Credentials
* Username and password for tanzu network
  
# Whats Included
This script has 5 functions
1. Create a local TAP installation
2. Delete a local TAP installation
3. Check the status of the local TAP installation
4. Stop a local TAP installation
5. Start a local TAP installation you stopped previously
  
## Create function
This will do the following:
1. Create the needed config files for the TCE Unmanaged Cluster as well as for the TAP installation.
2. Deploy the Cluster
3. Deploy a local docker registry
4. Deploy the secretgen controller in the cluster
5. Install TAP with the full profile except for learning center
6. Install Kyverno
7. Create a Kyverno Cluster Policy that will prepare every new namespace automatically for TAP workloads
8. Wait for all packages to reconcile and validate the platform is installed successfully
9. Expose TAP GUI and all ingress/httpproxy objects using the suffix 127.0.0.1.nip.io alllowing local access from your browser
  
## Delete a local TAP installation
This will do the following:
1. Delete the TCE Cluster
2. Delete the local registry

## Check Status
This will do the following:
1. Check the status of the TCE cluster
2. Check the status of the local registry
3. Check the status of all the TAP Packages
  
## Stop a local TAP installation
This will do the following:
1. Stop the TCE Cluster
2. Stop the local registry container

## Start a local TAP installation
This will do the following:
1. Start the TCE Cluster
2. Start the local registry container
  
# Usage
1. Make the script executable
```bash
chmod +x local-tap.sh
```  
2. Run the script with the --help flag for the needed flags
```bash
./local-tap.sh --help
```
