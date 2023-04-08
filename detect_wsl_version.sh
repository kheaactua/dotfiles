#!/bin/bash

wsl_version=$(uname -r | grep --color=never -oP '(?<=WSL)([0-9+])')
if [[ "$?" != 0 ]]; then
  wsl_version=0
fi

echo -n $wsl_version
