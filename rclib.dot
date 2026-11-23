function _exists() {
    local bin=${1}

    if [[ -z "${bin}" ]]; then
        echo "Usage: _exists <binary_name>"
        return 1
    fi

    if [ -n "${ZSH_VERSION}" ]; then
        local -r _not_found_pattern="not found$"
        if [[ "$(which "${bin}" 2> /dev/null)" =~ ${_not_found_pattern} ]]; then
            return 1
        else
            return 0
        fi
    else
        which "${bin}" > /dev/null 2>&1
        if [[ 0 != "$?" ]]; then
            return 1
        else
            return 0
        fi
    fi
}

if [[ -z "$BASH_VERSION" && -n "${ZSH_VERSION}" ]]; then
    # Helpful arm-ldd function
    # (don't think I've used this in 4 years)
    if _exists patchelf; then
        func="function arm-ldd() { patchelf --print-needed $1 }"
    else
        func="function arm-ldd() { readelf -d $1 | grep \"\(NEEDED\)\" | sed -r \"s/.*\[(.*)\]/\1/\" }"
    fi
    eval $func
fi

# This is done in an annoying way because once in a pipe, any sourceing or even
# variable setting seems to be scope locked to that block
declare -a search_dirs
if [[ -e "${DOTFILES_DIR}/dotfiles-secret" ]]; then
    search_dirs+=("${DOTFILES_DIR}/dotfiles-secret")
fi
if [[ -e "${DOTFILES_DIR}/scripts" ]]; then
    search_dirs+=("${DOTFILES_DIR}/scripts")
fi
if [[ "${#search_dirs[@]}" -gt 0 ]]; then
    declare files_str=$(find ${search_dirs[@]} -type f -name '*.dot' -print |
    while IFS= read -r file; do
        echo $file
    done)
    declare -a files=($(echo ${files_str}))

    for file in ${files[@]}; do
        source ${file}
    done;

    unset files
    unset files_str
    unset search_dirs
fi

# vim: ts=4 sw=4 sts=0 expandtab
