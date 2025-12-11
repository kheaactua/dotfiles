#!/bin/zsh

# This file is symlinked here after env modules is installed from source
declare module_profile_file="/etc/profile.d/modules.sh"
if [[ -e "${module_profile_file}" ]]; then
  declare -f module > /dev/null || . "${module_profile_file}"

	# modules_enabled=1;

	# Environmental Modules
	# The module command is now installed in /etc/profile.d/env-modules.sh

	# case "$0" in
	# -sh|sh|*/sh)        modules_shell=sh   ;;
	# -ksh|ksh|*/ksh)     modules_shell=ksh  ;;
	# -zsh|zsh|*/zsh)     modules_shell=zsh  ;;
	# -bash|bash|*/bash)  modules_shell=bash ;;
	# esac

	# export MODULEPATH=/usr/share/modules/modulefiles

	# # #module() { eval `/usr/Modules/$MODULE_VERSION/bin/modulecmd $modules_shell $*`; }
	# modulecmd=$(which modulecmd)
	# module() { eval `${modulecmd} $modules_shell $*`; }


  if [[ -e "${HOME}/.modulefiles" ]]; then
    module use "${HOME}/.modulefiles"
  fi
else
  echo "Environment modules ($module_profile_file) not installed"
fi

# vim: ts=2 sw=2 et :
