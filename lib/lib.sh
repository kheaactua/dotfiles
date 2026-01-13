# shellcheck shell=bash

# Requires ${DOTFILES_DIR:-${HOME}/dotfiles}
# Source after "${DOTFILES_DIR:-${HOME}/dotfiles}/detect_platform.dot"
# One day I'll convert this to pwsh so it can run on Windows as well.

function dotfiles_hostname() {
  hostname | tr '[:upper:]' '[:lower:]'
}

function symlink()
{
  local -r target=${1}; shift
  local -r link=${1}; shift
  local force=${1:-0}

  if [[ "0" != "${force}" ]]; then
    force=1
  fi

  local flags="-s"
  if [[ 0 != ${force} ]]; then
    flags="${flags}f"
  fi

  if [[ ! -e "${link}" || 1 == ${force} ]]; then
    ln ${flags} "${target}" "${link}"
  fi
}

function _dotfiles_check_if_fonts_are_installed()
{
  local home=${1:-${HOME}};
  local font_name=${2:-"Powerline"}

  find "${home}/.local/share/fonts" -type f | grep -i --color=none "${font_name}" > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    return 0
  else
    return 1
  fi
}

function dotfiles_install_powerline_fonts()
{
  local home=${1:-${HOME}};
  local DFTMP=${2:-"$(mktemp -d)"}

  if [[ $HOME == *com.termux* ]]; then
    echo "Avoiding install on termux"
    return
  fi

  # For now at least, don't install powerline fonts on termux
  mkdir -p "${home}/.local/share/fonts"

  # Install fonts
  if _dotfiles_check_if_fonts_are_installed "${home}" "Powerline"; then
    echo "Powerline fonts already installed"
  else
    if [[ ! -e "${DFTMP}/powerline_fonts" ]]; then
      git clone https://github.com/powerline/fonts.git "${DFTMP}/powerline_fonts"
    fi
    "${DFTMP}/powerline_fonts/install.sh"
  fi

  # apt-get install ttf-ancient-fonts -y
  # install http://input.fontbureau.com/download/  and http://larsenwork.com/monoid/ Hack the powerline font install script to mass install

  # Install nerd-fonts
  if _dotfiles_check_if_fonts_are_installed "${home}" "NerdFonts"; then
    if [[ ! -e "${DFTMP}/nerd_fonts/nerd_fonts" ]]; then
      git clone https://github.com/ryanoasis/nerd-fonts "${DFTMP}/nerd_fonts"
    fi
    "${DFTMP}/nerd_fonts/install.sh Meslo"
  fi
}

function dotfiles_install_cargo()
{
  local home=${1:-${HOME}}

  # Not using stow here because there's no point.  There are no config files in here.
  symlink "${DOTFILES_DIR:-${HOME}/dotfiles}/cargo" "${home}/.cargo"

  source "${DOTFILES_DIR:-${HOME}/dotfiles}/cargo/env"
  if _exists rustup; then
    echo "Cargo configuration files are setup, but rustup is not installed.  To install it, run:"
    echo "  curl https://sh.rustup.rs -sSf | sh"
    echo
    echo "Then, toolchains from ~/.cargo/config can be installed by running (example)"
    echo "  rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android"
  fi
}

function dotfiles_install_cargo_crates()
{
  # This function isn't complete, isn't even tested.. Right now it's better
  # thought of as a list of crates to install
  crates=( exa choose sd )
  cargo install ${crates[@]}
}


function dotfiles_install_gnupg()
{
  local home=${1:-${HOME}}
  local dotfiles_secret_dir=${2:-${DOTFILES_DIR:-${HOME}/dotfiles}/dotfiles-secret}

	stow -d "${DOTFILES_DIR}/stow" -t "${home}" gnupg

  if [[ -e "${dotfiles_secret_dir}" ]]; then
    symlink "${dotfiles_secret_dir}/global/gnupg/sshcontrol" "${home}/.gnupg/sshcontrol"
  fi
}

# function dotfiles_install_docker_config()
# {
#   local home=${1:-${HOME}}
#   local dotfiles_secret_dir=${2:-${DOTFILES_DIR:-${HOME}/dotfiles}/dotfiles-secret}

#   if [[ -e "${dotfiles_secret_dir}" && -e "${home}/.docker" && ! -e "${home}/.docker/config.json" ]]; then
#     symlink "${dotfiles_secret_dir}/docker" "${home}/.docker"
#   fi
# }

function dotfiles_install_tpm()
{
  local home=${1:-${HOME}}

  if [[ ! -e "${home}/.tmux/plugins/tpm" && $(_exists tmux) ]]; then
    echo "installing tmux"
    mkdir -p "${home}/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm "${home}/.tmux/plugins/tpm"
  fi
}

