#!/usr/bin/env bash
set -euo pipefail

version="v0.1.5-dev"
vault=""
skip_path_update="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vault|--vault-path|-v)
      vault="${2:-}"
      shift 2
      ;;
    --skip-path-update)
      skip_path_update="true"
      shift
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: bash ./install-macos.sh [--vault ~/AI-Memory-Vault] [--skip-path-update]"
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_scripts="$repo_root/scripts"
vault="${vault:-${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}}"
vault="${vault/#\~/$HOME}"
vault_scripts="$vault/scripts"

echo
echo "[ContextOS] Installing ContextOS $version for macOS"
echo "  - Repo root: $repo_root"
echo "  - Vault path: $vault"
echo "  - Safe to rerun after pulling a new ContextOS version."
echo "  - Existing project memory is not deleted or overwritten."
echo "  - Rerunning install-macos.sh updates reusable scripts in: $vault_scripts"
echo

if [[ ! -d "$source_scripts" ]]; then
  echo "Source scripts folder not found: $source_scripts"
  exit 1
fi

mkdir -p "$vault" "$vault_scripts" "$vault/projects" "$vault/context-packs" "$vault/debug" "$vault/inbox"
echo "[ContextOS] Vault folders ready."

copied=0
for path in "$source_scripts"/*.sh "$source_scripts"/*.py; do
  [[ -f "$path" ]] || continue
  cp "$path" "$vault_scripts/"
  chmod +x "$vault_scripts/$(basename "$path")" || true
  copied=$((copied + 1))
done

echo "[ContextOS] Scripts copied to $vault_scripts"
find "$vault_scripts" -maxdepth 1 \( -name '*.sh' -o -name '*.py' \) -type f -print | sort | sed 's#^.*/#  - #'

wrapper_names=(contextos-find contextos-projects contextos-resume contextos-open contextos-status contextos-doctor)
wrapper_targets=(contextos-find.sh contextos-projects.sh contextos-resume.sh contextos-open.sh contextos-status.sh contextos-doctor.sh)

for index in "${!wrapper_names[@]}"; do
  wrapper="${wrapper_names[$index]}"
  target="$vault_scripts/${wrapper_targets[$index]}"
  wrapper_path="$vault/$wrapper"
  cat > "$wrapper_path" <<EOF
#!/usr/bin/env bash
export CONTEXTOS_VAULT_PATH="$vault"
exec "$target" "\$@"
EOF
  chmod +x "$wrapper_path"
done

echo "[ContextOS] Command wrappers ready in vault root."
for wrapper in "${wrapper_names[@]}"; do
  echo "  - $wrapper"
done | sort

path_status="Skipped by --skip-path-update"
shell_profile="$HOME/.zshrc"
if [[ "$skip_path_update" != "true" ]]; then
  if [[ ":$PATH:" == *":$vault:"* ]]; then
    path_status="Already present in current PATH"
  elif [[ -f "$shell_profile" ]] && grep -Fq "$vault" "$shell_profile"; then
    path_status="Already present in $shell_profile"
  else
    {
      echo ""
      echo "# ContextOS"
      echo "export CONTEXTOS_VAULT_PATH=\"$vault\""
      echo "export PATH=\"$vault:\$PATH\""
    } >> "$shell_profile"
    path_status="Updated $shell_profile; restart terminal or run: source ~/.zshrc"
  fi
fi

echo "[ContextOS] PATH update: $path_status"

python_status="Warning: python3 not found"
if command -v python3 >/dev/null 2>&1; then
  python_status="Detected ($(python3 --version 2>&1))"
  echo "[ContextOS] Python detected: $(python3 --version 2>&1)"
else
  echo "[ContextOS] WARNING: python3 was not detected. Install Python 3 before using SessionEnd processing."
fi

settings_snippet=$(cat <<EOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "bash \\"$vault_scripts/contextos-start.sh\\"",
            "timeout": 30
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash \\"$vault_scripts/contextos-capture.sh\\"",
            "timeout": 60
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Read($vault/**)",
      "Write($vault/**)",
      "Edit($vault/**)",
      "Bash(bash \\"$vault_scripts/contextos-start.sh\\")",
      "Bash(bash \\"$vault_scripts/contextos-capture.sh\\")",
      "Bash(python3 \\"$vault_scripts/process-session.py\\"*)"
    ]
  }
}
EOF
)

echo
echo "Claude Code settings snippet:"
echo "--------------------------------"
echo "$settings_snippet"
echo "--------------------------------"

wrapper_count=0
for wrapper in "${wrapper_names[@]}"; do
  [[ -x "$vault/$wrapper" ]] && wrapper_count=$((wrapper_count + 1))
done

echo
echo "Post-install validation summary"
echo "-------------------------------"
echo "Vault exists:                 $([[ -d "$vault" ]] && echo Yes || echo No)"
echo "Scripts folder exists:        $([[ -d "$vault_scripts" ]] && echo Yes || echo No)"
echo "Scripts copied:               $copied"
echo "Command wrappers created:     $wrapper_count/${#wrapper_names[@]}"
echo "Python:                       $python_status"
echo "Claude settings snippet:      Printed"
echo "PATH update:                  $path_status"
echo
echo "Next recommended commands:"
echo "  contextos-status"
echo "  contextos-doctor"
echo "  contextos-projects"
echo
echo "[ContextOS] Install/upgrade complete."
