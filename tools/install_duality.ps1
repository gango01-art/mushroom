# Windows PowerShell 5.1+ / PowerShell 7. Installs a verified addon bundle with backups.
[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [string]$DotaPath = "",
  [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,31}$')][string]$AddonName = "duality",
  [ValidateSet('Demo', 'Match')][string]$Mode = 'Demo',
  [switch]$BuildMap,
  [switch]$BuildAssets,
  [switch]$PreserveLaunchMode,
  [switch]$Launch,
  [string]$SteamPath = ""
)
$ErrorActionPreference = 'Stop'
$PackageRoot = Split-Path -Parent $PSScriptRoot

function Find-DotaRoot {
  param([string]$Requested)
  if ($Requested) { $candidates = @($Requested) }
  else {
    $steamRoots = @()
    if (Test-Path 'HKCU:\Software\Valve\Steam') {
      $steamRoots += (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath
    }
    if (${env:ProgramFiles(x86)}) { $steamRoots += (Join-Path ${env:ProgramFiles(x86)} 'Steam') }
    $candidates = @()
    foreach ($steamRoot in $steamRoots | Select-Object -Unique) {
      if (-not $steamRoot) { continue }
      $libraries = @($steamRoot)
      $vdf = Join-Path $steamRoot 'steamapps/libraryfolders.vdf'
      if (Test-Path $vdf) {
        foreach ($m in [regex]::Matches((Get-Content -Raw $vdf), '"path"\s+"([^"]+)"')) {
          $libraries += $m.Groups[1].Value.Replace('\\', '\')
        }
      }
      foreach ($library in $libraries) { $candidates += (Join-Path $library 'steamapps/common/dota 2 beta') }
    }
  }
  foreach ($candidate in $candidates) {
    if (Test-Path (Join-Path $candidate 'game/bin/win64/dota2.exe')) { return (Resolve-Path $candidate).Path }
  }
  throw 'Dota 2 was not found. Pass -DotaPath "D:\SteamLibrary\steamapps\common\dota 2 beta".'
}

function Assert-Bundle {
  $manifestPath = Join-Path $PackageRoot 'build_manifest.json'
  if (-not (Test-Path $manifestPath)) {
    Write-Host 'Source checkout installation: destination files will be verified against these source files.'
    return
  }
  $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
  foreach ($entry in $manifest.files) {
    if ($entry.path -match '(^|[/\\])\.\.([/\\]|$)' -or [IO.Path]::IsPathRooted($entry.path)) { throw 'Invalid manifest path.' }
    $file = Join-Path $PackageRoot $entry.path
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing bundle file: $($entry.path)" }
    if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256) {
      throw "Bundle checksum mismatch: $($entry.path). Download/extract the archive again."
    }
  }
  Write-Host "Bundle SHA256 verification passed ($($manifest.files.Count) files)."
}

Assert-Bundle
$DotaRoot = Find-DotaRoot $DotaPath
if ($Launch -and (Get-Process -Name dota2 -ErrorAction SilentlyContinue)) {
  throw 'Close Dota 2 and Workshop Tools before launching this build. Lua modules are cached across map restarts.'
}
if (-not $PSCmdlet.ShouldProcess($DotaRoot, "Install DUALITY in $Mode mode; back up changed files")) { return }
$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss-ffff')
$backupRoot = Join-Path $DotaRoot "duality_backups/$AddonName/$stamp"
$copied = 0; $backedUp = 0
foreach ($tree in @('game', 'content')) {
  $sourceRoot = Join-Path $PackageRoot $tree
  if (-not (Test-Path $sourceRoot -PathType Container)) { throw "Missing $tree source tree." }
  $targetRoot = Join-Path $DotaRoot "$tree/dota_addons/$AddonName"
  # Junctions are already live checkouts; writing through them would mutate source
  # and overwrite local work. Use the established link workflow in that case.
  if ((Test-Path $targetRoot) -and ((Get-Item $targetRoot -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    throw "Live link detected: $targetRoot. Use tools/sync_addon.ps1 or install under a different -AddonName."
  }
  foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -Recurse -File) {
    $relative = $file.FullName.Substring($sourceRoot.Length + 1)
    if ($tree -eq 'game' -and $relative.Replace('\', '/') -eq 'scripts/duality_local.kv') { continue }
    $destination = Join-Path $targetRoot $relative
    $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    if (Test-Path -LiteralPath $destination) {
      if ((Get-Item -LiteralPath $destination -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked destination refused: $destination" }
      if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq $sourceHash) { continue }
      $backup = Join-Path $backupRoot "$tree/$relative"
      New-Item -ItemType Directory -Force (Split-Path -Parent $backup) | Out-Null
      Copy-Item -LiteralPath $destination -Destination $backup
      $backedUp++
    }
    New-Item -ItemType Directory -Force (Split-Path -Parent $destination) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $sourceHash) { throw "Installed checksum mismatch: $destination" }
    $copied++
  }
}
$localSettings = Join-Path $DotaRoot "game/dota_addons/$AddonName/scripts/duality_local.kv"
if (-not $PreserveLaunchMode -or -not (Test-Path $localSettings)) {
  $autoDemo = if (-not $PreserveLaunchMode -and $Mode -eq 'Demo') { '1' } else { '0' }
  $settings = '"DualityLocal"' + "`n{`n  " + '"auto_demo" "' + $autoDemo + '"' + "`n}`n"
  if ((Test-Path $localSettings) -and (Get-Content -Raw $localSettings) -ne $settings) {
    $backup = Join-Path $backupRoot 'game/scripts/duality_local.kv'
    New-Item -ItemType Directory -Force (Split-Path -Parent $backup) | Out-Null
    Copy-Item -LiteralPath $localSettings -Destination $backup
    $backedUp++
  }
  [IO.File]::WriteAllText($localSettings, $settings, (New-Object Text.UTF8Encoding($false)))
}
Write-Host "Installed: $copied changed files, $backedUp backups. No extra addon files were deleted."
if ($backedUp) { Write-Host "Backups: $backupRoot" }

function Invoke-DualityCompile {
  param([string]$Source, [string]$Output, [string]$Label)
  $compiler = Join-Path $DotaRoot 'game/bin/win64/resourcecompiler.exe'
  if (-not (Test-Path $compiler)) { throw 'ResourceCompiler is missing. Install Dota 2 Workshop Tools DLC.' }
  $logName = [IO.Path]::GetFileName($Source) + '-' + $stamp + '.log'
  $log = Join-Path $DotaRoot "duality_backups/$AddonName/$logName"
  New-Item -ItemType Directory -Force (Split-Path -Parent $log) | Out-Null
  Write-Host "Compiling $Label with the installed Source 2 ResourceCompiler..."
  $compilerArgs = '-i "' + $Source + '" -game "' + (Join-Path $DotaRoot 'game/dota') + '"'
  $stderrLog = $log + '.stderr'
  $process = Start-Process -FilePath $compiler -ArgumentList $compilerArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError $stderrLog
  $compilerExitCode = $process.ExitCode
  if ((Test-Path $stderrLog) -and (Get-Item $stderrLog).Length -gt 0) {
    Add-Content -LiteralPath $log -Value "`nCompiler stderr:"
    Get-Content -LiteralPath $stderrLog | Add-Content -LiteralPath $log
  }
  Get-Content -LiteralPath $log -Tail 25 | ForEach-Object { Write-Host $_ }
  if ($compilerExitCode -ne 0) { throw "ResourceCompiler failed ($compilerExitCode). Log: $log" }
  if (-not (Test-Path $Output) -or (Get-Item $Output).Length -eq 0 -or (Get-Item $Output).LastWriteTimeUtc -lt (Get-Item $Source).LastWriteTimeUtc) {
    throw "Compiler did not produce a current nonempty output: $Output. Open the source in Workshop Tools and perform a full build. Log: $log"
  }
  Write-Host "Compiled: $Output"
}

$map = if ($Mode -eq 'Demo') { 'dota' } else { 'rift_arena' }
if ($BuildAssets -or $BuildMap -or $Launch) {
  $contentRoot = Join-Path $DotaRoot "content/dota_addons/$AddonName"
  foreach ($pattern in @('*.vtex', '*.vpcf')) {
    foreach ($asset in Get-ChildItem -LiteralPath $contentRoot -Recurse -File -Filter $pattern) {
      $relative = $asset.FullName.Substring($contentRoot.Length + 1)
      $output = Join-Path $DotaRoot ("game/dota_addons/$AddonName/" + $relative + '_c')
      Invoke-DualityCompile -Source $asset.FullName -Output $output -Label $relative
    }
  }
}
if ($BuildMap -or ($Launch -and $Mode -eq 'Match')) {
  $source = Join-Path $DotaRoot "content/dota_addons/$AddonName/maps/rift_arena.vmap"
  $compiled = Join-Path $DotaRoot "game/dota_addons/$AddonName/maps/rift_arena.vmap_c"
  Invoke-DualityCompile -Source $source -Output $compiled -Label 'arena map'
}
Write-Host "Console command: dota_launch_custom_game $AddonName $map"
if ($Launch) {
  if (-not $SteamPath -and (Test-Path 'HKCU:\Software\Valve\Steam')) {
    $SteamPath = (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamExe
  }
  if (-not $SteamPath -and ${env:ProgramFiles(x86)}) { $SteamPath = Join-Path ${env:ProgramFiles(x86)} 'Steam/steam.exe' }
  if (-not $SteamPath -or -not (Test-Path $SteamPath)) { throw 'Steam executable not found. Pass -SteamPath or use the printed console command in Workshop Tools.' }
  Start-Process -FilePath $SteamPath -ArgumentList "-applaunch 570 -tools -console -condebug -addon $AddonName +dota_launch_custom_game $AddonName $map"
  Write-Host 'Steam launch requested. If the Tools launcher opens first, select this addon and use the console command above.'
}
