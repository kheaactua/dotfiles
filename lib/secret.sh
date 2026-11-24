#!/bin/bash
# Support for the private dotfiles-secret-<domain> repositories (home, work,
# ccnab, ...).  They are cloned by hand next to this repo and are never
# submodules; this file only installs whichever ones are present.
#
# Each repository may contain:
#   host-patterns   Globs, one per line, matched against `hostname`.  The
#                   repository is only installed when one matches.  No file
#                   means "always".
#   templates.map   `<template> <target> [mode]` per line.  Each template is
#                   rendered by scripts/populate_template.py (which pulls
#                   [pass:...] tokens from the password manager).  The target
#                   is relative to the repository, or starts with `~/` or
#                   `@dotfiles/`.
#   install.sh      Optional hook for work specific to that repository.  It
#                   receives DOTFILES_DIR and DOTFILES_SECRET_DIR (the
#                   repository itself) in its environment.
#   stow/<pkg>      Stow packages, installed into $HOME.
#   ssh/config      Shared SSH config, included from ~/.ssh/config.
#   ssh/config.<domain>
#                   SSH config for the whole repository (linked into ~/.ssh/config.d/).
#   ssh/config.$(hostname)
#                   Host specific SSH config (linked into ~/.ssh/config.d/).
#   gnupg/sshcontrol
#                   Merged with every other repository's into ~/.gnupg/sshcontrol.
#   keys/ssh/*      Chmod'ed 600.
#
# A key belongs to the repository of the machine that uses it, and a
# repository must never refer to another repository's paths.
#
# This file is also sourced from interactive shells, so it must work in bash
# and zsh.

function dotfiles_secret_repos()
{
  find "${DOTFILES_DIR:-${HOME}/dotfiles}" -mindepth 1 -maxdepth 1 -type d -name 'dotfiles-secret-*' | sort
}

function dotfiles_secret_domain()
{
  local name
  name="$(basename "${1}")"
  echo "${name#dotfiles-secret-}"
}

function dotfiles_secret_repo_matches_host()
{
  local -r repo="${1}"
  local -r host="${2:-$(hostname)}"
  local -r patterns_file="${repo}/host-patterns"

  [[ -f "${patterns_file}" ]] || return 0

  local pattern
  while IFS= read -r pattern || [[ -n "${pattern}" ]]; do
    pattern="${pattern%%#*}"
    pattern="${pattern//[[:space:]]/}"
    [[ -z "${pattern}" ]] && continue
    # shellcheck disable=SC2053
    [[ "${host}" == ${pattern} ]] && return 0
  done < "${patterns_file}"

  return 1
}

function dotfiles_secret_active_repos()
{
  local repo
  for repo in $(dotfiles_secret_repos); do
    if dotfiles_secret_repo_matches_host "${repo}" "${1:-}"; then
      echo "${repo}"
    fi
  done
}

