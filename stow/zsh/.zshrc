[[ "undefined" == "${DOTFILES_DIR:-undefined}" ]] && export DOTFILES_DIR="${HOME}/dotfiles"
[[ "undefined" == "${DOTFILES_SECRET_DIR:-undefined}" ]] && export DOTFILES_SECRET_DIR="${DOTFILES_DIR}/dotfiles-secret"

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

[[ -e "${DOTFILES_DIR}/rclib.dot" ]] && source "${DOTFILES_DIR}/rclib.dot"

if [[ -e "${DOTFILES_DIR}/agents.dot" ]]; then
	source "${DOTFILES_DIR}/agents.dot"
	check_agent_file

	if [[ 0 != "${WSL_VERSION}" ]]; then
		init_gpg_agent
	else
		init_keyring
	fi
fi

# Update the dotfiles repo to make sure we have all changes:
[[ -e "${DOTFILES_DIR}/doupdate.sh" ]] && "${DOTFILES_DIR}/doupdate.sh" > /dev/null

# Keep 1000 lines of history within the shell and save it to ${HOME}/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE="${HOME}/.zsh_history"

export LANG=en_US.UTF-8
export LC_TIME=en_GB.UTF-8

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Adjust PATH
[[ -e "${HOME}/.pathrc" ]] && source "${HOME}/.pathrc"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
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

	zplug "lib/completion", from:oh-my-zsh           # Provides completion of dot directories
	zplug "jeffreytse/zsh-vi-mode"
	zplug "kheaactua/zsh-docker-aliases", from:github

	# Really fast theme, configured at the head and tail of zshrc
	zplug "romkatv/powerlevel10k", as:theme, depth:1

	# Syntax highlighting bundle (syntax highlights commands as typing).
	zplug "zsh-users/zsh-syntax-highlighting", defer:3

	# Bookmarks in fzf
	_exists fzf && zplug "urbainvaes/fzf-marks"

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

if _exists urxvt; then
	# Set the terminal to urxvt, for i3wm:
	export TERMINAL=urxvt
fi

if _exists nvim; then
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

	_exists direnv && eval "$(direnv hook zsh)" 2> /dev/null
}
zvm_after_init_commands+=(_fix_zsh_init)

# Proxy functions
#
# Check if 'proxy-on' (function/alias/command) is not defined,
# AND if /etc/profile.d/proxy.sh exists (installed by toggle-proxy)
# This is explicit here because "non-login interactive shells" (shells that
# don't have an "l" in $-) do not source /etc/profile.d/* like login shells do.
if ! type -w proxy-on &>/dev/null && [ -f /etc/profile.d/proxy.sh ]; then
    source /etc/profile.d/proxy.sh
fi

# Aliases
[ -e "${HOME}/.bash_aliases" ] && source "${HOME}/.bash_aliases"

# This file is symlinked here after env modules is installed from source
declare module_profile_file="/etc/profile.d/modules.sh"
declare -f module > /dev/null || . "${module_profile_file}"
if [[ $? == 1 ]]; then
	# modules_enabled=1;

	# Environmental Modules
	# The module command is now installed in /etc/profile.d/env-modules.sh

	if [[ -e "${HOME}/.modulefiles" ]]; then
		module use "${HOME}/.modulefiles"
	fi
fi;

# Load host specific profile
[[ -e "${DOTFILES_SECRET_DIR}/profiles/$(hostname).zsh" ]] && source "${DOTFILES_SECRET_DIR}/profiles/$(hostname).zsh"

# Load default python virtual env.
[[ "undefined" == "${DEFAULT_PYTHON_VENV:-undefined}" ]] && DEFAULT_PYTHON_VENV="default"

# The issue is that tmux copies my path, which includes the python venv, so
# this test always passes once in tmux even when I'm not in a proper venv
declare INVENV=$(python3 -c "import sys; sys.stdout.write('1') if (hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)) else sys.stdout.write('0')")
if [[ 0 == "${INVENV}" ]]; then
	declare python_venv="${HOME}/.virtualenvs/${DEFAULT_PYTHON_VENV}"
	[ -e "${python_venv}/bin" ] && source "${python_venv}/bin/activate"
fi

# Cargo
[ -e "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"

# nvm (node.js)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# vcpkg
[ -e "${VCPKG_ROOT}/scripts/vcpkg_completion.bash" ] && source "${VCPKG_ROOT}/scripts/vcpkg_completion.bash"

if _exists fd; then
	declare fzfcmd=fd
elif _exists fdfind; then
	declare fzfcmd=fdfind
fi
if [[ "undefined" == "${fzfcmd:-undefined}" ]]; then
	export FZF_DEFAULT_COMMAND="${fzfcmd} --type f"
fi
unset fzfcmd

export RIPGREP_CONFIG_PATH="${HOME}/.config/ripgrep/ripgreprc"

export SDKMAN_DIR="${HOME}/.sdkman"
[[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]] && source "${HOME}/.sdkman/bin/sdkman-init.sh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

[ -e "${HOME}/.dir_colors/dircolors" ] && eval "$(dircolors ${HOME}/.dir_colors/dircolors)"

[ -e "${HOME}/.copilot.dot" ] && source "${HOME}/.copilot.dot"

if _exists zoxide; then
	eval "$(zoxide init zsh)"
	[[ -e "${HOME}/.config/zoxide/zoxide.zsh" ]] && source "${HOME}/.config/zoxide/zoxide.zsh"
fi

# Set terminal to kitty if it exists, this should be respected by i3-sensible-terminal
_exists kitty && export TERMINAL=kitty

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# vim: sw=4 sts=0 ts=4 noet ff=unix :
