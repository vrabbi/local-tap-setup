#!/usr/bin/env bash
if [[ $# == 0 ]]; then
  echo "No Flags were passed. Run with --help flag to get usage information"
  exit 1
fi
while test $# -gt 0; do
  case "$1" in
    --action)
      shift
      action=$1
      shift
      ;;
    --tanzunet-user)
      shift
      tanzunet_user=$1
      shift
      ;;
    --tanzunet-password)
      shift
      tanzunet_password=$1
      shift
      ;;
    --tbs-descriptor)
      shift
      tbs_descriptor=$1
      shift
      ;;
    --tce-package-repo-url)
      shift
      tce_package_repo_url=$1
      shift
      ;;
    --tap-package-repo-url)
      shift
      tap_package_repo_url=$1
      shift
      ;;
    --kyverno-package-repo-url)
      shift
      kyverno_package_repo_url=$1
      shift
      ;;
    --dockerhub-registry-mirror)
      shift
      dockerhub_registry_mirror=$1
      shift
      ;;
    --tap-gui-catalog-url)
      shift
      tap_gui_catalog_url=$1
      shift
      ;;
    --tap-version)
      shift
      tap_version=$1
      shift
      ;;
    --tap-profile)
      shift
      tap_profile=$1
      shift
      ;;
    --supply-chain)
      shift
      supply_chain=$1
      shift
      ;;
    --enable-techdocs)
      shift
      enable_techdocs=$1
      shift
      ;;
    --techdocs-container-image)
      shift
      techdocs_container_image=$1
      shift
      ;;
    --techdocs-dind-image)
      shift
      techdocs_dind_image=$1
      shift
      ;;
    --ca-file-path)
      shift
      ca_file_path=$1
      shift
      ;;
    --enable-remote-access)
      shift
      enable_remote_access=$1
      shift
      ;;
    --ip-address)
      shift
      ip_address=$1
      shift
      ;;
    --insecure-expose-kube-api)
      shift
      insecure_expose_kube_api=$1
      shift
      ;;
    --install-from-local-registry)
      shift
      install_from_local_registry=$1
      shift
      ;;
    --target)
      shift
      target=$1
      shift
      ;;
    --keep-local-registry)
      shift
      keep_local_registry=$1
      shift
      ;;
    --cluster-name)
      shift
      cluster_name=$1
      shift
      ;;
    --help)
      cat << EOF
Usage: local-tap.sh [OPTIONS]
Options:

[Global Manadatory Flags]
  --action : What action to take - create,stop,start,status,delete,prepare,relocate-images

[Global Optional Flags]
  --help : show this help menu
  --cluster-name : This allows you to set the cluster name to work against. (Default: tce-tap)

[Mandatory Flags - For Create Action]
  --tanzunet-user : User for Tanzu Network
  --tanzunet-password : Password for Tanzu Network
  --tap-package-repo-url : URL For Relocated TAP Package Repository

[Mandatory Flags - For Relocate Images Action]
  --tanzunet-user : User for Tanzu Network
  --tanzunet-password : Password for Tanzu Network

[Optional Flags - For Create Action]
  --tap-profile : TAP Installation Profile. (Default full)
  --supply-chain : The supply chain to install (Default basic) Options: basic, testing, testing_scanning
  --tap-version : Version of TAP. - (Default 1.1.1)
  --tbs-descriptor
  --tce-package-repo-url : URL For Tanzu Community Edition Package Repository. - (Default: projects.registry.vmware.com/tce/main:0.12.0)
  --kyverno-package-repo-url : URL For Kyverno Package Repository. - (Default: ghcr.io/vrabbi/kyverno-tap-repo.terasky.oss:0.1.5)
  --dockerhub-registry-mirror : URL for Dockerhub Registry Mirror to be configured in containerd on the cluster. - (Default: null)
  --tap-gui-catalog-url : Github URL for the TAP GUI Catalog. - (Default: https://github.com/vrabbi/tap-gui-beta-3/blob/master/yelb-catalog/catalog-info.yaml)
  --enable-techdocs : (yes or no) Adds a patch to the TAP GUI deployment to allow for auto rendering of TechDocs using a containerized Docker Socket (Default: no)
  --techdocs-container-image : Image URI for Techdocs rendering (Default: ghcr.io/vrabbi/techdocs:v1.0.3)
  --techdocs-dind-image : Image URI for DinD rootless image (Default: docker:dind-rootless
  --ca-file-path : The Full path to the file containing your CA data in PEM format you want to platform to trust
  --enable-remote-access : (yes or no) This flag allows you to set whether remote access from other machines should be allowed to TAP GUI and other exposed endpoints (Default: no)
  --ip-address : Required if enabling remote access. This flags value needs to be the IP of your node (eg. 192.168.1.231)
  --insecure-expose-kube-api : (yes or no) This flag allows you to set whether the Kubernetes Cluster will be configured to allow access from outside your machine. (Default: no)
  --install-from-local-registry : (yes or no) If you relocated the TAP images to a local docker registry on your machine set to yes (Default: no)

[Optional Flags - For Relocate Images Action]
  --target : (local or remote) set to local if pushing to a local docker registry otherwise set to remote (Default: remote)

[Optional Flags - For Delete Action]
  --keep-local-registry (yes or no) If set to yes, the local registry will not be deleted. (Default: no)

EOF
      exit 1
      ;;
    *)
      echo "$1 is not a recognized flag!"
      exit 1
      ;;
  esac
done
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine_os=Linux;;
    Darwin*)    machine_os=Mac;;
    *)          machine_os="UNKNOWN:${unameOut}"
