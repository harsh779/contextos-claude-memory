#!/usr/bin/env bash
set -euo pipefail

vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
delete_vault="false"
force="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-vault) delete_vault="true"; shift ;;
    --force) force="true"; shift ;;
    --vault|--vault-path|-v) vault="${2:-}"; shift 2 ;;
    *)
      echo "Usage: bash ./uninstall-macos.sh [--delete-vault] [--force] [--vault ~/AI-Memory-Vault]"
      exit 1
      ;;
  esac
done

vault="${vault/#\~/$HOME}"

echo
echo "[ContextOS] Uninstalling ContextOS from macOS"
echo "  - Vault path: $vault"
echo

# Detect shell profile
case "${SHELL:-}" in
  */bash) shell_profile="$HOME/.bash_profile" ;;
  */fish) shell_profile="$HOME/.config/fish/config.fish" ;;
  */zsh|*) shell_profile="$HOME/.zshrc" ;;
esac

# Remove PATH and env var entries from shell profile
if [[ -f "$shell_profile" ]]; then
  if grep -Fq "ContextOS" "$shell_profile" || grep -Fq "CONTEXTOS_VAULT_PATH" "$shell_profile"; then
    # Create backup
    cp "$shell_profile" "${shell_profile}.contextos-backup"
    # Remove ContextOS block
    grep -v "CONTEXTOS_VAULT_PATH\|# ContextOS" "$shell_profile" | grep -v "$vault" > "${shell_profile}.tmp" || true
    mv "${shell_profile}.tmp" "$shell_profile"
    echo "[ContextOS] Cleaned $shell_profile (backup: ${shell_profile}.contextos-backup)"
  else
    echo "[ContextOS] No ContextOS entries found in $shell_profile"
  fi
fi

# Remove command wrappers from vault root
wrappers=(contextos-find contextos-projects contextos-resume contextos-open contextos-status contextos-doctor)
removed=0
for wrapper in "${wrappers[@]}"; do
  if [[ -f "$vault/$wrapper" ]]; then
    rm "$vault/$wrapper"
    removed=$((removed + 1))
  fi
done
echo "[ContextOS] Removed $removed command wrappers"

# Remove scripts directory
if [[ -d "$vault/scripts" ]]; then
  rm -rf "$vault/scripts"
  echo "[ContextOS] Removed scripts directory"
fi

# Optionally delete vault
if [[ "$delete_vault" == "true" ]]; then
  if [[ "$force" != "true" ]]; then
    echo
    echo "WARNING: This will permanently delete all ContextOS memory at:"
    echo "  $vault"
    echo
    read -r -p "Type 'DELETE' to confirm: " confirm
    if [[ "$confirm" != "DELETE" ]]; then
      echo "[ContextOS] Vault deletion cancelled."
      exit 0
    fi
  fi
  rm -rf "$vault"
  echo "[ContextOS] Vault deleted: $vault"
else
  echo "[ContextOS] Vault preserved at: $vault"
  echo "  To delete: bash ./uninstall-macos.sh --delete-vault"
fi

echo
echo "[ContextOS] Uninstall complete. Restart your terminal for PATH changes."
