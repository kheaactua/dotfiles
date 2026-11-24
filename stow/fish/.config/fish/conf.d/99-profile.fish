# Load the functions and hostname-specific profile of each dotfiles-secret-<domain>
# repository whose host-patterns match this host (no host-patterns: always).
set -l host (hostname)
for repo in $DOTFILES_DIR/dotfiles-secret-*
    test -d "$repo"; or continue

    set -l matches 1
    if test -f "$repo/host-patterns"
        set matches 0
        for pattern in (string replace -r '#.*' '' < "$repo/host-patterns" | string trim)
            test -n "$pattern"; or continue
            if string match -q -- "$pattern" "$host"
                set matches 1
                break
            end
        end
    end
    test $matches -eq 1; or continue

    if test -d "$repo/functions"
        contains "$repo/functions" $fish_function_path; or set -gp fish_function_path "$repo/functions"
    end

    if test -f "$repo/profiles/$host.fish"
        source "$repo/profiles/$host.fish"
    end
end
