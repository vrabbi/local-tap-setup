# Local TAP Installation
This repo contains a script for managing a local TAP installation on a TCE Unmanaged Cluster.  
This script can manage TAP 1.1.0 and above.
  
# Pre-Reqs

## Instalations
In order to use this script you must have the following installed on your system:
1. Docker - must be installed in advance
2. Kubectl - can be installed using the script
4. TCE v0.12.0 - can be installed using the script
  
## Resources
You also need the following minimum resources:
* CPU: 8 cores
* RAM: 8 GB
* Free Disk Space: 20 GB
  
## Preperation
1. You must relocate the TAP Package Repository to a registry of your choosing
* You can do this following the [Official TAP Documentation](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-install.html#relocate-images-to-a-registry-0)
* You can use the relocate-tap-repo.sh script in this repo to do this as well
* The repo you relocate to should be a public repo that doesnt require authentication
  
2. Get a cup of coffee as the installation will take a few minutes  
  
## Credentials
* Username and password for tanzu network
  
# Whats Included
This script has 5 functions
1. Install prereqs if they are missing or outdated
1. Create a local TAP installation
2. Delete a local TAP installation
3. Check the status of the local TAP installation
4. Stop a local TAP installation
5. Start a local TAP installation you stopped previously
  
## Prepare function
This will do the following:
1. Check if Tanzu CLI is installed
2. Validate Tanzu CLI is of the correct version
3. Upgrade or install Tanzu CLI if needed
4. Check that Kubectl is installed
5. Install Kubectl if needed
  
## Create function
This will do the following:
1. Create the needed config files for the TCE Unmanaged Cluster as well as for the TAP installation.
2. Deploy the Cluster
3. Deploy a local docker registry
4. Deploy the secretgen controller in the cluster
5. Install TAP with the full profile except for learning center or with the iterate profile
6. Install any of the 3 OOTB Supply chains
7. Install Kyverno
8. Create a Kyverno Cluster Policy that will prepare every new namespace automatically for TAP workloads
9. Wait for all packages to reconcile and validate the platform is installed successfully
10. Prepare the default namespace for workload creation including scanning CRDs and an example tekton pipeline.
11. Expose TAP GUI and all ingress/httpproxy objects using the suffix 127.0.0.1.nip.io alllowing local access from your browser
  
## Delete function
This will do the following:
1. Delete the TCE Cluster
2. Delete the local registry

## Status function
This will do the following:
1. Check the status of the TCE cluster
2. Check the status of the local registry
3. Check the status of all the TAP Packages
  
## Stop function
This will do the following:
1. Stop the TCE Cluster
2. Stop the local registry container

## Start function
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

# Example Commands
```bash
# Prepare your machine
./local-tap.sh --action prepare

# Create a cluster with the default settings
./local-tap-sh --action create --tanzunet-user $TANZUNET_USER --tanzunet-password $TANZUNET_PASSWORD --tap-package-repo-url $TAP_REPO

# Create a cluster with the iterate profile - Saves resources but no UI or security tooling
./local-tap-sh --action create --tanzunet-user $TANZUNET_USER --tanzunet-password $TANZUNET_PASSWORD --tap-package-repo-url $TAP_REPO --tap-profile iterate

# Create a cluster with the testing and scanning supply chain
./local-tap-sh --action create --tanzunet-user $TANZUNET_USER --tanzunet-password $TANZUNET_PASSWORD --tap-package-repo-url $TAP_REPO --supply-chain testing_scanning  

# Create a cluster with a specific TAP version
./local-tap-sh --action create --tanzunet-user $TANZUNET_USER --tanzunet-password $TANZUNET_PASSWORD --tap-package-repo-url $TAP_REPO --tap-version $TAP_VERSION

# Get the status of your environment
./local-tap.sh --action status

# Shutdown your environment
./local-tap.sh --action stop

# Start up your environment
./local-tap.sh --action start

# Delete your environment
./local-tap.sh --action delete
```
