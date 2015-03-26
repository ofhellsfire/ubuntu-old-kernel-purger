#!/bin/bash
#
# Purge old kernel versions from Linux Ubuntu 14.04

#######################################
# Remove repeated values from array
# Globals:
#   UNIQ
# Arguments:
#   array
# Returns:
#   None
#######################################
function make_unique {
  UNIQ=$(echo "${@}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
}

######################################
#
# This section stands for 
# configuration variables
#
######################################
# How many latest packages to keep
readonly keep_count=2

# Coloring
readonly style_bold="$(tput bold)"
readonly style_rst="$(tput sgr0)"
readonly style_c_red="$(tput setaf 1)"
readonly style_c_green="$(tput setaf 2)"

############# E N D ##################


# Get current kernel version and split it into pieces
readonly current_kernel="$(uname -r)"

if [[ "$?" -ne 0 ]]; then
  echo "Unable to get kernel version." >&2
  exit 1
fi

## Splitting into pieces 
readonly current_kernel_parts=( ${current_kernel//-/ } )
readonly version_major=${current_kernel_parts[0]}
readonly version_minor=${current_kernel_parts[1]}
readonly version_type=${current_kernel_parts[2]}

# Feedback output
echo ""
echo "Current kernel version information: ${version_major}-${version_minor}-${version_type}"
echo ""



# Get installed minor kernel versions
readonly kernel_packages="$(ls /boot/ | grep ${version_type})"

if [[ "$?" -ne 0 ]] && [[ ${#kernel_packages[*]} -eq 0 ]]; then
  echo "Unable to get installed kernel packages." >&2
  exit 1
fi

declare -a installed_minors=()

for file in ${kernel_packages[@]}
do
  file_parts=( ${file//-/ } )
  installed_minors+=(${file_parts[2]})
  installed_major=(${file_parts[1]})
done

make_unique ${installed_minors[@]}

IFS=' ' read -ra uniq <<< ${UNIQ}

# Feedback output
echo ""
echo "Following packages are found:"
echo ""
for i in ${kernel_packages[@]}; do
  echo ${i}
done
echo ""



# Check if installed major matches
if [[ ${installed_major} != ${version_major} ]]; then
  echo "Extracted installed major version: ${installed_major} doesn't match against current version: ${version_major}." >&2
  exit 1
fi

# Compile versions to be purged
readonly versions_to_be_purged=${uniq[@]::(${#uniq[@]} - ${keep_count})}

if [[ $((${#uniq[@]} - ${keep_count})) == 0 ]]; then
  echo "No old packages found. Nothing to purge. Exiting..."
  exit 0
fi

echo "Staring purging process..."
echo ""
for ver in ${versions_to_be_purged}
do
  echo "The following package will be removed: ${style_bold}${style_c_red}${version_major}-${ver}-${version_type}${style_rst}"
  echo ""
  if [[ ${ver} != ${version_minor} ]]; then
    apt-get purge linux-image-${version_major}-${ver}-${version_type}
  else
  	echo "${style_bold}${style_c_red}Can't purge loaded version. Skipping purging of currently loaded package...${style_rst}"
  fi
  echo ""
done

echo "${style_bold}${style_c_green}The purging process has been finished successfully${style_rst}"
exit 0
