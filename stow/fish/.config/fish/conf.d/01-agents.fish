# Initialize SSH/GPG agents
if test -e "$DOTFILES_DIR/agents.fish"
    source "$DOTFILES_DIR/agents.fish"
    check_agent_file
    init_keyring  # Use init_gpg_agent if you prefer GPG agent for SSH
end
