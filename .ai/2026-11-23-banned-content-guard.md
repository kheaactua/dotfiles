# Banned-Content Guard

**Date:** 2026-11-23
**AI Tool:** copilot
**Purpose:** Prevent private/employer-specific content from being committed to this public repository. Mirrors the setup in `fish-ai-container`.

## Files Created/Modified

- `.pre-commit-hooks/check-banned-content.sh` - scanner with `files`, `author`, `message` and `history [RANGE]` modes
- `.pre-commit-config.yaml` - pre-commit and commit-msg hooks calling the scanner
- `.github/workflows/banned-content.yml` - CI scan of newly pushed commits
- `.banned-patterns.example` - template (the real `.banned-patterns` is gitignored)
- `.gitignore` - ignores `.banned-patterns`

## Setup

1. `pip install pre-commit && pre-commit install`
2. `cp .banned-patterns.example .banned-patterns` and list real patterns (one extended regex per line)
3. Add the same patterns as the `BANNED_PATTERNS` repository secret for CI

## Differences from the reference

- CI scans only the pushed/PR commit range, and only **added** lines, so cleanup commits that remove banned content pass.
- No weekly full-history scan; run `workflow_dispatch` for an on-demand full audit.
- An invalid revision range fails closed (exit 2).
- Existing tracked files and history already contain matches; they are not rewritten.
