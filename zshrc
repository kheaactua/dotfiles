# Update the dotfiles repo to make sure we have all changes:
~/dotfiles/doupdate.sh

# Uncomment if I want history shared across all terminals
# setopt histignorealldups sharehistory
setopt no_share_history
#unsetopt share_history

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)


source ~/dotfiles/antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
# These all take about a second to load
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
# Themes: robbyrussell, daveverwer candy clean pygalion, etc..
antigen theme blinks

# Tell antigen that you're done.
antigen apply

# Use VIM wherever possible.  The latter fixes colours in non-gvim
export EDITOR=vim
export TERM=xterm-256color

# This doesn't seem to be applying when at the top
setopt no_share_history

# Autocompletion with an arrow-key driven interface
zstyle ':completion:*' menu select

# Autocompletion of command line switches for aliases
setopt completealiases

# Ignore untracked files for showing status on prompt
export DISABLE_UNTRACKED_FILES_DIRTY=true

# Get number pad return/enter key to work
#bindkey "${terminfo[kent]}" accept-line

###########################################################
# Define some keys ( http://zshwiki.org/home/zle/bindkeys )
#
# Not sure if these are still needed.  I had only implemented
# them on dena
# #
typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# Setting up more key bindings
bindkey '' beginning-of-line
bindkey '' end-of-line
bindkey '' history-incremental-search-backward
bindkey "${key[Delete]}" delete-char
###########################################################


# Adjust the path
source ~/.pathrc

# Alises
if [ -e ~/.bash_aliases ]; then
	source ~/.bash_aliases
fi

# Dir colours, used by solarized
if [ -x /usr/bin/dircolors ]; then
	test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

local -a dirs;
dirs=(bin utils .linuxbrew/bin);
for d in $dirs; do
	dir=~/${d};
	if [[ -e $dir ]]; then
		export PATH=~/${dir}:${PATH}
	fi;
done

declare -f module > /dev/null;
if [[ $? == 1 ]]; then
	# Environmental Modules
	case "$0" in
	-sh|sh|*/sh)	modules_shell=sh ;;
	-ksh|ksh|*/ksh)	modules_shell=ksh ;;
	-zsh|zsh|*/zsh)	modules_shell=zsh ;;
	-bash|bash|*/bash)	modules_shell=bash ;;
	esac

	export MODULEPATH=/usr/share/modules/modulefiles

	#module() { eval `/usr/Modules/$MODULE_VERSION/bin/modulecmd $modules_shell $*`; }
	if [[ $(hostname) == "pontus.cee.carleton.ca" ]]; then
		modulecmd=/usr/local/Modules/3.2.9/bin/modulecmd
	else
		modulecmd=/usr/bin/modulecmd
	fi
	module() { eval `${modulecmd} $modules_shell $*`; }

	#module use ${HOST}/.modulefiles
fi;


if [[ $(hostname) == "khea" ]]; then
	module use /usr/local/Modules/default/modulefiles/
	module load modules

	module load mayofest
	module load diplomacy
	module load bona
	module load youtuber
	#module load gys

	# Adjust the path
	export PATH="${HOME}/utils:$PATH"

	# Ruby I think?
	export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
elif [[ $(hostname) == "pof" || $(hostname) == "tinder" ]]; then
	module use /usr/share/modules/modulefiles
	module load modules

	module load neptec 3dri

	# Set up ninja tab completion:
	if [[ -e /usr/share/zsh/functions/Completion/_ninja ]]; then
		source /usr/share/zsh/functions/Completion/_ninja
	fi;

elif [[ $(hostname) = dena* ]]; then
	# This should be a system "module use"!
	module use /cm/shared/denaModules

	# defaults
	module load shared modules

	# Development
	export PGI_DEFAULT=2015
	module load pgi slurm brew

	if [[ $(hostname) == "dena" ]]; then
		# Admin modules
		module load cmsh cmgui
	fi

elif [[ "$(hostname)" == "pontus.cee.carleton.ca" ]]; then
	module load pontus
fi;

# vim: sw=4 sts=0 ts=4 noet ffs=unix :
