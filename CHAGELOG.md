# Whats New
  
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
  
