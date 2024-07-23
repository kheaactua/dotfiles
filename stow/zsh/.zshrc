# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ "undefined" == "${DOTFILES_DIR:-undefined}" ]]; then
	export DOTFILES_DIR="${HOME}/dotfiles"
fi

if [[ -e "${DOTFILES_DIR}/rclib.dot" ]]; then
	source "${DOTFILES_DIR}/rclib.dot"
fi

source "${DOTFILES_DIR}/init_gpg_session.dot"

# Currently only loads init_ssh_agent, doesn't run it
source "${DOTFILES_DIR}/init_ssh_agent_session.dot"

if [[ -e "${DOTFILES_DIR}/doupdate.sh" && ! "$(hostname)" =~ sync* ]]; then
	# Update the dotfiles repo to make sure we have all changes:
	"${DOTFILES_DIR}/doupdate.sh" > /dev/null
fi

# Keep 1000 lines of history within the shell and save it to ${HOME}/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE="${HOME}/.zsh_history"

export LANG=en_US.UTF-8
export LC_TIME=en_GB.UTF-8

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# On the WSL, it's handy to use Windows $env:temp space
WSL_TEMP_GUESS=${HOME}/tmp
if [[ -O ${WSL_TEMP_GUESS} && -d ${WSL_TEMP_GUESS} ]]; then
	# # Shouldn't this be this?:
	# alias win_tmp=$(wslpath -u "C:\Users\$(whoami)\AppData\Local\Temp")
	TMPDIR="${WSL_TEMP_GUESS}"
fi

# Adjust the path
if [[ -e "${HOME}/.pathrc" ]]; then
	source "${HOME}/.pathrc"
fi

declare WSL_VERSION=0
declare IN_DOCKER=0
declare PLATFORM=linux_x86_64

if [[ -e "${DOTFILES_DIR}/detect_platform.dot" ]]; then
	source "${DOTFILES_DIR}/detect_platform.dot"

	WSL_VERSION="$(detect_wsl)"
	IN_DOCKER="$(detect_docker)"
	PLATFORM="$(detect_platform)"
else
	echo "Warning: Cannot detect platform"
fi

if [[ -e "${HOME}/.zplug" ]]; then
	source "${HOME}/.zplug/init.zsh"

	# Bundles from robbyrussell's oh-my-zsh.
	zplug "plugins/git", from:oh-my-zsh

	zplug "plugins/command-not-found", from:oh-my-zsh
	zplug "lib/directories", from:oh-my-zsh          # Provides the directory stack

	zplug "lib/history", from:oh-my-zsh              # Provides history management

	if [[ -e "${LINUXBREWHOME}/.linuxbrew/share/zsh/site-functions" ]]; then
		fpath+=("${LINUXBREWHOME}/.linuxbrew/share/zsh/site-functions")
	fi

	if [[ "${PLATFORM}" == android_aarch64 ]]; then
		# Pure Prompt https://github.com/sindresorhus/pure
		fpath+=('/usr/local/lib/node_modules/pure-prompt/functions')

		zplug "lib/completion", from:oh-my-zsh           # Provides completion of dot directories

		ZSH_THEME=""
		zplug "mafredri/zsh-async", from:github
		zplug "sindresorhus/pure," use:pure.zsh, from:github, as:theme
	else
		zplug "lib/completion", from:oh-my-zsh           # Provides completion of dot directories
		zplug "jeffreytse/zsh-vi-mode"
		zplug "kheaactua/zsh-docker-aliases", from:github

		# Really fast theme, configured at the head and tail of zshrc
		zplug romkatv/powerlevel10k, as:theme, depth:1

		# Syntax highlighting bundle (syntax highlights commands as typing).
		zplug "zsh-users/zsh-syntax-highlighting", defer:3
	fi

	# Bookmarks in fzf
	if [[ "1" == "$(_exists fzf)" ]]; then
		zplug "urbainvaes/fzf-marks"
	fi

	# Install plugins if there are plugins that have not been installed
	if ! zplug check --verbose; then
		printf "Install? [y/N]: "
		if read -q; then
			echo; zplug install
		fi
	fi

	# Then, source plugins and add commands to $PATH
	zplug load
fi

if [[ "1" == $(_exists urxvt) ]]; then
	# Set the terminal to urxvt, for i3wm:
	export TERMINAL=urxvt
fi

