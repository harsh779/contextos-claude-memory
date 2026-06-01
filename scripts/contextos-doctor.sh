#!/usr/bin/env bash
set -euo pipefail

version="v0.1.5-dev"
vault="${CONTEXTOS_VAULT_PATH:-$HOME/AI-Memory-Vault}"
scripts_dir="$vault/scripts"
settings_path="$HOME/.claude/settings.json"
warn_count=0
fail_count=0
fixes=()

add_fix() {
  fixes+=("$1")
}

section() {
  echo
  echo "$1"
  printf '%*s\n' "${#1}" '' | tr ' ' '-'
}

check() {
  local status="$1"
  local label="$2"
  local detail="${3:-}"
  [[ "$status" == "WARN" ]] && warn_count=$((warn_count + 1))
  [[ "$status" == "FAIL" ]] && fail_count=$((fail_count + 1))
  if [[ -n "$detail" ]]; then
    printf "%-5s %s: %s\n" "$status" "$label" "$detail"
  else
    printf "%-5s %s\n" "$status" "$label"
  fi
}

echo
echo "ContextOS Doctor"
echo "================"

section "Version"
check OK "ContextOS version" "$version"

section "Vault"
check OK "Resolved vault path" "$vault"
for item in "$vault" "$vault/projects" "$vault/scripts" "$vault/context-packs" "$vault/debug" "$vault/inbox"; do
  if [[ -e "$item" ]]; then
    check OK "$(basename "$item") exists" "$item"
  else
    check FAIL "$(basename "$item") exists" "$item"
    add_fix "Rerun install: bash ./install-macos.sh --vault \"$vault\""
  fi
done

section "Scripts"
required=(contextos-start.sh contextos-capture.sh contextos-status.sh contextos-projects.sh contextos-find.sh contextos-resume.sh contextos-open.sh contextos-doctor.sh process-session.py compress-project-memory.py)
for item in "${required[@]}"; do
  if [[ -f "$scripts_dir/$item" ]]; then
    check OK "$item" "$scripts_dir/$item"
  else
    check FAIL "$item" "Missing from vault scripts"
    add_fix "Rerun install: bash ./install-macos.sh --vault \"$vault\""
  fi
done

section "Wrappers"
wrappers=(contextos-status contextos-projects contextos-find contextos-resume contextos-open contextos-doctor)
for item in "${wrappers[@]}"; do
  if [[ -x "$vault/$item" ]]; then
    check OK "$item" "$vault/$item"
  else
    check FAIL "$item" "Missing from vault root or not executable"
    add_fix "Rerun install: bash ./install-macos.sh --vault \"$vault\""
  fi
done

section "PATH"
case ":$PATH:" in
  *":$vault:"*) check OK "PATH contains vault root" "$vault" ;;
  *)
    check WARN "PATH contains vault root" "Missing"
    add_fix "Add to shell profile: export PATH=\"$vault:\$PATH\""
    ;;
esac

section "Python"
if command -v python3 >/dev/null 2>&1; then
  check OK "python3 available" "$(command -v python3)"
  check OK "python3 --version" "$(python3 --version 2>&1)"
else
  check FAIL "python3 available" "Not found"
  add_fix "Install Python 3; SessionEnd processing requires it."
fi

section "Claude Hooks"
if [[ -f "$settings_path" ]]; then
  check OK "Claude settings file exists" "$settings_path"
  hooks_check="$(python3 -c "
import json, sys
try:
    cfg = json.load(open('$settings_path'))
    hooks = cfg.get('hooks', {})
    results = {
        'hooks': bool(hooks),
        'SessionStart': 'SessionStart' in hooks,
        'SessionEnd': 'SessionEnd' in hooks,
    }
    text = json.dumps(cfg)
    results['contextos-start'] = 'contextos-start' in text
    results['contextos-capture'] = 'contextos-capture' in text
    for k, v in results.items():
        print(f'{k}={v}')
except Exception as e:
    print(f'error={e}')
" 2>&1)" || hooks_check="error=python3 failed"
  if echo "$hooks_check" | grep -q "^error="; then
    check FAIL "Claude settings parse" "$(echo "$hooks_check" | head -1)"
  else
    for key in hooks SessionStart SessionEnd contextos-start contextos-capture; do
      if echo "$hooks_check" | grep -q "^${key}=True"; then
        check OK "$key appears in settings"
      else
        check FAIL "$key appears in settings" "Missing"
        add_fix "Merge the settings snippet printed by install-macos.sh."
      fi
    done
  fi
else
  check FAIL "Claude settings file exists" "$settings_path"
  add_fix "Create ~/.claude/settings.json and merge the settings snippet printed by install-macos.sh."
fi

section "Privacy"
if [[ "${CONTEXTOS_COPY_RAW_TRANSCRIPTS:-}" == "true" ]]; then
  check WARN "Raw transcript copying" "Enabled"
else
  check OK "Raw transcript copying" "Disabled"
fi

section "Cross-Project Memory"
[[ -f "$vault/PROJECT_INDEX.md" ]] && check OK "Project index exists" "$vault/PROJECT_INDEX.md" || { check WARN "Project index exists" "Missing"; add_fix "Refresh project index: contextos-projects"; }
if [[ "${CONTEXTOS_ENABLE_CROSS_PROJECT_MEMORY:-}" == "false" ]]; then
  check WARN "Cross-project startup injection" "Disabled"
else
  check OK "Cross-project startup injection" "Enabled"
fi

section "Recommended Fixes"
if [[ ${#fixes[@]} -eq 0 ]]; then
  echo "OK    No recommended fixes."
else
  for item in "${fixes[@]}"; do
    echo "- $item"
  done
  echo "- Run status: contextos-status"
fi

section "Final Result"
if [[ $fail_count -gt 0 ]]; then
  echo "FAIL: ContextOS is not correctly installed."
elif [[ $warn_count -gt 0 ]]; then
  echo "WARN: ContextOS works, but some improvements are recommended."
else
  echo "OK: ContextOS looks healthy."
fi
