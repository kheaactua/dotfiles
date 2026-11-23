#!/bin/bash

function clean_ssh_env()
{
    unset SSH_AGENT_PID
    unset SSH_AUTH_SOCK
    unset SSH_AUTH_AGENT
}

function check_agent_file()
{
  local -r ssh_auth_sock="${1:-${SSH_AUTH_SOCK}}"

  # Verify the SSH agent file is correct.  If docker starts before the agent
  # starts, than $SSH_AUTH_SOCK will be have the wrong ownership
  if [[ -z "${ssh_auth_sock}" ]]; then
    # SSH_AUTH_SOCK is not set, so it can't be pointing at the wrong file
    return 0
  fi

  if [[ ! -e "${ssh_auth_sock}" ]]; then
    # The file doesn't exist, so it can't be pointing at the wrong file/dir
    return 0
  fi

  if [[ -S "${ssh_auth_sock}" ]]; then
    # local -r owner=$(stat -c %U:%G "${SSH_AUTH_SOCK}")
    local -r owner=$(stat -c %U "${ssh_auth_sock}")
    if [[ "${owner}" != "${USER}" ]]; then
      echo "SSH_AUTH_SOCK=${ssh_auth_sock} has the wrong ownership: ${owner}"
      return 1
    fi
  else
    echo "\e[32mSSH_AUTH_SOCK=${ssh_auth_sock} is not a socket\e[0m"
    return 1
  fi
}

function gen_agent_sock_file_name()
{
  echo "/run/user/$(id -u)/ssh-agent.$(hostname).sock"
}

function init_gpg_agent()
{
  _exists gpgconf || return 1

  # Attempting to use gpg-agent over ssh-agent.  Do this before doupdate or else
  # it'll prompt for the SSH passphrase rather than the keyring passphrase
  # https://eklitzke.org/using-gpg-agent-effectively
  #
  # Also, according to
  # https://wiki.archlinux.org/title/SSH_keys#Start_ssh-agent_with_systemd_user
  # , we should probably check whether SSH_CONNECTION is set, and not set
  # SSH_AUTH_SOCK if it is.
  if [[ "undefined" == "${SSH_AUTH_SOCK:-undefined}" ]]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  fi
  export GPG_TTY="$(tty)"
  gpg-connect-agent updatestartuptty /bye >/dev/null
}

function ssh_agent_running()
{
  pgrep -x ssh-agent > /dev/null
}

function init_ssh_agent()
{
  local debug=0
  if [[ "${1}" == "debug" ]]; then
    debug=1
  fi;

  # From eval `ssh-agent`
  # eval $(ssh-agent)

  local ssh_auth_sock="$(gen_agent_sock_file_name)"

  pkill ssh-agent
  unset SSH_AUTH_SOCK
  unset SSH_AGENT_PID
  unset SSH_AUTH_AGENT

  if ! $(check_agent_file "${ssh_auth_sock}"); then
    echo "SSH_AUTH_SOCK=${ssh_auth_sock} is problematic"
    return 1
  fi

  if ! ssh_agent_running && [ -e "${ssh_auth_sock}" ]; then
    if [[ "${debug}" -eq 1 ]]; then
      echo "ssh-agent isn't running, but ${ssh_auth_sock} exists, removing it"
    fi
    rm -f "${ssh_auth_sock}"
  fi

  ssh-add -l 2>/dev/null >/dev/null
  if [ $? -ge 2 ]; then
    if [[ "${debug}" -eq 1 ]]; then
      ssh-agent -d -a "${ssh_auth_sock}" 2>&1 | tee -a /tmp/ssh-agent.log
    else
      ssh-agent -a "${ssh_auth_sock}" >/dev/null
    fi
  fi

  local -r ssh_agent_pid="$(pidof ssh-agent)"
  if [[ -z "${ssh_agent_pid}" ]]; then
    echo "Failed to start ssh-agent"
    clean_ssh_env
    return 1
  fi

  export SSH_AGENT_PID="$(pidof ssh-agent)"
  export SSH_AUTH_SOCK="${ssh_auth_sock}"
  export SSH_AUTH_AGENT="${ssh_auth_sock}"

  if [[ $debug -eq 1 ]]; then
    echo "SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
    echo "SSH_AUTH_AGENT=${SSH_AUTH_AGENT}"
    echo "SSH_AGENT_PID=${SSH_AGENT_PID}"
  fi

  # See https://rabexc.org/posts/pitfalls-of-ssh-agents might have a better way to do this
}

function init_keyring() {
  clean_ssh_env

  local gkversion;
  # Get the major version
  gkversion=$(/usr/bin/gnome-keyring-daemon --version 2>/dev/null | sed -n 's/.*gnome-keyring[^\s]*\s\(\([0-9]\+\)\.[0-9]\+\).*/\2/p')

  if [[ $gkversion -gt 46 ]]; then
    # I seem to need to do this on khea, gnome-keyring-daemon returns
    # GNOME_KEYRING_CONTOL rather than SSH_AUTH_SOCK
    # https://www.reddit.com/r/archlinux/comments/1avuxcw/psa_gnome_keyring_1461_may_break_your_sshagent/
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
  else
    eval "$(/usr/bin/gnome-keyring-daemon --start --components=ssh 2>/dev/null)"
    export SSH_AUTH_AGENT="${SSH_AUTH_SOCK}"
    export SSH_AUTH_SOCK
  fi

  # Not sure if I need GPG_TTY anymore
  # export GPG_TTY="$(tty)"
  # Pretty sure SSH_AGENT_PID was never needed
  # export SSH_AGENT_PID="$(pidof gnome-keyring-daemon)"
}

# vim: sw=4 sts=0 ts=4 noet ff=unix ft=sh :