if [[ "1" == "$(_exists nvim)" ]]; then
	export EDITOR=nvim
fi

# Autocompletion with an arrow-key driven interface
zstyle ':completion:*' menu select

# Uncomment if I want history shared across all terminals
# setopt histignorealldups sharehistory
# setopt no_share_history
# Trying these: https://stackoverflow.com/a/28647561/1861346

# This option works like APPEND_HISTORY except that new history lines are added
# to the $HISTFILE incrementally (as soon as they are entered), rather than
# waiting until the shell exits. The file will still be periodically re-written
# to trim it when the number of lines grows 20% beyond the value specified by
# $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
setopt inc_append_history

# Do not enter command lines into the history list if they are duplicates of
# the previous event.
setopt hist_ignore_dups

# Remove command lines from the history list when the first character on the
# line is a space, or when one of the expanded aliases contains a leading
# space. Only normal aliases (not global or suffix aliases) have this
# behaviour. Note that the command lingers in the internal history until the
# next command is entered before it vanishes, allowing you to briefly reuse or
# edit the line. If you want to make it vanish right away without entering
# another command, type a space and press return.
setopt hist_ignore_space

#unsetopt share_history

# This option allows me to tab complete branch names with the oh-my-zsh git aliases.
# http://zsh.sourceforge.net/Doc/Release/Options.html#index-COMPLETEALIASES
setopt nocomplete_aliases

# Ignore untracked files for showing status on prompt
export DISABLE_UNTRACKED_FILES_DIRTY=true

# Get number pad return/enter key to work
# bindkey "${terminfo[kent]}" accept-line

# Beginning/end of line
bindkey "^A" beginning-of-line
bindkey "\033[1~" beginning-of-line
bindkey "^E" end-of-line
bindkey "\033[4~" end-of-line
bindkey "\e[3~" delete-char
bindkey "^[0M" "^M"

# Outside of tmux, thre are some issue.  See the script at https://wiki.archlinux.org/title/Zsh#Key_bindings
bindkey -- "${${terminfo[khome]}}"      beginning-of-line
bindkey -- "${${terminfo[kend]}}"       end-of-line

# # "jeffreytse/zsh-vi-mode" "breaks" fzf history
# https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands
# Define an init function and append to zvm_after_init_commands
function _fix_zsh_init() {
	[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

	# Testing https://unix.stackexchange.com/a/631933/100689
	up-line-or-history() {
	  zle .set-local-history -n ${#WIDGET:#*global*}  # 0 iff $WIDGET == *global*
	  zle .up-line-or-history
	}
	zle -N up-line-or-history-local up-line-or-history
	zle -N up-line-or-history-global up-line-or-history

	# Up arrow
	bindkey '^[[A' up-line-or-history-local

	# # Alt + up arrow
	# bindkey '^[^[[A' up-line-or-history-global

	[[ "1" == "$(_exists direnv)" ]] && eval "$(direnv hook zsh)" 2> /dev/null
}
zvm_after_init_commands+=(_fix_zsh_init)

# Aliases
[ -e "${HOME}/.bash_aliases" ] && source "${HOME}/.bash_aliases"

# TODO It'd be nice if I could move this into a subfile or something
declare modules_enabled=0
declare -f module > /dev/null;
if [[ $? == 1 ]]; then
	modules_enabled=1;

	# Environmental Modules
	case "$0" in
	-sh|sh|*/sh)        modules_shell=sh   ;;
	-ksh|ksh|*/ksh)     modules_shell=ksh  ;;
	-zsh|zsh|*/zsh)     modules_shell=zsh  ;;
	-bash|bash|*/bash)  modules_shell=bash ;;
	esac

	export MODULEPATH=/usr/share/modules/modulefiles

	# #module() { eval `/usr/Modules/$MODULE_VERSION/bin/modulecmd $modules_shell $*`; }
	modulecmd=/usr/bin/modulecmd
	module() { eval `${modulecmd} $modules_shell $*`; }

	module use ${HOME}/.modulefiles
fi;

if [[ "khea" == "$(hostname)" ]]; then
	# Not using conan at the moment
	# export CONAN_SYSREQUIRES_MODE=disabled CONAN_SYSREQUIRES_SUDO=0

	# module load modules
	module load khea
	# module load bona

