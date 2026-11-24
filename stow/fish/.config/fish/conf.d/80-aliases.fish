# Fish aliases and functions translated from ~/.bash_aliases
# Note: Some bash-specific constructs have been adapted for fish

# Set DOTFILES_DIR if not already set
if not set -q DOTFILES_DIR
    set -gx DOTFILES_DIR "$HOME/dotfiles"
    if not test -e "$DOTFILES_DIR"
        # Fallback
        set -gx DOTFILES_DIR (realpath ~matt/dotfiles 2>/dev/null || echo "$HOME/dotfiles")
    end
end

# Helper function to check if a command exists (replaces _exists)
function _exists
    command -v $argv[1] >/dev/null 2>&1
end

# Basic aliases
alias df="df -h"
alias tclsh="rlwrap tclsh"
alias ip="ip --color"

# ls alias - conditional based on exa availability
if _exists exa
    alias ls="exa --header --long --sort=newest --tree --all --level=1 --ignore-glob='.git|.github|.clang-format|.gitignore'"
else
    alias ls="ls -lAhtrFG --color=auto"
end

# htop/ytop
if _exists ytop
    alias htop=ytop
end

# fd/fdfind handling
if not _exists fd; and _exists fdfind
    alias fd=fdfind
    set -gx FD_CMD fdfind
else
    set -gx FD_CMD fd
end

# FZF configuration
set -gx FZF_DEFAULT_COMMAND "$FD_CMD --type f --exclude .git --exclude out"

# bat/batcat configuration
set -gx BAT_PAGER "less -R -X -I --tabs=2"
if _exists batcat; and not _exists bat
    alias cat="batcat --paging=never"
    alias less=batcat
else if _exists bat
    alias cat=bat
    alias less=bat
else
    alias less="less -R -I --tabs=2"
end

# ag (the silver searcher)
if _exists ag
    alias ag="ag -iU --color-line-number 34 --color-path 31"
end

# nvim/vim configuration
if _exists nvim
    alias vi=nvim
    alias vim=nvim
    alias vimdiff="nvim -d"
    set -gx EDITOR nvim
else
    alias vi=vim
end

# grep with color
alias grep="grep --color=always --exclude-dir=.git"

# Yubikey authenticator
if test -e "$HOME/bin/yubioath-desktop-5.0.1-linux.AppImage"
    alias yubiAuth="$HOME/bin/yubioath-desktop-5.0.1-linux.AppImage"
end

# Git aliases - duplicates removed (covered by fisher plugin jhillyerd/plugin-git)
# Keeping only custom/unique aliases not in the plugin
alias rst="repo status"
alias gd="git dft"  # Custom: different from plugin's 'git diff'
alias rs="repo sync -j8 -q -c --no-tags"
alias rl="repo sync -j8 -q -c --no-tags"

# I prefer aliases to fish abbreviations
alias gco="git checkout"
alias grb="git rebase"

# GPG aliases
alias gpg-fixtty="gpg-connect-agent updatestartuptty /bye"
alias gpg-reload="gpg-connect-agent reloadagent /bye"

# Safety alias
alias reboot="echo no........"

# Simple wrappers, only defined when the tool is installed
if type -q rlwrap; and type -q sqlite3
    alias sqlite="rlwrap -a -c -i sqlite3"
end

if type -q rg
    alias rg="rg -L"
end

if test -x "/usr/lib/plexmediaserver/Plex Media Scanner"
    alias plex-refresh="/usr/lib/plexmediaserver/Plex\ Media\ Scanner -s -v"
end

# Git helper functions (git_current_remote lives in functions/)
function gcr
    git_current_remote
end

function git_current_branch
    git rev-parse --abbrev-ref HEAD 2>/dev/null
end

function git_set_default_remote
    set -l default_remote $argv[1]
    if test -z "$default_remote"
        set default_remote origin
    end
    git config remotes.default "$default_remote"
end

# Git aliases that use functions
alias gdr='git diff (git_current_remote)/(git_current_branch)'
alias gpsup='git push --set-upstream (git_current_remote) (git_current_branch)'
alias ggsup='git branch --set-upstream-to=(git_current_remote)/(git_current_branch)'
alias grsd=git_set_default_remote
alias grb="git rebase"

# Git fetch function
function gf
    set -l remote $argv[1]
    if test -z "$remote"
        set remote (git_current_remote)
    else
        set -e argv[1]
    end
    git fetch $remote $argv
end

# Vi git diff - open changed files in vi
function vigd
    set -l remote $argv[1]
    set -l branch $argv[2]

    if test -z "$remote"
        set remote (git_current_remote)
    end
    if test -z "$branch"
        set branch (git_current_branch)
    end

    set -l merge_base (git merge-base $branch $remote)
    vi -p (git diff --name-only $branch $merge_base)
end

# Curl download with resume
function cdl
    set -l output_dir /tmp

    if test "$argv[1]" = "-o"
        set output_dir $argv[2]
        set -e argv[1..2]
    end

    curl -o "$output_dir/"(basename $argv[1]) -LnC - $argv[1]
end

# WSL-specific
if command -v wslpath >/dev/null 2>&1
    if set -q WSL_VERSION; and test "$WSL_VERSION" != 0
        # Work-specific WSL paths (win_tmp) live in dotfiles-secret (fish-work/conf.d)

        # PowerShell aliases (if on WSL)
        alias pwsh="pwsh -ExecutionPolicy ByPass"
        alias powershell.exe="powershell.exe -ExecutionPolicy ByPass"
    end
end

# The work-specific `logs` function lives in dotfiles-secret (fish-work/functions)

# Source local fish aliases if they exist
if test -e ~/.config/fish/conf.d/aliases.local.fish
    source ~/.config/fish/conf.d/aliases.local.fish
end

# vim: ts=4 sts=4 sw=4 et ft=fish ff=unix :
