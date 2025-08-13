#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Configure Git remotes for this repo.
#
# What it does:
#   - Sets origin to your fork over SSH using your SSH host alias.
#   - Sets upstream to the full clone URL you provide (HTTPS or SSH).
#   - Disables pushing to upstream.
#   - Auto-detects SSH alias / owner / repo from existing origin when possible.
#   - Detects upstream default branch (main vs master).
#
# Defaults:
#   ORIGIN_URL   -> git@<SSH_ALIAS>:<FORK_OWNER>/<REPO_NAME>
#   UPSTREAM_URL -> full clone URL from GitHub (HTTPS or SSH), e.g.
#                   https://github.com/awslabs/amazon-redshift-utils.git
#
# Auto-detection:
#   - If 'origin' exists:
#       * SSH origin (git@ALIAS:OWNER/REPO(.git)?)  -> detect SSH_ALIAS, FORK_OWNER, REPO_NAME
#       * HTTPS origin (https://github.com/OWNER/REPO(.git)?) -> detect FORK_OWNER, REPO_NAME
#   - If 'upstream' exists and UPSTREAM_URL not provided, reuse it.
#
# Environment variables (override autodetect if set):
#   SSH_ALIAS      (default: github.com-jaco.alberts-mydata.co.za; auto if origin=SSH)
#   FORK_OWNER     (default: ojalberts-itc; auto if origin present)
#   REPO_NAME      (default: <basename of repo dir>; auto if origin present)
#   UPSTREAM_URL   (no default; if unset -> try existing upstream, else fallback to
#                   https://github.com/awslabs/${REPO_NAME}.git when REPO_NAME known)
#   SKIP_SSH_TEST  (set to 1 to skip alias test)
#
# Example usage for AWS Labs fork:
#   UPSTREAM_URL="https://github.com/awslabs/amazon-redshift-utils.git" \
#   FORK_OWNER=ojalberts-itc \
#   REPO_NAME=amazon-redshift-utils \
#   ./configure-git-remotes.sh
#
# Example usage for another fork:
#   UPSTREAM_URL="https://github.com/someorg/someproject.git" \
#   FORK_OWNER=mydata-za \
#   REPO_NAME=someproject \
#   ./configure-git-remotes.sh
# -----------------------------------------------------------------------------

# User overrides
SSH_ALIAS="${SSH_ALIAS:-}"
FORK_OWNER="${FORK_OWNER:-}"
REPO_NAME="${REPO_NAME:-}"
UPSTREAM_URL="${UPSTREAM_URL:-}"
SKIP_SSH_TEST="${SKIP_SSH_TEST:-0}"

