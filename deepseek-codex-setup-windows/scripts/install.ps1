param(
  [string]$ApiKey = $env:DEEPSEEK_API_KEY,
  [string]$Model = "deepseek-v4-pro",
  [int]$Port = 8766
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Fail($Message) {
  Write-Error $Message
  exit 1
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  Fail "Missing DeepSeek API key. Pass -ApiKey or set DEEPSEEK_API_KEY."
}

$NodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCommand) {
  Fail "Node.js was not found. Install Node.js LTS from https://nodejs.org/ and reopen PowerShell."
}

$CodexCommand = Get-Command codex -ErrorAction SilentlyContinue
if (-not $CodexCommand) {
  Write-Warning "codex was not found in PATH. Install or repair Codex CLI before testing with codex -p deepseek."
}

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$Root = Join-Path $CodexHome "deepseek-responses-proxy"
$EnvFile = Join-Path $CodexHome ".env"
$ProfileFile = Join-Path $CodexHome "deepseek.config.toml"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ServerSource = Join-Path $ScriptDir "server.mjs"
$ServerTarget = Join-Path $Root "server.mjs"

if (-not (Test-Path $ServerSource)) {
  Fail "server.mjs not found: $ServerSource"
}

New-Item -ItemType Directory -Force -Path $CodexHome, $Root | Out-Null
Copy-Item -Force $ServerSource $ServerTarget

if (Test-Path $EnvFile) {
  $lines = Get-Content $EnvFile
  $found = $false
  $updated = foreach ($line in $lines) {
    if ($line -match '^DEEPSEEK_API_KEY=') {
      $found = $true
      "DEEPSEEK_API_KEY=$ApiKey"
    } else {
      $line
    }
  }
  if (-not $found) {
    $updated += "DEEPSEEK_API_KEY=$ApiKey"
  }
  Set-Content -Path $EnvFile -Value $updated -Encoding UTF8
} else {
  Set-Content -Path $EnvFile -Value "DEEPSEEK_API_KEY=$ApiKey" -Encoding UTF8
}

$profileToml = @"
model = "$Model"
model_provider = "deepseek_proxy"

[model_providers.deepseek_proxy]
name = "DeepSeek v4 via local Responses proxy"
base_url = "http://127.0.0.1:$Port"
env_key = "DEEPSEEK_API_KEY"
wire_api = "responses"
supports_websockets = false
"@
Set-Content -Path $ProfileFile -Value $profileToml -Encoding UTF8

$startTemplate = @'
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$Root = Join-Path $CodexHome "deepseek-responses-proxy"
$EnvFile = Join-Path $CodexHome ".env"
$PidFile = Join-Path $Root "deepseek-proxy.pid"
$OutLog = Join-Path $Root "deepseek-proxy.out.log"
$ErrLog = Join-Path $Root "deepseek-proxy.err.log"
$ServerFile = Join-Path $Root "server.mjs"
$Port = __PORT__

function Read-DeepSeekKey($Path) {
  if (-not (Test-Path $Path)) {
    throw "Missing env file: $Path"
  }

  foreach ($line in Get-Content $Path) {
    if ($line -match '^DEEPSEEK_API_KEY=(.*)$') {
      return $Matches[1]
    }
  }

  throw "DEEPSEEK_API_KEY was not found in $Path"
}

if (Test-Path $PidFile) {
  $ExistingPid = (Get-Content $PidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
  if ($ExistingPid) {
    $ExistingProcess = Get-Process -Id ([int]$ExistingPid) -ErrorAction SilentlyContinue
    if ($ExistingProcess) {
      Write-Host "DeepSeek proxy already running: $ExistingPid"
      exit 0
    }
  }
  Remove-Item -Force $PidFile -ErrorAction SilentlyContinue
}

$NodeCommand = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCommand) {
  throw "Node.js was not found. Install Node.js LTS from https://nodejs.org/ and reopen PowerShell."
}

$env:DEEPSEEK_API_KEY = Read-DeepSeekKey $EnvFile
$env:DEEPSEEK_PROXY_PORT = [string]$Port

$Process = Start-Process -FilePath $NodeCommand.Source -ArgumentList @($ServerFile) -WorkingDirectory $Root -PassThru -WindowStyle Hidden -RedirectStandardOutput $OutLog -RedirectStandardError $ErrLog
Set-Content -Path $PidFile -Value $Process.Id -Encoding ASCII
Start-Sleep -Milliseconds 1000

