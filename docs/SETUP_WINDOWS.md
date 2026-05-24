# Windows Setup

## 1. Create Memory Vault

```powershell
mkdir C:\Users\<User>\AI-Memory-Vault
mkdir C:\Users\<User>\AI-Memory-Vault\scripts
mkdir C:\Users\<User>\AI-Memory-Vault\projects
mkdir C:\Users\<User>\AI-Memory-Vault\context-packs
mkdir C:\Users\<User>\AI-Memory-Vault\inbox
```

## 2. Copy scripts

Copy all files from this repo's `scripts/` folder into:

```txt
C:\Users\<User>\AI-Memory-Vault\scripts
```

## 3. Add command wrappers

Optional: place wrapper scripts in:

```txt
C:\Users\<User>\AI-Memory-Vault
```

Then add this path to user PATH:

```powershell
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$userPath;C:\Users\<User>\AI-Memory-Vault", "User")
```

## 4. Add Claude Code hooks

Edit:

```txt
C:\Users\<User>\.claude\settings.json
```

Add a top-level `hooks` block.

See `docs/settings.example.json`.

## 5. Add permissions

Allow Claude Code to read/write/edit the memory vault and run ContextOS scripts.

Example permission rules:

```json
"Read(C:\\Users\\<User>\\AI-Memory-Vault\\**)",
"Write(C:\\Users\\<User>\\AI-Memory-Vault\\**)",
"Edit(C:\\Users\\<User>\\AI-Memory-Vault\\**)"
```

## 6. Test

Create a dummy folder:

```powershell
mkdir C:\Users\<User>\Desktop\contextos-auto-test
cd C:\Users\<User>\Desktop\contextos-auto-test
claude
```

Ask:

```txt
What ContextOS memory did you receive?
```

Expected:

Claude should mention auto-created memory files.

Exit with `Ctrl + D`, then check:

```powershell
Get-ChildItem C:\Users\<User>\AI-Memory-Vault\projects\contextos-auto-test
```

## 7. Check Status

After install or upgrade, run:

```powershell
contextos-status
```

This confirms the vault path, installed scripts, Claude Code hooks, raw transcript copying status, and cross-project memory status.

Then run:

```powershell
contextos-doctor
contextos-projects
```

`contextos-projects` creates or refreshes `AI-Memory-Vault\PROJECT_INDEX.md`.
