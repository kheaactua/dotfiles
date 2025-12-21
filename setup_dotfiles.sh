#!/bin/bash
# shellcheck disable=SC2155

# This script used to attempt to use dotfiles from the windows partition if
# this was running on the WSL (if WINHOME was defined), however this just
# causes more headaches than it solves
declare h="${HOME}"

declare -r DOTFILES_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
source "${DOTFILES_DIR}/lib/detect_platform.sh"
source "${DOTFILES_DIR}/lib/rclib.sh"
source "${DOTFILES_DIR}/lib/lib.sh"

declare -r DOTFILES_SECRET_DIR="${DOTFILES_DIR}/dotfiles-secret"

ARGUMENT_STR_LIST=(
  "home"
)
# TODO re-write these to change skip to include
ARGUMENT_FLAG_LIST=(
  "skip-apt"
  "install-powerline"
  "skip-fzf"
  "skip-python-venv"
  "skip-tmux"
  "skip-submodules"
  "skip-zplug"
  "skip-rofi"
  "skip-i3"
  "skip-gnupg"
  "skip-cargo"
  "small"
  "stow"
)

# read arguments
opts=$(getopt \
    --longoptions "$(printf "%s:," "${ARGUMENT_STR_LIST[@]}")$(printf "%s," "${ARGUMENT_FLAG_LIST[@]}")" \
    --name "$(basename "$0")" \
    --options "" \
    -- "$@"
)
eval set --$opts

declare skip_apt=0
declare skip_powerline=1
declare skip_python_venv=0
declare skip_fzf=0
declare skip_tmux=0
declare skip_submodules=0
declare skip_zplug=0
declare skip_rofi=0
declare skip_i3=0
declare skip_gnupg=0
declare skip_cargo=0
declare just_stow=0
while [[ "" != $1 ]]; do
  case "$1" in
  "--home")
    shift
    h=$1
    ;;
  "--skip-apt")
    skip_apt=1
    ;;
  "--install-powerline")
    skip_powerline=0
    ;;
  "--skip-python-venv")
    skip_python_venv=1
    ;;
  "--skip-fzf")
    skip_fzf=1
    ;;
  "--skip-tmux")
    skip_tmux=1
    ;;
  "--skip-submodules")
    skip_submodules=1
    ;;
  "--skip-zplug")
    skip_zplug=1
    ;;
  "--skip-rofi")
    skip_rofi=1
    ;;
  "--skip-i3")
    skip_i3=1
    ;;
  "--skip-gnupg")
    skip_gnupg=1
    ;;
  "--skip-cargo")
    skip_cargo=1
    ;;
  "--small")
    skip_apt=1
    skip_tmux=1
    skip_fzf=1
    skip_python_venv=1
    skip_powerline=1
    skip_submodules=1
    skip_rofi=1
    skip_i3=1
    skip_gnupg=1
    skip_cargo=1
    ;;
  "--stow")
    skip_apt=1
    skip_tmux=1
    skip_fzf=1
    skip_python_venv=1
    skip_powerline=1
    skip_submodules=1
    skip_rofi=1
    skip_i3=1
    skip_gnupg=1
    skip_cargo=1
    just_stow=1
    ;;
  "--")
    shift
    break
    ;;
  esac
  shift
done

echo "Using home: ${h}"

declare -r backup_dir="${h}/.dotfiles_backup"
declare -r DFTMP="$(mktemp -d)"
declare -r VENVS="${h}/.virtualenvs"

# First ensure that the submodules in this repo
# are available and up to date:
if [[ ! "1" == "${skip_submodules}" ]]; then
  dotfiles_clone_submodules
fi

cd "${h}" || exit 1

#
# TODO deal with Windows Terminal, PS, etc, files
# TODO Create a function to mkdir.. I do that a lot here.
#

if [[ "1" != "${skip_apt}" ]]; then
  pkgs=(curl stow git rlwrap pinentry-gnome3 pinentry-curses pinentry-tty rofi autorandr)
  is_ubuntu && sudo apt-get install -qy "${pkgs[@]}" environment-modules pass
  is_arch   && sudo pacman -S --noconfirm "${pkgs[@]}" which inetutils rofi-pass
fi

# TODO
# Other things to setup that aren't handled
# bash won't stow on a new system because .bashrc exists by default
# https://github.com/spwhitton/git-remote-gcrypt , which needs python3-docutils
# Installing rustup: curl https://sh.rustup.rs -sSf | sh
#   Add this to dotfiles_install_cargo
# cargo install bob-nvim
# curl -LsSf https://astral.sh/uv/install.sh | sh
# docker-credential-helper: https://github.com/docker/docker-credential-helpers/releases
#   Manually install this (with a symlink) to /usr/local/bin
# rofi-pass on ubuntu.  https://github.com/carnager/rofi-pass and `sudo make`

