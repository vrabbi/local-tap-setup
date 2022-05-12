#!/usr/bin/env bash
NC='\033[0m'           # Text Reset
BR='\033[1;31m'         # Red
BG='\033[1;32m'       # Green
B='\033[1m'                   # Bold Regular
RNC=$'\033[0m'
RB=$'\033[1m'
BU='\033[1m\e[4m'
clear
echo -e "${BU}Prereq Check:${NC}"
echo ""
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

get_password() {
  unset PWORD
  PWORD=
  echo -e -n "${B}$1${NC}" 1>&2
  while IFS= read -r -n1 -s char; do
    # Convert users key press to hexadecimal character code
    # Note a 'return' or EOL, will return a empty string
    #
    #code=$( echo -n "$char" | od -An -tx1 | tr -d ' \011' )
    code=${char:+$(printf '%02x' "'$char'")} # set to nothing for EOL

    case "$code" in
    ''|0a|0d) break ;;   # EOL, newline, return
    08|7f)  # backspace or delete
        if [ -n "$PWORD" ]; then
          PWORD="$( echo "$PWORD" | sed 's/.$//' )"
          echo -n $'\b \b' 1>&2
        fi
        ;;
    15) # ^U or kill line
        echo -n "$PWORD" | sed 's/./\cH \cH/g' >&2
        PWORD=''
        ;;
    [01]?) ;; # Ignore ALL other control characters
    *)  PWORD="$PWORD$char"
        echo -n '*' 1>&2
        ;;
    esac
  done
  echo
  echo $PWORD
}

echo ""
echo -e "${BU}TAP Package Repository Relocation Info:${NC}"
echo ""
echo -e "${BU}Tanzu Network Details${NC}"
echo ""
read -p "${RB}Tanzu Network Username: ${RNC}" TANZUNET_USER

# read -s -p 'Tanzu Network Password: ' TANZUNET_PASSWORD
TANZUNET_PASSWORD="$(get_password 'Tanzu Network Password: ')"
echo ""
TANZUNET_PASSWORD_CONFIRM="$(get_password 'Tanzu Network Password (Agian): ')"
echo ""
while [ "$TANZUNET_PASSWORD" != "$TANZUNET_PASSWORD_CONFIRM" ];
do
  echo -e "${BR}Passwords do not match. Please try again${NC}"
  TANZUNET_PASSWORD="$(get_password 'Tanzu Network Password: ')"
  echo ""
  TANZUNET_PASSWORD_CONFIRM="$(get_password 'Tanzu Network Password (Agian): ')"
  echo ""
done
echo ""
echo ""
echo -e "${BU}Destination Repository Details${NC}"
echo ""
read -p "${RB}Destination Registry FQDN: ${RNC}" INSTALL_REGISTRY_HOSTNAME
read -p "${RB}Destination Registry Repo: ${RNC}" INSTALL_REGISTRY_REPO
read -p "${RB}Destination Registry Username: ${RNC}" INSTALL_REGISTRY_USERNAME

# read -s -p 'Destination Registry Password: ' INSTALL_REGISTRY_PASSWORD
INSTALL_REGISTRY_PASSWORD="$(get_password 'Destination Registry Password: ')"
echo ""
INSTALL_REGISTRY_PASSWORD_CONFIRM="$(get_password 'Destination Registry Password (Agian): ')"
echo ""
while [ "$INSTALL_REGISTRY_PASSWORD" != "$INSTALL_REGISTRY_PASSWORD_CONFIRM" ];
do
  echo -e "${BR}Passwords do not match. Please try again${NC}"
  INSTALL_REGISTRY_PASSWORD="$(get_password 'Destination Registry Password: ')"
  echo ""
  INSTALL_REGISTRY_PASSWORD_CONFIRM="$(get_password 'Destination Registry Password (Agian): ')"
  echo ""
done

read -p "${RB}TAP Version: ${RNC}" TAP_VERSION
echo ""
echo -e "${BU}The final URL for the package repository will be:${NC} ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REGISTRY_REPO}/tap-packages:${TAP_VERSION}"
echo ""
read -p "${RB}Continue (y/n)? ${RNC}" choice
case "$choice" in
  y|Y ) echo "Logging into the source and destination registries" ;;
  n|N ) exit 1 ;;
  * ) echo "invalid choice. exiting now." && exit 1;;
esac
echo ""
echo $TANZUNET_PASSWORD | docker login --username $TANZUNET_USER --password-stdin registry.tanzu.vmware.com
echo $INSTALL_REGISTRY_PASSWORD | docker login --username $INSTALL_REGISTRY_USERNAME --password-stdin $INSTALL_REGISTRY_HOSTNAME
echo ""
echo -e "${B}Relocating the images now. This may take a few minutes.${NC}"
imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} --to-repo ${INSTALL_REGISTRY_HOSTNAME}/${INSTALL_REGISTRY_REPO}/tap-packages
