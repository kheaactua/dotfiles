#!/usr/bin/env fish

function update_dotfiles
    set -l cwd (dirname (realpath (status --current-filename)))
    cd $cwd; or echo "Could not change to $cwd"
    
    set -l check_file (set -q DOTFILES_DIR; and echo $DOTFILES_DIR; or dirname (realpath (status --current-filename)))/.last_check

    set -l now (date +%s)
    if not test -e $check_file
        echo 0 > $check_file
    end
    
    set -l last_update (cat $check_file)
    if test -z "$last_update"
        set last_update 0
    end

    # Three days
    set -l s (math $last_update + 259200)
    if test $now -gt $s
        echo "Checking for update to dotfiles...."
        set -l dotfiles_path (set -q DOTFILES_DIR; and echo $DOTFILES_DIR; or echo ~/dotfiles)
        env GIT_DIR=$dotfiles_path/.git GIT_WORK_TREE=$dotfiles_path/ git pull
        echo $now > $check_file
    else
        # echo "Not checking for update to dotfiles...."
    end
end

update_dotfiles