#
# Declare the stows we want to install
declare -a stows;
stows+=(zsh bash bat vnc gdb neovim vim tmux git p10k env-modules procs rlwrap zellij screenlayout autorandr npm zoxide ripgrep kitty sway ccache fish)

if [[ "1" != "${skip_powerline}" ]]; then
  dotfiles_install_powerline_fonts
else
  echo "Skipped installing powerline fonts"
fi

[[ "khea" == "$(hostname)" ]] && stows+=('xinit')

[[ $(_exists tmux) && "1" != "${skip_tmux}" ]] && dotfiles_install_tpm "${h}"

_exists screen && stows+=('screen')
_exists sqlite3 && stows+=('sqlite')

if _exists vncserver || _exists tightvncserver; then
  stows+=('vnc')
fi

# Create a backup directory:
[[ -e "${backup_dir}" ]] || mkdir -p "${backup_dir}"

cd "$h" || exit 1

dotfiles_setup_ssh_config "${h}" "${DOTFILES_SECRET_DIR}"

if [[ "1" != "${skip_zplug}" ]]; then
  dotfiles_install_zplug "${h}" "${DFTMP}"
else
  echo "Skipped installing zplug"
fi

if [[ "1" != "${skip_rofi}" ]]; then
  stows+=('rofi')
  # dotfiles_install_rofi "${h}"
  # dotfiles_install_rofipass "${h}"
else
  echo "Skipped installing rofi"
fi

# Make sure config directory exists
[[ -e "${h}/.config" ]] || mkdir -p "${h}/.config"

# Because sway points to i3, this doesn't fit well with stow.  I can remove the
# complexity once all my systems are using sway.
declare current_wm;
if [ "$XDG_SESSION_DESKTOP" = "sway" ] || [ "$DESKTOP_SESSION" = "sway" ]; then
  current_wm="sway"
elif [ "$XDG_SESSION_DESKTOP" = "i3" ] || [ "$DESKTOP_SESSION" = "i3" ]; then
  current_wm="i3"
fi

skip_i3=0
if [[ "1" != "${skip_i3}" ]]; then
  if [ "i3" == "${current_wm}" ]; then
    dotfiles_install_i3 "${h}"
    stows+=('i3')
  elif [ "sway" == "${current_wm}" ]; then
    # dotfiles_install_sway "${h}"
    stows+=('sway')
  fi
else
  echo "Skipped installing i3/sway"
fi

# Setup pwsh on linux
_exists pwsh && stows+=('pwsh')

# Setup pwsh on linux
_exists fsb && stows+=('fsb')

# Install fzf
if [[ "1" != "${skip_fzf}" ]]; then
  dotfiles_install_fzf "${h}"
else
  echo "Skipped installing fzf"
fi

# Setup default virtualenv
if [[ "1" != "${skip_python_venv}" ]]; then
  dotfiles_setup_python_venvs "${h}" "${VENVS}"
else
  echo "Skipped setting up python virtual environments"
fi

# GPG-Agent
if [[ "1" != "${skip_gnupg}" ]]; then
  dotfiles_install_gnupg "${h}" "${DOTFILES_SECRET_DIR}"
else
  echo "Skipped installing gnupg"
fi

if [[ ! -e "${h}/.ssh/tmp" ]]; then
  mkdir -p "${h}/.ssh/tmp"
  chmod 700 "${h}/.ssh"
fi

for s in "${stows[@]}"; do
  # set -x
  stow -d "${DOTFILES_DIR}/stow" -t "${h}" "${s}"
  # set +x
done

#
# Setup's that can or should occur after stow
#

# NPM packages
if [[ "1" != "${just_stow}" ]]; then
  echo "skipping npm"
  # dotfiles_install_npm "${h}"
else
  echo "Skipping npm install"
fi

# Cargo
if [[ "1" != "${skip_cargo}" ]]; then
  dotfiles_install_cargo "${h}"
  cargo install ripgrep du-dust fd-find
else
  echo "Skipped installing cargo config"
fi

# Run stow on the dotfiles-secret stows
if [[ -e "${DOTFILES_SECRET_DIR}/install.sh" ]]; then
  echo "Running secret install script"
  "${DOTFILES_SECRET_DIR}/install.sh"
else
  echo "Couldn't find ${DOTFILES_SECRET_DIR}/install.sh, skipping stow"
fi

# vim: ts=2 sw=2 sts=0 ff=unix et :