function dotfiles_secret_render_templates()
{
  local -r repo="${1}"
  local -r home="${2:-${HOME}}"
  local -r dotfiles_dir="${DOTFILES_DIR:-${HOME}/dotfiles}"
  local -r map="${repo}/templates.map"

  [[ -f "${map}" ]] || return 0

  local template target mode
  while read -r template target mode; do
    [[ -z "${template}" || "${template}" == \#* ]] && continue

    target="${target/#\~/${home}}"
    target="${target/#@dotfiles/${dotfiles_dir}}"
    [[ "${target}" == /* ]] || target="${repo}/${target}"

    # A previous render may be read-only
    rm -f "${target}"
    mkdir -p "$(dirname "${target}")"
    if "${dotfiles_dir}/scripts/populate_template.py" "${repo}/${template}" "${target}"; then
      [[ -n "${mode}" ]] && chmod "${mode}" "${target}"
    else
      echo "WARNING: could not render ${template} from $(basename "${repo}")" >&2
    fi
  done < "${map}"
}

function dotfiles_secret_link_ssh_config()
{
  local -r repo="${1}"
  local -r home="${2:-${HOME}}"
  local -r domain="$(dotfiles_secret_domain "${repo}")"

  mkdir -p "${home}/.ssh/config.d"

  # config.<domain> applies wherever the repository is installed;
  # config.<hostname> only on that host.
  local source_config link_name
  for link_name in "${domain}" "$(hostname)"; do
    source_config="${repo}/ssh/config.${link_name}"
    [[ -e "${source_config}" ]] || continue
    ln -sf "${source_config}" "${home}/.ssh/config.d/${domain}-${link_name}"
  done
}

function dotfiles_secret_stow()
{
  local -r repo="${1}"
  local -r home="${2:-${HOME}}"

  [[ -d "${repo}/stow" ]] || return 0

  local pkg_dir
  for pkg_dir in "${repo}"/stow/*/; do
    # Two repositories may stow into the same target.  Whichever installs
    # first wins; the rest is reported, not fatal.
    stow -d "${repo}/stow" -t "${home}" "$(basename "${pkg_dir}")" ||
      echo "WARNING: stow conflict installing $(basename "${pkg_dir}") from $(basename "${repo}")" >&2
  done
}

function dotfiles_secret_fix_permissions()
{
  local -r repo="${1}"

  find "${repo}" -path "${repo}/.git" -prune -o -type f -path '*/keys/ssh/*' -exec chmod 600 {} +
  chmod g-rwx,o-rwx "${repo}"
}

function dotfiles_secret_merge_sshcontrol()
{
  local -r home="${1:-${HOME}}"
  local -r target="${home}/.gnupg/sshcontrol"

  local -a sources=()
  local repo
  for repo in $(dotfiles_secret_active_repos); do
    [[ -f "${repo}/gnupg/sshcontrol" ]] && sources+=("${repo}/gnupg/sshcontrol")
  done

  if [[ "${#sources[@]}" -eq 0 ]]; then
    return 0
  fi

  mkdir -p "${home}/.gnupg" && chmod 700 "${home}/.gnupg"
  # A symlink from an older layout would write back into a repository
  rm -f "${target}"
  {
    echo "# Generated by dotfiles_secret_merge_sshcontrol from dotfiles-secret-*/gnupg/sshcontrol."
    echo "# Edit those files; changes made here are overwritten."
    cat "${sources[@]}" | awk 'NF && !seen[$0]++'
  } > "${target}"
  chmod 600 "${target}"
}

function dotfiles_secret_run_hook()
{
  local -r repo="${1}"
  local -r home="${2:-${HOME}}"

  [[ -x "${repo}/install.sh" ]] || return 0

  DOTFILES_DIR="${DOTFILES_DIR:-${HOME}/dotfiles}" DOTFILES_SECRET_DIR="${repo}" "${repo}/install.sh" "${home}"
}

function dotfiles_secret_install_all()
{
  local -r home="${1:-${HOME}}"

  local repo
  for repo in $(dotfiles_secret_repos); do
    if ! dotfiles_secret_repo_matches_host "${repo}"; then
      echo "Skipping $(basename "${repo}"): no host-patterns entry matches $(hostname)"
      continue
    fi

    echo "Installing $(basename "${repo}")"
    dotfiles_secret_run_hook "${repo}" "${home}"
    dotfiles_secret_render_templates "${repo}" "${home}"
    dotfiles_secret_link_ssh_config "${repo}" "${home}"
    dotfiles_secret_stow "${repo}" "${home}"
    dotfiles_secret_fix_permissions "${repo}"
  done

  dotfiles_secret_merge_sshcontrol "${home}"

  [[ -d "${home}/.ssh" ]] && chmod 700 "${home}/.ssh"
  [[ -e "${home}/.netrc" ]] && chmod 600 "${home}/.netrc"
  [[ -e "${home}/.modulefiles/tokens" ]] && chmod 600 "${home}/.modulefiles/tokens"
  return 0
}

# vim: ts=2 sw=2 sts=0 ff=unix expandtab ft=sh :
