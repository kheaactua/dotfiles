#!/bin/zsh

# This file is symlinked here after env modules is installed from source
declare module_profile_file="/etc/profile.d/modules.sh"
if [[ -e "${module_profile_file}" ]]; then
  declare -f module > /dev/null || . "${module_profile_file}"
  if [[ -e "${HOME}/.modulefiles" ]]; then
    module use "${HOME}/.modulefiles"
  fi
else
  echo "Environment modules ($module_profile_file) not installed"
fi

# vim: ts=2 sw=2 et :