try {
  Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 2 | Out-Null
  Write-Host "DeepSeek proxy started: http://127.0.0.1:$Port"
  Write-Host "Log: $OutLog"
  Write-Host "Error log: $ErrLog"
} catch {
  Write-Error "DeepSeek proxy failed to start. Check logs: $OutLog and $ErrLog"
  exit 1
}
'@

$stopTemplate = @'
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$Root = Join-Path $CodexHome "deepseek-responses-proxy"
$PidFile = Join-Path $Root "deepseek-proxy.pid"

if (-not (Test-Path $PidFile)) {
  Write-Host "DeepSeek proxy is not running."
  exit 0
}

$PidValue = (Get-Content $PidFile | Select-Object -First 1)
$Process = Get-Process -Id ([int]$PidValue) -ErrorAction SilentlyContinue
if ($Process) {
  Stop-Process -Id $Process.Id
  Write-Host "DeepSeek proxy stopped: $PidValue"
} else {
  Write-Host "DeepSeek proxy process was not running: $PidValue"
}

Remove-Item -Force $PidFile -ErrorAction SilentlyContinue
'@

$desktopDeepSeekTemplate = @'
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$Model = "__MODEL__"
$Port = __PORT__
$CodexHome = Join-Path $env:USERPROFILE ".codex"
$ConfigFile = Join-Path $CodexHome "config.toml"
$BackupDir = Join-Path $CodexHome "config-backups"
$OriginalBackup = Join-Path $BackupDir "config.toml.before-deepseek-desktop.original"
$StartScript = Join-Path $CodexHome "deepseek-responses-proxy\start.ps1"

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
& $StartScript

if (Test-Path $ConfigFile) {
  if (-not (Test-Path $OriginalBackup)) {
    Copy-Item $ConfigFile $OriginalBackup
    Write-Host "Original backup: $OriginalBackup"
  }
  $Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $BackupFile = Join-Path $BackupDir "config.toml.before-deepseek-desktop.$Stamp"
  Copy-Item $ConfigFile $BackupFile
  Write-Host "Backup: $BackupFile"
} else {
  New-Item -ItemType File -Force -Path $ConfigFile | Out-Null
  Copy-Item $ConfigFile $OriginalBackup
  Write-Host "Original backup: $OriginalBackup"
}

$Lines = Get-Content $ConfigFile -ErrorAction SilentlyContinue
$Filtered = New-Object System.Collections.Generic.List[string]
$Table = $null
$SkipDeepSeekProvider = $false