elif [[ "UGC14VW7PZ3" == "$(hostname)" ]]; then
	# Ford Desktop
	# module load ford/sync
	module load ford/quarry

	function fix-apt-sources() {
		# This is a little sketchy, but so is landscape renaming these all the
		# time, so manage the file list manually
		local -r ubuntu_version_code=$(detect_version_code)
		apt_sources=( \
			archive_uri-http_apt_llvm_org_${ubuntu_version_code}_-${ubuntu_version_code}.list.save \
			git-core-ubuntu-ppa-${ubuntu_version_code}.list.save
			github_git-lfs.list.save
			us-ubuntu.list.save
			signal-xenial.list.save
			microsoft-edge.list.save
			mozillateam-ubuntu-ppa-${ubuntu_version_code}.list.save
			deadsnakes-ubuntu-ppa-${ubuntu_version_code}.list.save
			sur5r-i3.list.save
			wireshark-dev-ubuntu-stable-${ubuntu_version_code}.list.save
			neovim-ppa-ubuntu-unstable-${ubuntu_version_code}.list.save
			wireshark-dev-ubuntu-stable-${ubuntu_version_code}.list.save
		)
		for f in ${apt_sources[@]}; do
			local abs_f=/etc/apt/sources.list.d/$f
			if [[ -e "${abs_f}" ]]; then
			  sudo mv "${abs_f}" ${abs_f/.save/};
			fi
		done
	}

	function check-eth() {
		for d in wls5 enp2s0 enp0s31f6; ip -4 a show dev $d

		echo "route:"
		ip route show | rg '10\.2\.0.\d*'
	}

elif [[ "sync-android" == "$(hostname)" ]]; then

	# module load sync

elif [[ "WGC1CV2JWQP13" == "$(hostname)" ]]; then
	# TODO hostname is wrong
	# Ford Laptop
	export WINHOME=/c/users/mruss100

	export DISPLAY=:0

	# Use Window's Docker
	# https://nickjanetakis.com/blog/setting-up-docker-for-windows-and-wsl-to-work-flawlessly
	export DOCKER_HOST=tcp://localhost:2375

	# module load ford/ford

elif [[ "$(uname -o)" = Android ]]; then
	# Likely in Termux
	# export DISPLAY=":1"
fi

# Load default python virtual env.
if [[ "undefined" == "${DEFAULT_PYTHON_VENV:-undefined}" ]]; then
	DEFAULT_PYTHON_VENV="default"
fi

# The issue is that tmux copies my path, which includes the python venv, so
# this test always passes once in tmux even when I'm not in a proper venv
declare INVENV=$(python3 -c "import sys; sys.stdout.write('1') if (hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)) else sys.stdout.write('0')")
if [[ 0 == "${INVENV}" ]]; then
	declare python_venv="${HOME}/.virtualenvs/${DEFAULT_PYTHON_VENV}"
	[ -e "${python_venv}/bin" ] && source "${python_venv}/bin/activate"
fi

# Cargo
[ -e "/${HOME}/.cargo/env" ] && source "/${HOME}/.cargo/env"

# vcpkg
[ -e "${VCPKG_ROOT}/scripts/vcpkg_completion.bash" ] && source "${VCPKG_ROOT}/scripts/vcpkg_completion.bash"

if [[ "1" == "$(_exists fd)" ]]; then
	declare fzfcmd=fd
elif [[ "1" == "$(_exists fdfind)" ]]; then
	declare fzfcmd=fdfind
fi
if [[ "undefined" == "${fzfcmd:-undefined}" ]]; then
	export FZF_DEFAULT_COMMAND="${fzfcmd} --type f"
fi
unset fzfcmd

export RIPGREP_CONFIG_PATH="${DOTFILES_DIR}/ripgreprc"

export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Dir colours
[ -e "${HOME}/.dir_colors/dircolors" ] && eval "$(dircolors ${HOME}/.dir_colors/dircolors)"

# copilot
[ -e "${HOME}/.copilot.dot" ] && source "${HOME}/.copilot.dot"

# Note: I use this less and less..
declare DEVEL_ENV="${HOME}/workspace/system-setup-scripts/devel/conanbuildenv.sh"
if [[ -e "${DEVEL_ENV}" ]]; then
	source "${DEVEL_ENV}"
else
	# echo "No development environment available, please run \`conan install\` to create ${DEVEL_ENV}"
fi

export FSB_CONFIG_FILE=/f/phoenix/phx-fsb/.fsb.yaml

# vim: sw=4 sts=0 ts=4 noet ff=unix :