esac
if [[ $machine_os != "Mac" && $machine_os != "Linux" ]]; then
  echo "Only Mac and Linux are currently supported. your machine returned the type of $machine_os"
  exit 1
fi

# Validate an action was selected
if ! [[ $action ]]; then
  echo "You must specify the action the script should perform via the --action flag"
  exit 1
fi
if ! [[ $tap_version ]]; then
  tap_version="1.1.1"
fi

NC='\033[0m'           # Text Reset
BR='\033[1;31m'         # Red
BG='\033[1;32m'       # Green
BY='\033[1;33m'      # Yellow
B='\033[1m'                   # Bold Regular
RNC=$'\033[0m'
RB=$'\033[1m'
BU='\033[1m\e[4m'

print_package_status () {
  pkg_status=`kubectl --context kind-tce-tap get pkgi -n $2 $3 -o custom-columns=STATUS:.status.friendlyDescription --no-headers`
  if [[ $pkg_status == "Reconcile succeeded" ]]; then
    echo -e "    ${B}$1: ${BG}$pkg_status${NC}"
  elif [[ $pkg_status == "Reconciling" ]]; then
    echo -e "    ${B}$1: ${BY}$pkg_status${NC}"
  elif [[ $pkg_status == "Reconcile failed: Error (see .status.usefulErrorMessage for details)" ]]; then
    echo -e "    ${B}$1: ${BR}$pkg_status${NC}"
  else
    echo -e "    ${B}$1: ${B}$pkg_status${NC}"
  fi
}
start=`date +%s`
if ! [[ $cluster_name ]]; then
  cluster_name="tce-tap"
