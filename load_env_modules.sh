#!/bin/zsh

# This file is symlinked here after env modules is installed from source
# I suspect I messed up the manual install so now I guess at which file to source
declare -a module_candidates=(
  /etc/profile.d/env-modules.sh
  /etc/profile.d/modules.sh
  /usr/share/Modules/init/zsh
)
for module_file in "${module_candidates[@]}"; do
  if [[ -e "${module_file}" ]]; then
    declare -f module > /dev/null || . "${module_file}"
    break
  fi
done

if ! declare -f module > /dev/null; then
  echo "Environment modules not installed"
else
  if [[ -e "${HOME}/.modulefiles" ]]; then
    module use "${HOME}/.modulefiles"
  fi
fi

# vim: ts=2 sw=2 et :
