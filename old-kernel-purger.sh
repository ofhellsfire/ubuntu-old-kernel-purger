#!/bin/bash -e

BASH_VER=( ${BASH_VERSION//./ } )
MIN_SUPPORT_VERSION=4

print_help() {
echo "Script Name: ${0:2}

Deletes old kernel packages for Ubuntu 14.04 (requires root privileges)

Usage:
-h, --help		Print usage
-d, --dry-run		Run without making real actions.
                	Useful for examining what packages
                	will be removed. Default: false
-y, --yes		Run in non-interactive mode.
			Default: false
-k <num>, --keep <num>	Specify how many latest versions to keep.
			Default: 2"
}

check_bash_version() {
  if [[ "${BASH_VER[0]}" -lt "${MIN_SUPPORT_VERSION}" ]]; then
    echo "Unsupported Bash version has been detected. Detected Bash version is ${BASH_VER[0]}. Minimal required version is ${MIN_SUPPORT_VERSION}. Exiting..."
    exit 1
  fi
}

check_privileges() {
  if [[ "$EUID" -ne 0 ]]; then
    echo "Script must be run with root privileges. Exiting..."
    exit 2
  fi
}

create_exclude() {
  readarray kernelkeep < .kernelkeep
  for line in ${kernelkeep[@]}; do
    exclude="${exclude}|${line}"
    echo "The following package will be kept: ${line}-generic"
  done
}

find_keep() {
  for ((x=0;x<${keep_count};x++)); do
    unset packages
    declare -A packages
    names=($(ls /boot | grep vmlinuz | grep -Ev "${exclude}" | grep -Ev "${keep}"))

    for ((i=0;i<${#names[@]};i++)); do
      name=${names[$i]}

      # split string
      parted=( ${name//-/ } )
      version=( ${parted[1]//./ } )
      major=${version[0]}
      minor=${version[1]}
      sub_minor=${version[2]}
      build=${parted[2]}
      packages[$i,0]=$name
      packages[$i,1]=$major
      packages[$i,2]=$minor
      packages[$i,3]=$sub_minor
      packages[$i,4]=$build
    done

    maxi=0
    maxk=$(( ${packages[0,1]} * 1000000000 + ${packages[0,2]} * 1000000 + ${packages[0,3]} * 1000 + ${packages[0,4]} ))
    for ((j=1;j<$(( ${#packages[@]} / 5 ));j++)); do
      k=$(( ${packages[$j,1]} * 1000000000 + ${packages[$j,2]} * 1000000 + ${packages[$j,3]} * 1000 + ${packages[$j,4]} ))
      if [[ ${k} -ge ${maxk} ]]; then
        maxi=$j
        maxk=${k}
      fi
    done

    echo "The following package will be kept: ${packages[$maxi,1]}.${packages[$maxi,2]}.${packages[$maxi,3]}-${packages[$maxi,4]}-generic"

    keep="${keep}|${packages[$maxi,0]}"
  done
}

delete_packages() {
  names=($(ls /boot | grep vmlinuz | grep -Ev "${exclude}" | grep -Ev "${keep}"))
  declare -A packages_to_delete

  for ((i=0;i<${#names[@]};i++)); do
    name=${names[$i]}

    # split string
    parted=( ${name//-/ } )
    version=( ${parted[1]//./ } )
    major=${version[0]}
    minor=${version[1]}
    sub_minor=${version[2]}
    build=${parted[2]}
    packages_to_delete[$i,0]=$name
    packages_to_delete[$i,1]=$major
    packages_to_delete[$i,2]=$minor
    packages_to_delete[$i,3]=$sub_minor
    packages_to_delete[$i,4]=$build
  done

  for ((m=0;m<$(( ${#packages_to_delete[@]} / 5 ));m++)); do
    # echo "${packages_to_delete[$m,0]}";
    yes=""
    if [[ ${YES} ]]; then
      yes="-y "
    fi
    pkg="linux-image-${packages_to_delete[$m,1]}.${packages_to_delete[$m,2]}.${packages_to_delete[$m,3]}-${packages_to_delete[$m,4]}-generic"
    echo "Package to be deleted: ${pkg}"
    if [[ -z ${DRYRUN} ]]; then
      apt-get ${yes}purge ${pkg}
    fi
  done
}

main() {
  check_bash_version

  while true; do
    case "$1" in
      -h | --help ) print_help; exit 0 ;;
      -d | --dry-run ) DRYRUN=true; shift ;;
      -y | --yes ) YES=true; shift ;;
      -k | --keep ) KEEP=${2}; shift 2 ;;
      * ) break ;;
    esac
  done

  check_privileges

  keep=$(uuidgen)
  keep_count=${KEEP:=2}
  exclude=$(uname -r)

  create_exclude
  echo "The following package will be kept: $(uname -r)"
  find_keep
  delete_packages
}

main "$@"