fi
if [[ $action == "relocate-images" ]]; then
  clear
  echo -e "${BU}Prereq Check:${NC}"
  echo ""
  fail="no"
  if ! [[ $target ]]; then
    target="remote"
  fi
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
  if [[ $target == "local" ]]; then
    echo "${RB}Deploying a local registry to hold TAP images${RNC}"
    docker run -d --restart=always -p "5000:5000" --name "registry.local" registry:2
    INSTALL_REGISTRY_REPO="tap"
    INSTALL_REGISTRY_HOSTNAME="localhost:5000"
    INSTALL_REGISTRY_PASSWORD="password"
    INSTALL_REGISTRY_USERNAME="user"
  else
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
  fi
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
elif [[ $action == "prepare" ]]; then
  echo "Installing Prereqs if not present or of the wrong version"

  if [[ $machine_os != "Mac" && $machine_os != "Linux" ]]; then
    echo "Only Mac and Linux are currently supported. your machine returned the type of $machine_os"
    exit 1
  fi
  echo "Checking if Tanzu CLI is installed"
  if ! command -v tanzu &> /dev/null
  then
    echo -e "${B}Tanzu CLI is not installed. installing now${NC}"
    if [[ $machine_os == "Linux" ]]; then
      curl -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/vmware-tanzu/community-edition/contents/hack/get-tce-release.sh | bash -s v0.12.0 linux
      tar -zxvf tce-linux-amd64-v0.12.0.tar.gz
      cd tce-linux-amd64-v0.12.0
      ./install.sh
    elif [[ $machine_os == "Mac" ]]; then
      curl -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/vmware-tanzu/community-edition/contents/hack/get-tce-release.sh | bash -s v0.12.0 darwin
      tar -zxvf tce-darwin-amd64-v0.12.0.tar.gz
      cd tce-darwin-amd64-v0.12.0
      ./install.sh
    fi
  else
    echo -e "${BG}Tanzu CLI is already installed${NC}"
    echo "Checking if Tanzu CLI is up to date"
    if [[ `tanzu version` != *2022-05-04* ]]; then
      echo -e "${B}Tanzu CLI is not up to date. Updating now.${NC}"
      if [[ $machine_os == "Linux" ]]; then
        curl -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/vmware-tanzu/community-edition/contents/hack/get-tce-release.sh | bash -s v0.12.0 linux
        tar -zxvf tce-linux-amd64-v0.12.0.tar.gz
        cd tce-linux-amd64-v0.12.0
        ./install.sh
      elif [[ $machine_os == "Mac" ]]; then
        curl -H "Accept: application/vnd.github.v3.raw" -L https://api.github.com/repos/vmware-tanzu/community-edition/contents/hack/get-tce-release.sh | bash -s v0.12.0 darwin
        tar -zxvf tce-darwin-amd64-v0.12.0.tar.gz
        cd tce-darwin-amd64-v0.12.0
        ./install.sh
      fi
      echo -e "${BG}Tanzu CLI has been updated${NC}"
    else
      echo -e "${BG}Tanzu CLI is installed already with the right version${NC}"
    fi

  fi
  echo "Checking if Kubectl is installed"
  if ! command -v kubectl &> /dev/null
  then
    echo -e "${B}kubectl is not installed. installing now.${NC}"
    if [[ $machine_os == "Linux" ]]; then
      curl -LO https://dl.k8s.io/release/v1.21.12/bin/linux/amd64/kubectl
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    elif [[ $machine_os == "Mac" ]]; then
      curl -LO https://dl.k8s.io/release/v1.21.12/bin/darwin/amd64/kubectl
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
      sudo chown root: /usr/local/bin/kubectl
    fi
    echo -e "${BG}Kubectl is now installed${NC}"
  else
    echo -e "${BG}Kubectl is already installed${NC}"
  fi
  echo "Checking if Docker is installed"
  if ! command -v docker &> /dev/null
  then
    echo -e "${BR}ERROR: Docker is not installed. please install docker or docker desktop and then try again.${NC}"
    exit 1
  else
    echo -e "${BG}Docker is already installed${NC}"
  fi

elif [[ $action == "status" ]]; then
  cls_status=`tanzu uc list -o json | jq -r '.[] | select(.name=="'$cluster_name'") | .status'`
  if [[ $cls_status == "Running" ]]; then
    echo -e "${B}Cluster Status: ${BG}$cls_status${NC}"
  elif [[ $cls_status == "Stopped" ]]; then
    echo -e "${B}Cluster Status: ${BY}$cls_status${NC}"
  else
    echo -e "${B}Cluster Status: ${BR}$cls_status${NC}"
  fi
  reg_status=`docker container inspect -f '{{.State.Status}}' registry.local`
  if [[ $reg_status == "running" ]]; then
    echo -e "${B}Local Registry Status: ${BG}Running${NC}"
  elif [[ $reg_status == "exited" ]]; then
    echo -e "${B}Local Registry Status: ${BY}Stopped${NC}"
  else
    echo -e "${B}Local Registry Status: ${BR}$reg_status${NC}"
  fi
  if [[ `tanzu uc list -o json | jq -r '.[] | select(.name=="'$cluster_name'") | .status'` == "Running" ]]; then
    echo -e "${B}Package Statuses:${NC}"
    tap_profile=`kubectl get secret -n tkg-system tap-config -o json | jq '.data["values.yml"]' -r | base64 -d | head -n 1 | cut -d ":" -f2`
    supply_chain_suffix=`kubectl get secret -n tkg-system tap-config -o json | jq -r '.data."values.yml"' | base64 -d | grep "supply_chain: " | sed 's/^supply_chain: //' | sed 's/_/-/g'`
    supply_chain="ootb-supply-chain-$supply_chain_suffix"
    print_package_status "TAP Meta Package" tkg-system tap
    print_package_status "Secretgen Controller" tkg-system secretgen-controller
    print_package_status "kyverno" tkg-system kyverno
    print_package_status "App Liveview" tap-install appliveview
    print_package_status "App Liveview Connector" tap-install appliveview-connector
    print_package_status "App Liveview Conventions" tap-install appliveview-conventions
    print_package_status "Build Service" tap-install buildservice
    print_package_status "Cartographer" tap-install cartographer
    print_package_status "Cert Manager" tap-install cert-manager
    print_package_status "Cloud Native Runtimes" tap-install cnrs
    print_package_status "Contour" tap-install contour
    print_package_status "Conventions Controller" tap-install conventions-controller
    print_package_status "Developer Conventions" tap-install developer-conventions
    print_package_status "FluxCD Source Controller" tap-install fluxcd-source-controller
    print_package_status "Image Policy Webhook" tap-install image-policy-webhook
    print_package_status "OOTB Delivery" tap-install ootb-delivery-basic
    print_package_status "OOTB Supply Chain" tap-install $supply_chain
    print_package_status "OOTB Templates" tap-install ootb-templates
    print_package_status "Service Bindings" tap-install service-bindings
    print_package_status "Services Toolkit" tap-install services-toolkit
    print_package_status "Source Controller" tap-install source-controller
    print_package_status "Spring Boot Conventions" tap-install spring-boot-conventions
    print_package_status "TAP Auth" tap-install tap-auth
    print_package_status "TAP Telemetry" tap-install tap-telemetry
    print_package_status "Tekton Pipelines" tap-install tekton-pipelines
    if [[ $tap_profile == " full" ]]; then
      print_package_status "Metadata Store" tap-install metadata-store
      print_package_status "Accelerator" tap-install accelerator
      print_package_status "API Portal" tap-install api-portal
      print_package_status "Grype" tap-install grype
      print_package_status "Scanning" tap-install scanning
      print_package_status "TAP GUI" tap-install tap-gui
    fi
  fi
  echo -e "${B}Images in the Local Registry${NC}"
  curl -s http://localhost:5000/v2/_catalog | jq -r .repositories[] |  while read repo ; do echo -e "    ${RB}$repo:${NC}" && imgpkg tag ls -i localhost:5000/$repo --json | jq -r .Tables[0].Rows[].name | sed 's/^/        /g' - ; done
  #curl http://localhost:5000/v2/_catalog --silent | jq -r .repositories[] | sed 's/^/    /'
  end=`date +%s`
  runtime=$((end-start))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))
  echo ""
  echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
