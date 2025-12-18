# Load default python virtual env
if not set -q DEFAULT_PYTHON_VENV
    set -gx DEFAULT_PYTHON_VENV "default"
end

# Check if we're in a virtual environment
set -l invenv (python3 -c "import sys; sys.stdout.write('1') if (hasattr(sys, 'real_prefix') or (hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix)) else sys.stdout.write('0')" 2>/dev/null)
if test "$invenv" = "0"
    set -l python_venv "$HOME/.virtualenvs/$DEFAULT_PYTHON_VENV"
    if test -e "$python_venv/bin/activate.fish"
        source "$python_venv/bin/activate.fish"
    end
end