info() { printf '\033[1;34m[i]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
error() {
  printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2
  exit 1
}

# Preconditions
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || error "Not inside a Git repository."
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Parse origin if present
if git remote get-url origin >/dev/null 2>&1; then
  ORIGIN_EXISTING="$(git remote get-url origin)"
  # SSH form: git@ALIAS:OWNER/REPO(.git)?
  if [[ "$ORIGIN_EXISTING" =~ ^git@([^:]+):([^/]+)/([^/]+?)(\.git)?$ ]]; then
    SSH_ALIAS="${SSH_ALIAS:-${BASH_REMATCH[1]}}"
    FORK_OWNER="${FORK_OWNER:-${BASH_REMATCH[2]}}"
    REPO_NAME="${REPO_NAME:-${BASH_REMATCH[3]}}"
  # HTTPS form: https?://host/OWNER/REPO(.git)?
  elif [[ "$ORIGIN_EXISTING" =~ ^https?://[^/]+/([^/]+)/([^/]+?)(\.git)?$ ]]; then
    FORK_OWNER="${FORK_OWNER:-${BASH_REMATCH[1]}}"
    REPO_NAME="${REPO_NAME:-${BASH_REMATCH[2]}}"
  fi
fi

# Fill defaults
SSH_ALIAS="${SSH_ALIAS:-github.com-jaco.alberts-mydata.co.za}"
FORK_OWNER="${FORK_OWNER:-ojalberts-itc}"
REPO_NAME="${REPO_NAME:-$(basename "$REPO_ROOT")}"

# Normalize repo name: strip ALL trailing ".git"
while [[ "$REPO_NAME" == *.git ]]; do REPO_NAME="${REPO_NAME%.git}"; done

# Determine UPSTREAM_URL
if [[ -z "$UPSTREAM_URL" ]]; then
  if git remote get-url upstream >/dev/null 2>&1; then
    UPSTREAM_URL="$(git remote get-url upstream)"
    info "Reusing existing upstream URL: $UPSTREAM_URL"
  else
    UPSTREAM_URL="https://github.com/awslabs/${REPO_NAME}.git"
    warn "UPSTREAM_URL not provided; defaulting to $UPSTREAM_URL"
    warn "Override by running: UPSTREAM_URL='<clone-url>' ./configure-git-remotes.sh"
  fi
fi

# Build SSH origin URL (no .git suffix on purpose)
ORIGIN_URL="git@${SSH_ALIAS}:${FORK_OWNER}/${REPO_NAME}"

# SSH alias sanity
if [[ "$SKIP_SSH_TEST" != "1" ]]; then
  if ! grep -qE "^[[:space:]]*Host[[:space:]]+$SSH_ALIAS\b" "${HOME}/.ssh/config" 2>/dev/null; then
    warn "SSH alias '$SSH_ALIAS' not found in ~/.ssh/config. You may hit auth issues."
  else
    info "Testing SSH alias '$SSH_ALIAS'..."
    if ssh -T -o BatchMode=yes -o StrictHostKeyChecking=no "git@${SSH_ALIAS}" 2>&1 | grep -qi "successfully authenticated"; then
      info "SSH alias '$SSH_ALIAS' looks good."
    else
      warn "SSH test did not confirm authentication. If pushes fail, check the key attached to GitHub."
    fi
  fi
fi

# Configure origin
if git remote get-url origin >/dev/null 2>&1; then
  CURRENT_ORIGIN="$(git remote get-url origin)"
  if [[ "$CURRENT_ORIGIN" != "$ORIGIN_URL" ]]; then
    info "Updating origin:"
    info "  $CURRENT_ORIGIN"
    info "    -> $ORIGIN_URL"
    git remote set-url origin "$ORIGIN_URL"
  else
    info "origin already set to desired URL."
  fi
  git remote set-url --push origin "$ORIGIN_URL"
else
  info "Adding origin -> $ORIGIN_URL"
  git remote add origin "$ORIGIN_URL"
  git remote set-url --push origin "$ORIGIN_URL"
fi

# Configure upstream (fetch from provided URL, push disabled)
if git remote get-url upstream >/dev/null 2>&1; then
  CURRENT_UPSTREAM="$(git remote get-url upstream)"
  if [[ "$CURRENT_UPSTREAM" != "$UPSTREAM_URL" ]]; then
    info "Updating upstream fetch URL:"
    info "  $CURRENT_UPSTREAM"
    info "    -> $UPSTREAM_URL"
    git remote set-url upstream "$UPSTREAM_URL"
  else
    info "upstream fetch URL already correct."
  fi
else
  info "Adding upstream (fetch) -> $UPSTREAM_URL"
  git remote add upstream "$UPSTREAM_URL"
fi

# Disable pushes to upstream explicitly
git remote set-url --push upstream DISABLE

# Show final remotes
echo
info "Final remotes:"
git remote -v

# Detect upstream default branch
echo
info "Detecting upstream default branch..."
DEFAULT_REF="$(git ls-remote --symref "$UPSTREAM_URL" HEAD 2>/dev/null | awk '/^ref:/ {print $2}' | sed 's#refs/heads/##')"
if [[ -n "$DEFAULT_REF" ]]; then
  info "Upstream default branch appears to be: $DEFAULT_REF"
else
  warn "Could not determine upstream default branch. It is usually 'main' or 'master'."
fi

cat <<'EONOTES'

Next steps (manual):
  git fetch upstream
  # Merge or rebase as needed:
  #   git checkout master && git merge upstream/<branch>
  #   git checkout master && git rebase upstream/<branch>
  #
  git push origin HEAD

EONOTES