elif [[ $action == "delete" ]]; then
  if ! [[ $keep_local_registry ]]; then
    keep_local_registry="no"
  fi
  if [[ $keep_local_registry == "no" ]]; then
    echo "(1/2) Delete TCE TAP Cluster"
    tanzu uc delete $cluster_name
    echo "(2/2) Delete Local Registry"
    docker stop registry.local | sed 's/^/       /g'
    docker rm registry.local | sed 's/^/       /g'
  else
    echo "(1/1) Delete TCE TAP Cluster"
    tanzu uc delete $cluster_name
  fi
  echo "Your environment has been deleted."
  end=`date +%s`
  runtime=$((end-start))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))
  echo ""
  echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
elif [[ $action == "stop" ]]; then
  echo "(1/2) Stop TCE TAP Cluster"
  tanzu uc stop $cluster_name | sed 's/^/       /g'
  echo "(2/2) Stop Local Registry"
  docker stop registry.local | sed 's/^/       /g'
  echo "Your environment has been stopped."
  end=`date +%s`
  runtime=$((end-start))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))
  echo ""
  echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
elif [[ $action == "start" ]]; then
  echo "(1/2) Start Local Registry"
  docker start registry.local | sed 's/^/       /g'
  echo "(2/2) Start TCE TAP Cluster"
  tanzu uc start $cluster_name | sed 's/^/       /g'
  echo "Your environment has been started. please give it a few minutes to come back up fully and reconcile all of the packages."
  end=`date +%s`
  runtime=$((end-start))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))
  echo ""
  echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
