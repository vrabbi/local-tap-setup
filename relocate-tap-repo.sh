#!/usr/bin/env bash
NC='\033[0m'           # Text Reset
BR='\033[1;31m'         # Red
BG='\033[1;32m'       # Green
B='\033[1m'                   # Bold Regular
echo "Prereq Check:"
fail="no"
if ! command -v docker &> /dev/null
then
  echo -e "${BR}ERROR: Docker is not installed. please install docker and try again.${NC}"
  fail="yes"
else
  echo -e "${BG}Docker is installed${NC}"
fi
if ! command -v imgpkg &> /dev/null
then
  echo -e "${BR}ERROR: imgpkg is not installed. please install imgpkg and try again.${NC}"
  fail="yes"
else
  echo -e "${BG}imgpkg is installed${NC}"
fi
if [[ $fail == "yes" ]]; then
  echo -e "${BR}Prereq check failed. Please install the prerequisite tools (docker and imgpkg) and then try again${NC}"
  exit 1
fi
echo ""
echo -e "${B}TAP Package Repository Relocation Info:${NC}"
read -p 'Tanzu Network Username: ' TANZUNET_USER
read -s -p 'Tanzu Network Password: ' TANZUNET_PASSWORD
echo ""
read -p 'Destination Registry FQDN: ' INSTALL_REGISTRY_HOSTNAME
read -p 'Destination Registry Repo: ' INSTALL_REGISTRY_REPO
read -p 'Destination Registry Username: ' INSTALL_REGISTRY_USERNAME
read -s -p 'Destination Registry Password: ' INSTALL_REGISTRY_PASSWORD
echo ""
read -p 'TAP Version: ' TAP_VERSION
echo ""
echo "The final URL for the package repository will be ${INSTALL_REGISTRY_HOSTNAME}/tap/tap-packages:${TAP_VERSION}"
read -p "Continue (y/n)?" choice
case "$choice" in
  y|Y ) echo "Logging into the source and destination registries" ;;
  n|N ) exit 1 ;;
  * ) echo "invalid choice. exiting now." && exit 1;;
esac
echo ""
echo $TANZUNET_PASSWORD | docker login --username $TANZUNET_USER --password-stdin registry.tanzu.vmware.com
echo $INSTALL_REGISTRY_PASSWORD | docker login --username $INSTALL_REGISTRY_USERNAME --password-stdin $INSTALL_REGISTRY_HOSTNAME
echo ""
echo "Relocating the images now. This may take a few minutes."
imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/tap/tap-packages
