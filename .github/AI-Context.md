# AI Context for Dotfiles Repository

## What is this repository?

This is a personal dotfiles repository that manages system configuration files across multiple Linux machines using GNU Stow. It contains configurations for various applications and tools to maintain a consistent development environment.

## Repository Structure

- **stow/** - Main configuration directory organized by application
  - Each subdirectory contains configs for a specific tool (e.g., fish, i3, neovim, tmux, etc.)
  - Uses GNU Stow to symlink configurations to the home directory
- **bin/** - Personal scripts and utilities
- **scripts/** - Automation and setup scripts
- **dotfiles-secret/** - Git submodule for sensitive/private configurations
- **.ai/** - Tracking directory for AI-assisted modifications

## Key Technologies

- **Shell**: Fish shell (primary), with some bash scripts
- **Window Manager**: i3wm with custom configurations
- **Terminal**: Kitty
- **Editor**: Neovim with custom config
- **Multiplexer**: Tmux and Zellij
- **Theme**: Solarized color scheme across applications

## Management Approach

- Uses **GNU Stow** for symlink management
- Supports multiple machines with machine-specific configs
- Git submodules for sensitive data separation
- Modular design - can stow individual applications as needed

## When Making Changes

1. Understand that configs are in `stow/<app>/.config/<app>/` structure
2. Test changes don't break existing functionality
3. Consider cross-machine compatibility
4. Document AI-assisted changes in `.ai/` directory
5. Respect existing coding styles (especially Fish shell syntax)
6. Be aware of dependencies between configurations

## Common Patterns

- Machine-specific configs often use hostnames in filenames (e.g., `khea.i3`)
- Fish shell functions in `stow/fish/.config/fish/functions/`
- i3 configs are split into numbered files that get concatenated
- Environment modules system for managing different environments

## AI Assistance Guidelines

- Always check if changes affect multiple machines
- Test fish shell syntax (different from bash!)
- Don't modify ignored files (see .gitignore)
- Preserve existing customizations and personal preferences
- Document changes in `.ai/` directory with date and description