elif [[ $action == "create" ]]; then
  # Validate Mandatory Flags were supplied
  if ! [[ $tanzunet_user || $tanzunet_password || $tap_package_repo_url ]]; then
    echo "Mandatory flags were not passed. use --help for usage information"
    exit 1
  fi
  if [[ $enable_remote_access == "yes" ]]; then
    if ! [[ $ip_address ]]; then
      echo "When enabling remote access, you must provide your machine IP address via the flag --ip-address"
      exit 1
    fi
  fi
  if [[ $insecure_expose_kube_api == "yes" ]]; then
    if ! [[ $ip_address ]]; then
      echo "When exposing the kube API outside of your machine, you must provide your machine IP address via the flag --ip-address"
      exit 1
    fi
  fi
  task_count=9
  if [[ $enable_techdocs == "yes" ]]; then
    ((task_count++))
  fi
  if [[ -n "$ca_file_path" ]]; then
    ((task_count++)) 
    ((task_count++))
    ((task_count++))
  fi
  # Default Values if not overridden via input flags
  if ! [[ $tap_profile ]]; then
    tap_profile="full"
  fi
  if ! [[ $tbs_descriptor ]]; then
    tbs_descriptor="lite"
  fi
  if ! [[ $kyverno_package_repo_url ]]; then
    kyverno_package_repo_url="ghcr.io/vrabbi/kyverno-tap-repo.terasky.oss:0.1.5"
  fi
  if ! [[ $tce_package_repo_url ]]; then
    tce_package_repo_url="projects.registry.vmware.com/tce/main:0.12.0"
  fi
  if ! [[ $tap_gui_catalog_url ]]; then
    tap_gui_catalog_url="https://github.com/vrabbi/tap-gui-beta-3/blob/master/yelb-catalog/catalog-info.yaml"
  fi
  if ! [[ $supply_chain ]]; then
    supply_chain="basic"
  fi
  if ! [[ $techdocs_container_image ]]; then
    techdocs_container_image="ghcr.io/vrabbi/techdocs:v1.0.3"
  fi
  if ! [[ $techdocs_dind_image ]]; then
    techdocs_dind_image="docker:dind-rootless"
  fi
  if ! [[ $ip_address ]]; then
    ip_address="127.0.0.1"
  fi
  if ! [[ $install_from_local_registry ]]; then
    install_from_local_registry="no"
  fi
  task=1
  mkdir -p $cluster_name-files | sed 's/^/       /g'
  cd $cluster_name-files | sed 's/^/       /g'
  echo "($task/$task_count) Generating Config files"
  ((task++))
  if [[ $ca_file_path ]]; then
    cat << EOF > $cluster_name.yaml
ClusterName: $cluster_name
Cni: calico
PortsToForward:
  - HostPort: 80
    ContainerPort: 80
  - HostPort: 443
    ContainerPort: 443
EOF
  else
    cat << EOF > $cluster_name.yaml
ClusterName: $cluster_name
Cni: calico
AdditionalPackageRepos:
  - $tce_package_repo_url
  - $tap_package_repo_url
  - $kyverno_package_repo_url
PortsToForward:
  - HostPort: 80
    ContainerPort: 80
  - HostPort: 443
    ContainerPort: 443
InstallPackages:
- name: secretgen-controller
  version: 0.7.1
- name: kyverno
  version: 2.3.5
- name: tap
  version: $tap_version
  config: tap-values.yaml
EOF
  fi
  if [[ $insecure_expose_kube_api == "yes" ]]; then
    cat << EOF >> $cluster_name.yaml
ProviderConfiguration:
  rawKindConfig: |
    networking:
      apiServerAddress: $ip_address
EOF
  fi
  if [[ $tap_profile == "full" ]]; then
    cat << EOF > tap-values.yaml
profile: full
ceip_policy_disclosed: true
buildservice:
  kp_default_repository: "registry.local:5000/tap/tbs"
  kp_default_repository_username: "admin"
  kp_default_repository_password: "admin"
  tanzunet_username: "$tanzunet_user"
  tanzunet_password: "$tanzunet_password"
  descriptor_name: "$tbs_descriptor"
  enable_automatic_dependency_updates: true

tap_gui:
  service_type: ClusterIP
  ingressEnabled: "true"
  ingressDomain: "$ip_address.nip.io"
  app_config:
    app:
      baseUrl: http://tap-gui.$ip_address.nip.io
      title: Local TAP Environment
      support:
        url: https://github.com/vrabbi/local-tap-setup
        items:
          - title: Issues
            icon: github
            links:
            - url: https://github.com/vrabbi/local-tap-setup/issues
              title: Github Issues
          - title: Blog
            icon: docs
            links:
            - url: https://vrabbi.cloud
              title: vRabbi's Blog
          - title: Contact Support
            icon: email
            links:
            - url: https://tanzu.vmware.com/support
              title: Tanzu Support Page
          - title: Documentation
            icon: docs
            links:
            - url: https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/index.html
              title: Tanzu Application Platform Documentation
    organization:
      name: Local TAP Environment
    catalog:
      locations:
        - type: url
          target: "$tap_gui_catalog_url"
    backend:
      baseUrl: http://tap-gui.$ip_address.nip.io
      cors:
        origin: http://tap-gui.$ip_address.nip.io

cnrs:
  provider: local
  domain_name: $ip_address.nip.io
  domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}"

excluded_packages:
- learningcenter.tanzu.vmware.com
- workshops.learningcenter.tanzu.vmware.com
accelerator:
  server:
    service_type: "ClusterIP"

metadata_store:
  app_service_type: NodePort
EOF
  elif [[ $tap_profile == "iterate" ]]; then
    cat << EOF > tap-values.yaml
profile: iterate
ceip_policy_disclosed: true
buildservice:
  kp_default_repository: "registry.local:5000/tap/tbs"
  kp_default_repository_username: "admin"
  kp_default_repository_password: "admin"
  tanzunet_username: "$tanzunet_user"
  tanzunet_password: "$tanzunet_password"
  descriptor_name: "$tbs_descriptor"
  enable_automatic_dependency_updates: true