foreach ($Line in $Lines) {
  if ($Line -match '^\s*\[([^\]]+)\]\s*$') {
    $Table = $Matches[1]
    $SkipDeepSeekProvider = ($Table -eq "model_providers.deepseek_proxy")
    if ($SkipDeepSeekProvider) {
      continue
    }
  }

  if ($SkipDeepSeekProvider) {
    continue
  }

  if (($null -eq $Table) -and ($Line -match '^\s*(model|model_provider)\s*=')) {
    continue
  }

  if ($Line -eq "model = `"$Model`"") {
    continue
  }

  if ($Line -eq 'model_provider = "deepseek_proxy"') {
    continue
  }

  $Filtered.Add($Line)
}

$FirstTableIndex = $Filtered.Count
for ($i = 0; $i -lt $Filtered.Count; $i++) {
  if ($Filtered[$i] -match '^\s*\[') {
    $FirstTableIndex = $i
    break
  }
}

$Out = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $FirstTableIndex; $i++) {
  $Out.Add($Filtered[$i])
}
if (($Out.Count -gt 0) -and ($Out[($Out.Count - 1)] -ne "")) {
  $Out.Add("")
}
$Out.Add("model = `"$Model`"")
$Out.Add('model_provider = "deepseek_proxy"')
$Out.Add("")
for ($i = $FirstTableIndex; $i -lt $Filtered.Count; $i++) {
  $Out.Add($Filtered[$i])
}
if (($Out.Count -gt 0) -and ($Out[($Out.Count - 1)] -ne "")) {
  $Out.Add("")
}
$Out.Add("[model_providers.deepseek_proxy]")
$Out.Add('name = "DeepSeek v4 via local Responses proxy"')
$Out.Add("base_url = `"http://127.0.0.1:$Port`"")
$Out.Add('env_key = "DEEPSEEK_API_KEY"')
$Out.Add('wire_api = "responses"')
$Out.Add('supports_websockets = false')

Set-Content -Path $ConfigFile -Value $Out -Encoding UTF8

Write-Host ""
Write-Host "Codex Desktop is now configured to use DeepSeek."
Write-Host "Important: fully quit Codex Desktop and open it again."
Write-Host "To restore default config later:"
Write-Host "  $CodexHome\deepseek-responses-proxy\desktop-use-default.ps1"
'@

$desktopDefaultTemplate = @'
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$CodexHome = Join-Path $env:USERPROFILE ".codex"
$ConfigFile = Join-Path $CodexHome "config.toml"
$BackupDir = Join-Path $CodexHome "config-backups"
$OriginalBackup = Join-Path $BackupDir "config.toml.before-deepseek-desktop.original"

if (Test-Path $OriginalBackup) {
  Copy-Item $OriginalBackup $ConfigFile
  Write-Host "Restored: $OriginalBackup"
  Write-Host "Important: fully quit Codex Desktop and open it again."
  exit 0
}

if (-not (Test-Path $ConfigFile)) {
  Write-Host "No config.toml found. Nothing to restore."
  exit 0
}

$Lines = Get-Content $ConfigFile
$Out = New-Object System.Collections.Generic.List[string]
$Table = $null
$SkipDeepSeekProvider = $false

foreach ($Line in $Lines) {
  if ($Line -match '^\s*\[([^\]]+)\]\s*$') {
    $Table = $Matches[1]
    $SkipDeepSeekProvider = ($Table -eq "model_providers.deepseek_proxy")
    if ($SkipDeepSeekProvider) {
      continue
    }
  }

  if ($SkipDeepSeekProvider) {
    continue
  }

  if (($null -eq $Table) -and ($Line -match '^\s*(model|model_provider)\s*=')) {
    continue
  }

  if ($Line -match '^\s*model\s*=\s*"deepseek-v4-pro"\s*$') {
    continue
  }

  if ($Line -eq 'model_provider = "deepseek_proxy"') {
    continue
  }

  $Out.Add($Line)
}

Set-Content -Path $ConfigFile -Value $Out -Encoding UTF8
Write-Host "Removed DeepSeek Desktop config block."
Write-Host "Important: fully quit Codex Desktop and open it again."
'@

$startScript = $startTemplate.Replace("__PORT__", [string]$Port)
$desktopDeepSeekScript = $desktopDeepSeekTemplate.Replace("__MODEL__", $Model).Replace("__PORT__", [string]$Port)

Set-Content -Path (Join-Path $Root "start.ps1") -Value $startScript -Encoding UTF8
Set-Content -Path (Join-Path $Root "stop.ps1") -Value $stopTemplate -Encoding UTF8
Set-Content -Path (Join-Path $Root "desktop-use-deepseek.ps1") -Value $desktopDeepSeekScript -Encoding UTF8
Set-Content -Path (Join-Path $Root "desktop-use-default.ps1") -Value $desktopDefaultTemplate -Encoding UTF8

$startCmd = '@echo off' + "`r`n" + 'powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.codex\deepseek-responses-proxy\start.ps1"'
$stopCmd = '@echo off' + "`r`n" + 'powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.codex\deepseek-responses-proxy\stop.ps1"'
Set-Content -Path (Join-Path $Root "start.cmd") -Value $startCmd -Encoding ASCII
Set-Content -Path (Join-Path $Root "stop.cmd") -Value $stopCmd -Encoding ASCII

& (Join-Path $Root "start.ps1")

Write-Host ""
Write-Host "Installed DeepSeek Codex profile for Windows."
Write-Host "Test with:"
Write-Host '  codex exec -p deepseek --skip-git-repo-check "只回复 OK"'
Write-Host "Interactive use:"
Write-Host "  codex -p deepseek"
Write-Host "Desktop use:"
Write-Host "  $CodexHome\deepseek-responses-proxy\desktop-use-deepseek.ps1"
Write-Host "Desktop restore:"
Write-Host "  $CodexHome\deepseek-responses-proxy\desktop-use-default.ps1"
