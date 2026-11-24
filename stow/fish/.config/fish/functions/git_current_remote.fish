function git_current_remote --description "Print the default git remote (remotes.default, else the first remote)"
    # This is a hack for now; eventually it should detect a repo workspace and
    # use the manifest tools to pick the right remote.
    set -l grc (git config remotes.default 2>/dev/null)

    if test -n "$grc"
        echo $grc
    else
        git remote | head -n 1
    end
end