supply_chain: basic

ootb_supply_chain_basic:
  registry:
    server: "registry.local:5000"
    repository: "tap"
  gitops:
    ssh_secret: ""

cnrs:
  provider: local
  domain_name: $ip_address.nip.io
  domain_template: "{{.Name}}-{{.Namespace}}.{{.Domain}}"
EOF
  fi
  if [[ $supply_chain == "basic" ]]; then
    cat << EOF >> tap-values.yaml
supply_chain: basic

ootb_supply_chain_basic:
  registry:
    server: "registry.local:5000"
    repository: "tap"
  gitops:
    ssh_secret: ""
EOF
  elif [[ $supply_chain == "testing" ]]; then
    cat << EOF >> tap-values.yaml
supply_chain: testing

ootb_supply_chain_testing:
  registry:
    server: "registry.local:5000"
    repository: "tap"
  gitops:
    ssh_secret: ""
EOF
  elif [[ $supply_chain == "testing_scanning" ]]; then
    cat << EOF >> tap-values.yaml
supply_chain: testing_scanning

ootb_supply_chain_testing_scanning:
  registry:
    server: "registry.local:5000"
    repository: "tap"
  gitops:
    ssh_secret: ""
grype:
  targetImagePullSecret: "tap-registry"
EOF
  else
    echo "Error: Invalid Supply Chain name provided"
    exit 1
  fi
  if [[ -n $ca_file_path ]]; then
    sed 's/^/    /g' $ca_file_path > indented-ca-file.crt
    cat << EOF >> tap-values.yaml
shared:
  ca_cert_data: |
EOF
    cat indented-ca-file.crt >> tap-values.yaml
    cat << EOF >> tap-values.yaml
convention_controller:
  ca_cert_data: |
EOF
    cat indented-ca-file.crt >> tap-values.yaml
  fi
  echo "($task/$task_count) Creating the TCE kind based unmanaged cluster"
  ((task++))
  tanzu uc create -f $cluster_name.yaml
  if [[ $ca_file_path ]]; then
    echo "($task/$task_count) Configuring Kapp Controller to Trust the provided CA"
    ((task++))
    tap_repo_name=`echo $tap_package_repo_url | sed 's|/|-|g' | sed 's|:|-|g'`
    kyverno_repo_name=`echo $kyverno_package_repo_url | sed 's|/|-|g' | sed 's|:|-|g'`
    cat <<EOF > kapp-controller-config-ca-overlay.yaml
data:
  caCerts: |
