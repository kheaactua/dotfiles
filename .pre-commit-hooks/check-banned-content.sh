#!/usr/bin/env bash
# Block employer-specific / private content from a public repository.
#
# The patterns themselves are NOT stored in the repo (listing them here would
# defeat the purpose). They live in a local, gitignored file:
#   $BANNED_PATTERNS_FILE, or <repo root>/.banned-patterns
# Format: one extended regex per line, '#' comments and blank lines ignored,
# matched case-insensitively. See .banned-patterns.example.
#
# Paths listed in the tracked file .banned-content-allowlist are exempt from the
# file and history scans (author, identity and commit message checks still apply).
#
# Usage:
#   check-banned-content.sh files FILE...   scan file names and contents
#   check-banned-content.sh author          scan author/committer identities
#   check-banned-content.sh message FILE    scan a commit message file
#   check-banned-content.sh history [RANGE] scan every commit on every ref, or only
#                                           RANGE (CI); prints SHAs only, never matched text

set -u

mode="${1:-}"
shift || true

repo_root="$(git rev-parse --show-toplevel)"
patterns_file="${BANNED_PATTERNS_FILE:-${repo_root}/.banned-patterns}"

if [ ! -f "$patterns_file" ]; then
    echo "check-banned-content: patterns file not found: ${patterns_file}" >&2
    echo "  Copy .banned-patterns.example to .banned-patterns (or set BANNED_PATTERNS_FILE)." >&2
    exit 2
fi

# Strip comments/blank lines into a temp file usable with grep -f
compiled="$(mktemp)"
trap 'rm -f "$compiled"' EXIT
sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$patterns_file" > "$compiled"

if [ ! -s "$compiled" ]; then
    echo "check-banned-content: ${patterns_file} contains no patterns" >&2
    exit 2
fi

# Exempt paths: one repo-relative path per line in .banned-content-allowlist
allowlist_file="${repo_root}/.banned-content-allowlist"
allowed=()
exclude_specs=()
if [ -f "$allowlist_file" ]; then
    while IFS= read -r allowed_path; do
        allowed+=("$allowed_path")
        exclude_specs+=(":(exclude,literal)${allowed_path}")
    done < <(sed -e 's/[[:space:]]*#.*$//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$allowlist_file")
fi

is_allowed() {
    local candidate="${1#./}" entry
    for entry in "${allowed[@]+"${allowed[@]}"}"; do
        [ "$candidate" = "$entry" ] && return 0
    done
    return 1
}

status=0

case "$mode" in
    files)
        for f in "$@"; do
            [ -f "$f" ] || continue
            is_allowed "$f" && continue
            if printf '%s\n' "$f" | grep -Eiq -f "$compiled"; then
                echo "BANNED (file name): $f"
                status=1
            fi
            # -I skips binary files
            if hits="$(grep -EiIn -f "$compiled" -- "$f")"; then
                echo "BANNED (content): $f"
                printf '%s\n' "$hits" | cut -c1-200 | sed 's/^/    /'
                status=1
            fi
        done
        ;;
    author)
        for var in GIT_AUTHOR_IDENT GIT_COMMITTER_IDENT; do
            ident="$(git var "$var" 2> /dev/null)" || continue
            if printf '%s\n' "$ident" | grep -Eiq -f "$compiled"; then
                echo "BANNED (${var}): ${ident%% [0-9]*}"
                echo "    Fix with: git config user.email <personal address>"
                status=1
            fi
        done
        ;;
    history)
        # Output is limited to SHAs and categories so CI logs of a public repo
        # never reveal what was matched. An optional revision range (e.g.
        # base..head) limits the scan to new commits and to ADDED lines, so
        # commits that remove banned content are not flagged; with no range,
        # every commit on every ref is scanned.
        range_arg="${1:-}"
        if [ -n "$range_arg" ]; then
            if ! git rev-list "$range_arg" > /dev/null 2>&1; then
                echo "check-banned-content: invalid revision range: ${range_arg}" >&2
                exit 2
            fi
            revs=("$range_arg")
        else
            revs=(--all)
        fi
        combined="$(paste -sd'|' "$compiled")"
        report() { # label, then SHAs on stdin
            while read -r sha; do
                [ -n "$sha" ] && echo "BANNED (${1}): ${sha}" && status=1
            done
        }
        if [ -n "$range_arg" ]; then
            report "diff content" < <(git log -p -U0 --no-color --format='@@@%H' "${revs[@]}" -- . "${exclude_specs[@]+"${exclude_specs[@]}"}" |
                awk '/^@@@/ {sha = substr($0, 4); next} /^\+\+\+/ {next} /^\+/ {print sha "\t" substr($0, 2)}' |
                while IFS=$'\t' read -r sha line; do
                    printf '%s\n' "$line" | grep -Eiq -f "$compiled" && echo "$sha"
                done | sort -u)
        else
            report "diff content" < <(git log "${revs[@]}" -E -i -G "$combined" --format='%H' -- . "${exclude_specs[@]+"${exclude_specs[@]}"}")
        fi
        report "commit message" < <(git log "${revs[@]}" -E -i --grep "$combined" --format='%H')
        report "author" < <(git log "${revs[@]}" -E -i --author "$combined" --format='%H')
        report "committer" < <(git log "${revs[@]}" -E -i --committer "$combined" --format='%H')
        while IFS=$'\t' read -r sha path; do
            if printf '%s\n' "$path" | grep -Eiq -f "$compiled"; then
                echo "BANNED (file name): ${sha}"
                status=1
            fi
        done < <(git log "${revs[@]}" --diff-filter=AMR --name-only --format='@%H' -- . "${exclude_specs[@]+"${exclude_specs[@]}"}" |
            awk '/^@/ {sha = substr($0, 2); next} NF {print sha "\t" $0}')
        ;;
    message)
        msg_file="${1:?commit message file required}"
        if hits="$(grep -Ein -f "$compiled" -- "$msg_file")"; then
            echo "BANNED (commit message):"
            printf '%s\n' "$hits" | cut -c1-200 | sed 's/^/    /'
            status=1
        fi
        ;;
    *)
        echo "Usage: $0 {files FILE...|author|message FILE|history [RANGE]}" >&2
        exit 2
        ;;
esac

if [ "$status" -ne 0 ]; then
    echo >&2
    echo "This is a public repository: private/employer-specific content must be" >&2
    echo "kept in the dotfiles-secret submodule or another private location." >&2
fi
exit "$status"
