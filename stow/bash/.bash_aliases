if [[ "undefined" == "${DOTFILES_DIR:-undefined}" ]]; then
	export DOTFILES_DIR="${HOME}/dotfiles"
	if [[ ! -e "${DOTFILES_DIR}" ]]; then
		# Just guess
		export DOTFILES_DIR=$(realpath -- ~matt/dotfiles)
	fi
fi
if ! typeset -f _exists > /dev/null ; then
	if [[ -e "${DOTFILES_DIR}/rclib.dot" ]]; then
		source "${DOTFILES_DIR}/rclib.dot"
	fi
fi

alias df="df -h"
alias tclsh="rlwrap tclsh"
alias ip="ip --color"

if [[ "$(_exists exa)" == 1 ]]; then
   alias ls="exa --header --long --sort=newest --tree --all --level=1 --ignore-glob=\".git|.github|.clang-format|.gitignore\""
else
   alias ls="ls -lAhtrFG --color=auto"
fi
if [[ "$(_exists htop)" == 1 ]]; then
   alias htop=ytop
fi
if [[ "$(_exists dust)" == 1 ]]; then
   alias du=dust
fi
if [[ "$(_exists fd)" == 0 && "$(_exists fdfind)" == 1 ]]; then
   alias fd=fdfind
   export FD_CMD=fdfind
fi
export FZF_DEFAULT_COMMAND="${FD_CMD:-fd} --type f --exclude .git --exclude out"
declare -x BAT_PAGER="less -R -X -I --tabs=2"
if [[ "$(_exists bat)" == 0 && $(_exists batcat) == 1 ]]; then
   alias cat=batcat
   alias less=batcat
elif [[ "$(_exists bat)" == 1 ]]; then
   alias cat=bat
else
   alias less="less -R -I --tabs=2"
fi
if [[ "$(_exists ag)" == 1 ]]; then
   alias ag="ag -iU --color-line-number 34 --color-path 31"
fi
if [[ $(_exists nvim) == 1 ]]; then
	alias vi=nvim
	alias vimdiff="nvim -d"
else
	alias vi=vim
fi

alias grep="grep --color=always --exclude-dir={.git}"

# Test for Yubi
if [[ -e "${HOME}/bin/yubioath-desktop-5.0.1-linux.AppImage" ]]; then
   alias yubiAuth="${HOME}/bin/yubioath-desktop-5.0.1-linux.AppImage"
fi

function git_current_remote() {
	# This is a hack for now, soon this should be changes to detect if we're in
	# a repo workspace and use the python manifest tools to select the proper
	# tool.
	# Currently this returns this first remote
	grc=$(git config remotes.default)

	if [[ "" != "${grc}" ]]; then
		echo "${grc}"
	else
		echo $(git remote | head -n 1)
	fi
}

function gcr() {
	git_current_remote
}

# A better test would be whether I'm running zsh..
if [[ $0 == *bash || "" != "${TRUE_HOST}" || "$(hostname)" == *siteground* ]]; then
   alias ga="git add"
   alias gb="git branch"
   alias gba="git branch -vr"
   alias gco="git checkout"
   alias gcp="git cherry-pick"
   alias gl="git pull"
   alias gp="git push"
   alias gsta="git stash"
   alias gstp="git stash pop"
   alias grh="git reset HEAD"
   alias grb="git rebase"
   alias grbc="git rebase --continue"
   alias grv="git remote -v"
fi
if [[ "${HOME}" == *com.termux* ]]; then
   alias vi="nvim"
   alias vim="nvim"
fi
alias gmt="git mergetool"
alias gst="git status -uno -sb"
alias rst="repo status"
alias gd="git diff -w --color"
alias gdrm='git diff $(git_current_remote)/master'
alias gdr='git diff $(git_current_remote)/$(git_current_branch)'
alias rs="repo sync -j8 -q -c --no-tags"
alias rl="repo sync -j8 -q -c --no-tags"
alias gpsup='git push --set-upstream $(git_current_remote) $(git_current_branch)'
alias ggsup='git branch --set-upstream-to=$(git_current_remote)/$(git_current_branch)'

if [[ "$(alias gf 2>/dev/null)" != "" ]]; then
	unalias gf
fi
function gf()
{
	local -r remote=${1:-$(git_current_remote)}
	if [[ "" != "$1" ]]; then
		shift
	fi

	git fetch "${remote}" $@
}


function vigd() {
	local remote=${1:-$(git_current_remote)}; shift
	local branch=${2:-$(git_current_branch)}
	vi -p $(git diff --name-only "${branch}" "$(git merge-base "${branch}" "${remote}")")
}

# alias glog="git log --follow --name-status"

[[ -e ~/.bash_aliases.local ]] && source ~/.bash_aliases.local

alias vm="ssh vagrant@127.0.0.1 -p 2222"

# GPG aliases.. Needed until I understand GPG better
alias gpg-fixtty="gpg-connect-agent updatestartuptty /bye"
alias gpg-reload="gpg-connect-agent reloadagent /bye"

# Windows Terminal Settings (TODO I think this moved again, settings.json now or something)
# alias edit_windows_terminal="vi /c/Users/matthew.russell/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/profiles.json"

alias pwsh="pwsh -ExecutionPolicy ByPass"
alias powershell.exe="powershell.exe -ExecutionPolicy ByPass"


alias reboot="echo no........"

alias plex-refresh="/usr/lib/plexmediaserver/Plex\ Media\ Scanner -s -v"

# https://superuser.com/a/999132/184123
alias sqlite="rlwrap -a -c -i sqlite3"

function cdl() {
	# alias cdl='curl -LnOC -'
	if [[ "-o" == "$1" ]]; then
		shift
		output_dir=$1
		shift
	else
		output_dir="/tmp"
	fi
	curl -o "${output_dir}/$(basename $1)" -LnC - "$1"
	# echo curl -LnOC - "$1"
}

if [[ $(_exists wslpath) == 1 ]]; then
	if [[ "${WSL_VERSION}" != 0 ]]; then
		# Will have to deal with the username if I start using the WSL in more places..
		alias win_tmp=$(wslpath -u "C:\\Users\\mruss100\\AppData\\Local\\Temp")
	fi;
fi

# vim: ts=3 sts=0 sw=3 noet ft=sh ff=unix :