EOF
    cat indented-ca-file.crt >> kapp-controller-config-ca-overlay.yaml
    rm -f indented-ca-file.crt
    kubectl patch cm -n tkg-system kapp-controller-config --patch-file kapp-controller-config-ca-overlay.yaml | sed 's/^/       /g'
    RS_NAME=`kubectl get replicasets.apps -n tkg-system -l app=kapp-controller --sort-by=.metadata.creationTimestamp --no-headers -o json | jq -r .items[0].metadata.name`
    kubectl delete replicaset -n tkg-system $RS_NAME | sed 's/^/       /g'
    echo "($task/$task_count) Installing Package Repositories and Packages for TAP"
    ((task++))
    tanzu package repository add $tap_repo_name -n tanzu-package-repo-global --url $tap_package_repo_url
    tanzu package repository add $kyverno_repo_name -n tanzu-package-repo-global --url $kyverno_package_repo_url
    tanzu package install -n tkg-system secretgen-controller -p secretgen-controller.terasky.oss -v 0.7.1 --wait=false
    tanzu package install -n tkg-system kyverno -p kyverno.terasky.oss -v 2.3.5 --wait=false
    tanzu package install -n tkg-system tap -p tap.tanzu.vmware.com -v $tap_version --wait=false -f tap-values.yaml
  fi
  kubectl create ns tap-install | sed 's/^/       /g'
  if [[ $install_from_local_registry == "no" ]]; then
    echo "($task/$task_count) Creating a local docker registry to be used for TAP workloads and TBS images"
    ((task++))
    docker run -d --restart=always -p "5000:5000" --name "registry.local" registry:2 | sed 's/^/       /g'
  else
    echo "($task/$task_count) Connecting your local docker registry to the TCE docker network to be used for TAP workloads and TBS images"
    ((task++))
  fi
  docker network connect kind registry.local | sed 's/^/       /g'
  echo "($task/$task_count) Configuring TCE cluster to trust the insecure local registry"
  ((task++))
  docker cp $cluster_name-control-plane:/etc/containerd/config.toml ./config.toml | sed 's/^/       /g'
  tap_registry_fqdn=`echo $tap_package_repo_url | sed 's|/.*||g'`
  if [[ $dockerhub_registry_mirror ]]; then
    cat << EOF >> config.toml
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["$dockerhub_registry_mirror"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."$tap_registry_fqdn"]
      endpoint = ["https://$tap_registry_fqdn"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.local:5000"]
      endpoint = ["http://registry.local:5000"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."$tap_registry_fqdn".tls]
      insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.local:5000".tls]
      insecure_skip_verify = true
EOF
  else
    cat << EOF >> config.toml
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."$tap_registry_fqdn"]
      endpoint = ["https://$tap_registry_fqdn"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.local:5000"]
      endpoint = ["http://registry.local:5000"]
  [plugins."io.containerd.grpc.v1.cri".registry.configs]
    [plugins."io.containerd.grpc.v1.cri".registry.configs."$tap_registry_fqdn".tls]
      insecure_skip_verify = true
    [plugins."io.containerd.grpc.v1.cri".registry.configs."registry.local:5000".tls]
      insecure_skip_verify = true
EOF
  fi
  docker cp config.toml $cluster_name-control-plane:/etc/containerd/config.toml | sed 's/^/       /g'
  docker exec $cluster_name-control-plane service containerd restart | sed 's/^/       /g'
  echo "($task/$task_count) Setting up Access to the local registry from your docker daemon..."
  ((task++))
  ipAddr=`docker inspect -f '{{.NetworkSettings.IPAddress}}' registry.local | tr '\n' ' '`
  hostName="registry.local"
  matchesInHosts=`grep -n registry.local /etc/hosts | cut -f1 -d:`
  hostEntry="$ipAddr $hostName"
  if [ ! -z "$matchesInHosts" ]
  then
    echo "Updating existing hosts entry." | sed 's/^/       /g'
    # iterate over the line numbers on which matches were found
    while read -r line_number; do
      # replace the text of each line with the desired host entry
      sudo sed -i "${line_number}s/.*/${hostEntry} /" /etc/hosts
    done <<< "$matchesInHosts"
  else
    echo "Adding new hosts entry." | sed 's/^/       /g'
    echo "$hostEntry" | sudo tee -a /etc/hosts > /dev/null
  fi
  cat << EOF > registry-cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
  kubectl apply -f registry-cm.yaml | sed 's/^/       /g'
  rm -f registry-cm.yaml
  echo "($task/$task_count) Waiting for SecretGen Controller installation to complete"
  ((task++))
  cat << EOF > reg-creds-secret.yaml
apiVersion: v1
data:
  .dockerconfigjson: eyJhdXRocyI6eyJyZWdpc3RyeS5sb2NhbDo1MDAwIjp7InVzZXJuYW1lIjoiYWRtaW4iLCJwYXNzd29yZCI6ImFkbWluIn19fQ==
kind: Secret
metadata:
  name: registry-credentials
  namespace: tap-install
type: kubernetes.io/dockerconfigjson
EOF
  kubectl apply -f reg-creds-secret.yaml | sed 's/^/       /g'
  rm -f reg-creds-secret.yaml
  kubectl wait -n tkg-system --for=condition=ReconcileSucceeded pkgi/secretgen-controller --timeout=10m | sed 's/^/       /g'
  cat << EOF > reg-creds-secret-export.yaml
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: registry-credentials
  namespace: tap-install
spec:
  toNamespaces:
  - '*'
EOF
  kubectl apply -f reg-creds-secret-export.yaml | sed 's/^/       /g'
  rm -f reg-creds-secret-export.yaml
  echo "($task/$task_count) Waiting for TAP installation to complete"
  ((task++))
  kubectl wait -n tkg-system --for=condition=ReconcileSucceeded pkgi/tap --timeout=15m | sed 's/^/       /g'
  echo "($task/$task_count) Trigger Kyverno generate policy on the default namespace"
  ((task++))
  kubectl label namespace default a=b | sed 's/^/       /g'
  kubectl label namespace default a- | sed 's/^/       /g'
  echo "($task/$task_count) Patching Kapp Controller to support TAP generated App CRs"
  ((task++))
  cat << EOF > kapp-controller-dns-patch.yaml
spec:
  template:
    spec:
      dnsPolicy: "ClusterFirstWithHostNet"
EOF
  kubectl patch deployment -n tkg-system kapp-controller --patch-file kapp-controller-dns-patch.yaml | sed 's/^/       /g'
  RS_NAME=`kubectl get replicasets.apps -n tkg-system -l app=kapp-controller --sort-by=.metadata.creationTimestamp --no-headers -o json | jq -r .items[0].metadata.name`
  kubectl delete replicaset -n tkg-system $RS_NAME | sed 's/^/       /g'
  if [[ $enable_techdocs == "yes" ]]; then
    echo "($task/$task_count) Enabling Techdocs via Overlay Mechanism"
    ((task++))
    kubectl patch pkgi tap -n tkg-system -p '{"spec":{"paused":true}}' --type=merge | sed 's/^/       /g'
    kubectl patch pkgi tap-gui -n tap-install -p '{"spec":{"paused":true}}' --type=merge | sed 's/^/       /g'
    cat << EOF > tap-gui-dind-patch.yaml
spec:
  template:
    spec:
      containers:
      - command:
        - dockerd
        - --host
        - tcp://127.0.0.1:2375
        image: $techdocs_dind_image
        imagePullPolicy: IfNotPresent
        name: dind-daemon
        resources: {}
        securityContext:
          privileged: true
          runAsUser: 0
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /tmp
          name: tmp
        - mountPath: /output
          name: output
      - name: backstage
        env:
        - name: DOCKER_HOST
          value: tcp://localhost:2375
        volumeMounts:
        - mountPath: /tmp
          name: tmp
        - mountPath: /output
          name: output
      volumes:
      - emptyDir: {}
        name: tmp
      - emptyDir: {}
        name: output
EOF
    kubectl get secret -n tap-gui app-config-ver-1 -o json | jq -r '.data."app-config.yaml"' | base64 -d > tap-gui-secret.yaml | sed 's/^/       /g'
    cat <<EOF >> tap-gui-secret.yaml
techdocs:
  generator:
    dockerImage: $techdocs_container_image
EOF
    CM_CONTENT=`cat tap-gui-secret.yaml | base64 -w 0`
    cat << EOF >> tap-gui-secret-patch.yaml
data:
  app-config.yaml: $CM_CONTENT
EOF
    kubectl patch secret -n tap-gui app-config-ver-1 --patch-file tap-gui-secret-patch.yaml | sed 's/^/       /g'
    kubectl patch deploy server -n tap-gui --patch-file tap-gui-dind-patch.yaml | sed 's/^/       /g'
    kubectl rollout status deployment server -n tap-gui | sed 's/^/       /g'
  fi
  # Move config files to the dedicated folder
  mv $cluster_name.yaml tap-values.yaml tap-gui-secret-patch.yaml tap-gui-dind-patch.yaml kapp-controller-dns-patch.yaml config.toml tap-gui-secret.yaml kapp-controller-config-ca-overlay.yaml $cluster_name-files/ 2>/dev/null
  echo "Your local TAP environment is ready!"
  if [[ $tap_profile == "full" ]]; then
    echo ""
    echo "You can access TAP GUI at: http://tap-gui.$ip_address.nip.io"
  fi
  cat << EOF

Local Registry Info:
    Login command: docker login localhost:5000
    Username: user
    Password: password

    When referencing images within kubernetes, the registry name is registry.local:5000 and not localhost:5000
EOF
  if [[ $supply_chain != "basic" ]]; then
    cat << EOF

Sample App Deployment:
    Deploy Command: tanzu apps workload create demo01 --git-repo https://github.com/sample-accelerators/tanzu-java-web-app --git-branch main --type web --label app.kubernetes.io/part-of=demo01 --yes --label apps.tanzu.vmware.com/has-tests="true"
  
    Command to follow along with the supply chain: tanzu apps workload tail demo01
   
    Your deployed app is now accessible at: http://demo01-default.$ip_address.nip.io
EOF
  fi
  if [[ $supply_chain == "basic" ]]; then
    cat << EOF

Sample App Deployment:
    Deploy Command: tanzu apps workload create demo01 --git-repo https://github.com/sample-accelerators/tanzu-java-web-app --git-branch main --type web --label app.kubernetes.io/part-of=demo01 --yes
    
    Command to follow along with the supply chain: tanzu apps workload tail demo01
    
    Your deployed app is now accessible at: http://demo01-default.$ip_address.nip.io
EOF
  fi
  echo ""
  echo "Happy TAPing!"
  end=`date +%s`
  runtime=$((end-start))
  hours=$((runtime / 3600))
  minutes=$(( (runtime % 3600) / 60 ))
  seconds=$(( (runtime % 3600) % 60 ))
  echo ""
  echo "Script Runtime: $hours:$minutes:$seconds (hh:mm:ss)"
else
  echo "Unknown Action"
  exit 1
fi
