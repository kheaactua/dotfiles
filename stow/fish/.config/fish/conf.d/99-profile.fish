# Load hostname-specific profile
if set -q DOTFILES_SECRET_DIR
    # Add work functions directory to fish_function_path for autoloading
# TODO this should be "domain" dependent
    set -l work_functions_dir "$DOTFILES_SECRET_DIR/work/functions"
    if test -d "$work_functions_dir"
        contains "$work_functions_dir" $fish_function_path; or set -gp fish_function_path "$work_functions_dir"
    end

    # Source hostname-specific profile for setup/initialization
    set -l hostname_profile "$DOTFILES_SECRET_DIR/profiles/"(hostname)".fish"
    if test -f "$hostname_profile"
        source "$hostname_profile"
    end
end
