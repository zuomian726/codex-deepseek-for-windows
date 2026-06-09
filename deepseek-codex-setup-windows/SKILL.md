---
name: deepseek-codex-setup-windows
description: Configure or repair Codex CLI/Desktop for Windows to use DeepSeek V4 through a local Responses API proxy. Use when the user asks to connect DeepSeek API to Codex on Windows, migrate this setup to another Windows PC, fix `codex -p deepseek`, or troubleshoot `/responses` 404, `Reconnecting...`, or `stream disconnected` errors with DeepSeek-backed Codex.
---

# DeepSeek Codex Setup for Windows

## Purpose

Use this skill to install, repair, test, or explain the local DeepSeek V4 bridge for Codex on Windows. Codex expects a Responses API provider, while DeepSeek V4 exposes Chat Completions, so this setup runs a local proxy:

```text
Codex -> http://127.0.0.1:8766/responses -> https://api.deepseek.com/chat/completions
```

When helping a beginner, lead with the README quick-start flow for Windows: install Codex, install Node.js LTS, get a DeepSeek API key, clone the repository, run `install.ps1`, then test `codex exec -p deepseek --skip-git-repo-check "只回复 OK"`. Avoid explaining protocol details unless the user asks. Do not present this as a Mac/Linux guide.

## Install Or Repair

Use the bundled PowerShell installer unless the user only wants an explanation.

```powershell
powershell -ExecutionPolicy Bypass -File .\deepseek-codex-setup-windows\scripts\install.ps1 -ApiKey <your-deepseek-api-key>
```

If the key is already in the environment:

```powershell
$env:DEEPSEEK_API_KEY = "<your-deepseek-api-key>"
powershell -ExecutionPolicy Bypass -File .\deepseek-codex-setup-windows\scripts\install.ps1
```

The installer writes:

- `%USERPROFILE%\.codex\.env` with `DEEPSEEK_API_KEY`
- `%USERPROFILE%\.codex\deepseek.config.toml`
- `%USERPROFILE%\.codex\deepseek-responses-proxy\server.mjs`
- `%USERPROFILE%\.codex\deepseek-responses-proxy\start.ps1`
- `%USERPROFILE%\.codex\deepseek-responses-proxy\stop.ps1`
- `%USERPROFILE%\.codex\deepseek-responses-proxy\desktop-use-deepseek.ps1`
- `%USERPROFILE%\.codex\deepseek-responses-proxy\desktop-use-default.ps1`

Never print the API key in user-facing output. Mask it in diagnostics.

## Daily Commands

Start the proxy before using the DeepSeek profile:

```powershell
& "$HOME\.codex\deepseek-responses-proxy\start.ps1"
```

Interactive Codex with DeepSeek:

```powershell
codex -p deepseek
```

One-shot test:

```powershell
codex exec -p deepseek --skip-git-repo-check "只回复 OK"
```

Stop the proxy:

```powershell
& "$HOME\.codex\deepseek-responses-proxy\stop.ps1"
```

Health check:

```powershell
Invoke-RestMethod http://127.0.0.1:8766/health
```

Expected:

```json
{"ok":true,"provider":"deepseek","base_url":"https://api.deepseek.com"}
```

## Desktop Guidance

Prefer terminal usage with `codex -p deepseek`, but support Desktop when the user explicitly asks. Codex Desktop does not expose the same obvious profile switch, so use the generated scripts instead of asking beginners to hand-edit TOML:

```powershell
& "$HOME\.codex\deepseek-responses-proxy\desktop-use-deepseek.ps1"
& "$HOME\.codex\deepseek-responses-proxy\desktop-use-default.ps1"
```

Explain that `desktop-use-deepseek.ps1` starts the proxy, creates a one-time original backup of `%USERPROFILE%\.codex\config.toml`, and writes DeepSeek as the global model provider. Tell the user to fully quit and reopen Codex Desktop after switching. If Desktop fails to connect, start the proxy or run `desktop-use-default.ps1` to restore the original config from before the first Desktop switch.

