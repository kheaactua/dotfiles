#!/usr/bin/env python3
"""
Python replacement for _dotfiles_secret_populate_template shell function.

This script reads a template file, finds all [pass:...] tokens, queries
the pass password manager for values, and replaces the tokens with the values.

Usage:
    populate_template.py <template_file> <target_file>

Token format:
    [pass:<key_path>]           - Get first line of pass entry
    [pass:<key_path>:<key>]     - Get specific key from pass entry
"""

import sys
import os
import re
import subprocess
from pathlib import Path


def parse_pass_token(path_and_key):
    """
    Parse a pass token into key_path and optional_key.

    Args:
        path_and_key: String like "path/to/key" or "path/to/key:keyname"

    Returns:
        tuple: (key_path, optional_key)
    """
    # Check if there's a colon (meaning we might have an optional key)
    if ':' in path_and_key:
        # Split on the last colon
        parts = path_and_key.rsplit(':', 1)
        key_path = parts[0]
        optional_key = parts[1]

        # Make sure optional_key doesn't contain / (which would mean it's part of the path)
        if '/' in optional_key or not optional_key:
            # The colon is part of the path or empty, treat as no optional key
            key_path = path_and_key.rstrip(':')
            optional_key = ""
    else:
        # No colon at all
        key_path = path_and_key
        optional_key = ""

    return key_path, optional_key


def query_pass(key_path, optional_key=""):
    """
    Query the pass password manager for a value.

    Args:
        key_path: Path to the pass entry
        optional_key: Optional key to extract from the entry

    Returns:
        str: The value from pass, or empty string on error
    """
    try:
        result = subprocess.run(
            ['pass', key_path],
            capture_output=True,
            text=True,
            check=False
        )

        if result.returncode != 0:
            return ""

        output = result.stdout

        if optional_key:
            # Key specified, search for the line with this key
            for line in output.split('\n'):
                if line.startswith(optional_key + ':') or line.startswith(optional_key + ' :'):
                    # Strip the "key: " prefix and any whitespace
                    value = re.sub(r'^[^:]*:\s*', '', line)
                    return value
            return ""
        else:
            # No key, get the first line
            lines = output.split('\n')
            return lines[0] if lines else ""

    except Exception as e:
        print(f"Error querying pass for '{key_path}': {e}", file=sys.stderr)
        return ""


def populate_template(template_file, target_file):
    """
    Read template file, replace all [pass:...] tokens, write to target file.

    Args:
        template_file: Path to template file
        target_file: Path to output file

    Returns:
        bool: True on success, False on error
    """
    template_path = Path(template_file)
    target_path = Path(target_file)

    if not template_path.exists():
        print(f"Error: Template file '{template_file}' does not exist", file=sys.stderr)
        return False

    # Create target directory if it doesn't exist
    target_path.parent.mkdir(parents=True, exist_ok=True)

    # Read the template file
    try:
        with open(template_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading template file '{template_file}': {e}", file=sys.stderr)
        return False

    # Find all [pass:...] tokens
    token_pattern = r'\[pass:[^\]]*\]'
    tokens = re.findall(token_pattern, content)

    # Process each unique token (longest first to handle overlapping tokens)
    unique_tokens = sorted(set(tokens), key=len, reverse=True)

    for full_token in unique_tokens:
        # Remove the "[pass:" prefix and trailing "]" to get the path
        path_and_key = full_token[6:-1]  # Strip "[pass:" and "]"

        # Parse the token to extract key_path and optional_key
        key_path, optional_key = parse_pass_token(path_and_key)

        # Query pass for the value
        value = query_pass(key_path, optional_key)

        if not value:
            print(f"Warning: Could not retrieve value for '{full_token}'", file=sys.stderr)

        # Replace all occurrences of this token with the value
        # Using simple string replacement - no regex escaping needed!
        content = content.replace(full_token, value)

    # Write to target file
    try:
        with open(target_path, 'w') as f:
            f.write(content)

        # Set permissions to 600 (owner read/write only)
        os.chmod(target_path, 0o600)

        print(f"Wrote {target_file}")
        return True

    except Exception as e:
        print(f"Error writing target file '{target_file}': {e}", file=sys.stderr)
        return False


def main():
    if len(sys.argv) != 3:
        print("Usage: populate_template.py <template_file> <target_file>", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    template_file = sys.argv[1]
    target_file = sys.argv[2]

    success = populate_template(template_file, target_file)
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