function dotfiles_install_zplug()
{
  local home=${1:-${HOME}}
  local tmp=${2:-$(mktemp -d)}

  if [[ ! -e "${home}/.zplug" ]]; then
    if [[ "1" == "$(detect_docker)" ]]; then
      git_proxy_args=""
      if [[ "" != "${http_proxy}" ]]; then
        git_proxy_args="--config=http.proxy=${http_proxy}"
      fi
      git clone ${git_proxy_args} https://github.com/zplug/zplug.git "${home}/.zplug"
      if [[ $? != 0 ]]; then
        echo "Couldn't clone zplug repo.  Is there a proxy blocking it?  Proxy env is:"
        env | grep -i proxy
      fi
    else
      curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh > "${tmp}/install_zplug.sh"
      if [[ $? == 0 ]]; then
        zsh "${tmp}/install_zplug.sh"
      else
        echo "Couldn't download zplug installer.  Is there a proxy blocking it?  Proxy env is:"
        env | grep -i proxy
      fi
    fi
  fi
}

function dotfiles_install_i3_config()
{
  local -r lower_hostname=$(dotfiles_hostname)
  local i3_dir=${1:-${DOTFILES_DIR:-${HOME}/dotfiles}/stow/i3/.config/i3}
  symlink "${i3_dir}/0-config.${lower_hostname}.i3" "${i3_dir}/config" 1
}

function dotfiles_install_i3()
{
  local home=${1:-${HOME}}
  if _exists i3; then
    local -r i3_config_dir="${DOTFILES_DIR:-${HOME}/dotfiles}/stow/i3/.config/i3"
    if [[ ! -e "${i3_config_dir}" ]]; then
      echo "Error: i3 config dir ${i3_config_dir} doesn't exist" >&2
      return 1
    fi

    dotfiles_install_i3_config "${i3_config_dir}"

    # Create a "host.sh" symlink with the appropriate screen layout
    symlink "${DOTFILES_DIR:-${HOME}/dotfiles}/stow/screenlayout/.screenlayout/$(dotfiles_hostname).sh" "${home}/.screenlayout/host.sh" 1
  fi
}

# deleted dotfiles_install_kotlin_language_server()

function dotfiles_install_sdkman()
{
  curl -s "https://get.sdkman.io" | bash
}

function dotfiles_setup_ssh_config()
{
  local -r home=${1:-${HOME}};
  local -r dotfiles_secret_dir="${2:-${DOTFILES_DIR:${home}/dotfiles}/dotfiles-secret}"
  local -r ssh_dir="${home}/.ssh"
  local -r ssh_config="${ssh_dir}/config"

  if [[ ! -e "${ssh_dir}" ]]; then
    mkdir "${ssh_dir}" && chmod 700 "${ssh_dir}"
  fi

  if [[ ! -e "${ssh_config}" ]]; then
    cat <<TOHERE > "${ssh_config}"
Include ~/dotfiles/dotfiles-secret/*/ssh/config

# vim: ts=4 sw=4 sts=0 expandtab ft=sshconfig
TOHERE
  fi
}

function dotfiles_clone_submodules() {
	pushd "${DOTFILES_DIR}" || return 1
	git submodule init
	git submodule update
  popd
}

function dotfiles_install_npm() {
  local home=${1:-${HOME}}

  if ! _exists nvm; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    export NVM_DIR="${home}/.nvm"
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
      echo "Error: nvm installation failed" >&2
      return 1
    fi
    \. "$NVM_DIR/nvm.sh"
  fi

  nvm install latest

  [[ -e "${HOME}/.npm_packages" ]] || mkdir -p "${HOME}/.npm_packages"

  # If this is the first npm install command, it'll complain that
  # ~/.npm_packageslib/ is missing, lets just ignore those
  # Sept 15 2025: Disabled this as it seems incompatible with a nvm install
  # npm config set prefix "${HOME}/.npm_packages" 2>&1 > /dev/null

  # This can take some time
  npm install -g npm
}

function get_distro() {
  if grep -q "ID=ubuntu" /etc/os-release; then
    echo ubuntu
  elif grep -q "ID=arch" /etc/os-release; then
    echo arch
  else
    echo "Neither Ubuntu nor Arch Linux detected."
  fi
}

function is_ubuntu() {
  [[ "ubuntu" == "$(get_distro)" ]] && return 0;
}

function is_arch() {
  [[ "arch" == "$(get_distro)" ]] && return 0;
}

function dotfiles_install_fzf()
{
  local home=${1:-${HOME}}

  if [[ ! -e "${home}/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "${home}/.fzf" || return 1
    cd "${home}/.fzf" || return 1
  else
    pushd "${home}/.fzf" || return 1
    git pull
  fi
  yes | "${home}/.fzf/install"
}

function dotfiles_install_pyvenv()
{
  local home=${1:-${HOME}}
  local VENVS="${2:-"${home}/.virtualenvs"}"

  if [[ "${DEFAULT_PYTHON_VENV:-undefined}" == "undefined" ]]; then
    DEFAULT_PYTHON_VENV="default"
  fi

  if ! _exists uv; then
    echo "Please install uv: https://docs.astral.sh/uv/getting-started/installation/"
  else

    if [[ ! -e "${VENVS}/${DEFAULT_PYTHON_VENV}" ]]; then
      mkdir -p "${VENVS}"
      pushd .
      cd "${VENVS}" || return 1
      echo "Creating virtual python environment ${DEFAULT_PYTHON_VENV}"
      # python3 -m env "${DEFAULT_PYTHON_VENV}"
      uv venv "${DEFAULT_PYTHON_VENV}"
      popd || return 1
    fi
  fi
}

# vim: ts=2 sw=2 sts=0 ff=unix expandtab ft=sh :
