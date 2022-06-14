# Whats New

## June 14th 2022
* Added support for setting the cluster name vi a new flag --cluster-name. Still defaults to tce-tap but this allows for changing the name if needed. currently you can still only run 1 instance at a time on a machine.
* Added support for installing from a local registry using a new flag --install-from-local-registry
* Added the logic from the relocate images script to a new action in the main script called relocate-images. The relocate script will be removed in the near future from the repo.
* Added logic to the relocate functionality to support pushing images to a local registry via the new --target flag.
* Added printing of all images in the local registry including tags to the status action
* Added an option to keep the local docker registry when deleting the environment via a new flag --keep-local-registry
  
## June 13th 2022
* Added support for exposing the cluster outside of your local machine using the Machines IP address as the Control Plane Endpoint by setting the flag --insecure-expose-kube-api to yes, and providing your machines IP address via the flag --ip-address
  
## June 9th 2022
* Added support for exposing all TAP Endpints (TAP-GUI and Deployed Apps) outside of the local machine by setting the flag --enable-remote-access to yes and providing your machines IP address via the flag --ip-address
* Added the Local TAP Setup Github Repo, and vRabbi Blog under the support section in TAP GUI
* Added some simple Branding on the TAP GUI
* Include instructions for deploying a sample app after the deployment succeeded
* Included details for connecting and using the local container registry

  
## June 7th 2022
* Added Experimental Self Signed Certificate Registry Support via the --ca-file-path flag
* Configured Techdocs to use ghcr.io/vrabbi/techdocs:v1.0.3 by default as the builder image to prevent dockerhub rate limiting
* Added a flag --techdocs-container-image to specify your own image for the techdocs rendering
* Added a flag to choose the DinD image to be used for techdocs rendering via the flag --techdocs-dind-image
* At the end of the creation task all config files generated in the script are saved in a new directory tce-tap-files for reference
  
## June 2nd 2022
* Added ability to enable Techdocs auto rendering via a docker daemon sidecar container
* Cleaned up output to make it more readable
  
## June 1st 2022
* Added ability to choose which OOTB Supply chain to install (basic, testing, testing_Scanning) via the --supply-chain flag
* Prepare the default namespace for workload creation
  
