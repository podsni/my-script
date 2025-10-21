# Repository Guidelines

## Project Structure & Module Organization
`install.sh` is the interactive entry point that locates `.sh` files under `script/` and runs them in sequence. `test.sh` offers a lightweight TUI for dry runs. The `script/` directory is grouped by topic (`ai-tools/`, `dev-env/`, `dev-tools/`, `git-tools/`, `jaringan/`, `Programming-Lang/`, `setupOS/`, `vm-test/`, etc.), and every script is runnable via `bash script/<category>/<script>.sh`. Vendored bundles (`MAS/`, `Microsoft-Activation-Scripts/`) should only change when syncing upstream.

## Build, Test, and Development Commands
- `./install.sh` — main interactive selector; use for end-to-end validation.
- `./test.sh` — menu runner for quick smoke tests of discovery and prompts.
- `bash script/<category>/<name>.sh` — execute a single installer while iterating (e.g., `bash script/dev-tools/docker.sh`).
- `shellcheck script/<category>/<name>.sh` — run static analysis before submission.

## Coding Style & Naming Conventions
Scripts target Bash (`#!/bin/bash`) and should enable `set -euo pipefail` unless documented otherwise. Indent with four spaces, keep functions lowercase with underscores (`log_info`), and name files in kebab-case. Reuse the existing logging helpers when touching `install.sh` so output stays consistent. Group related helpers near the top of each file and explain environment variables with concise inline comments.

## Testing Guidelines
Run changed scripts directly and through `./install.sh` to confirm they appear in the menu, request input correctly, and exit cleanly. Capture representative success and failure output for the PR description. Strive for idempotent operations so reruns are safe; if a script must be destructive, document the prerequisite state and rollback steps.

## Commit & Pull Request Guidelines
Write imperative, scope-focused commit subjects as seen in history (`Enhance ocaml.sh...`, `Refactor golang.sh...`), staying under ~72 characters. Add body details when multiple scripts change or new dependencies are introduced. Pull requests should clarify motivation, list affected scripts, note OS assumptions (e.g., Debian-based), and paste the commands you used for testing. When adding new scripts, justify the chosen category and call out any sync requirements for bundled directories.

## Security & Configuration Tips
Document required environment variables or credentials (e.g., `MY_SCRIPT_REPO_URL`, API tokens) in both the script header and PR. Do not hard-code secrets—prompt the user or read from the environment. Flag scripts that need sudo so reviewers can weigh the risk early.
