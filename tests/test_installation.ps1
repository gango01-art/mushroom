# Runs only against a disposable fake Dota tree. Mock compiler != Source 2 validation.
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $Repo 'tools/install_duality.ps1'
$Scratch = Join-Path ([IO.Path]::GetTempPath()) ('duality-install-test-' + [guid]::NewGuid().ToString('N'))
$FakeDota = Join-Path $Scratch 'Dota path with spaces'
$global:DualityInstallChecks = 0
function Check([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }; $global:DualityInstallChecks++
}
try {
  # Parse all launch scripts before executing any install.
  $tokens = $null; $parseErrors = $null
  [Management.Automation.Language.Parser]::ParseFile($Installer, [ref]$tokens, [ref]$parseErrors) | Out-Null
  Check ($parseErrors.Count -eq 0) 'Installer parse error'
  New-Item -ItemType Directory -Force (Join-Path $FakeDota 'game/bin/win64') | Out-Null
  New-Item -ItemType File (Join-Path $FakeDota 'game/bin/win64/dota2.exe') | Out-Null
  & $Installer -DotaPath $FakeDota -Mode Demo -WhatIf
  Check (-not (Test-Path (Join-Path $FakeDota 'game/dota_addons'))) 'WhatIf wrote addon files'
  $OwnerFile = Join-Path $FakeDota 'game/dota_addons/duality/scripts/vscripts/addon_game_mode.lua'
  New-Item -ItemType Directory -Force (Split-Path -Parent $OwnerFile) | Out-Null
  [IO.File]::WriteAllText($OwnerFile, 'owner-local-work')
  $Extra = Join-Path $FakeDota 'game/dota_addons/duality/owner-extra.txt'
  [IO.File]::WriteAllText($Extra, 'keep-this')
  & $Installer -DotaPath $FakeDota -Mode Demo
  Check ((Get-FileHash $OwnerFile).Hash -eq (Get-FileHash (Join-Path $Repo 'game/scripts/vscripts/addon_game_mode.lua')).Hash) 'Wrong installed source'
  $Backups = @(Get-ChildItem (Join-Path $FakeDota 'duality_backups') -Recurse -File | Where-Object Name -eq 'addon_game_mode.lua')
  Check ($Backups.Count -eq 1) 'Changed owner file not backed up exactly once'
  Check ((Get-Content -Raw $Backups[0].FullName) -eq 'owner-local-work') 'Backup content incorrect'
  Check ((Get-Content -Raw $Extra) -eq 'keep-this') 'Unknown owner file deleted'
  $Settings = Join-Path $FakeDota 'game/dota_addons/duality/scripts/duality_local.kv'
  Check ((Get-Content -Raw $Settings) -match '"auto_demo" "1"') 'Demo autostart not configured'
  & $Installer -DotaPath $FakeDota -Mode Demo
  $Again = @(Get-ChildItem (Join-Path $FakeDota 'duality_backups') -Recurse -File | Where-Object Name -eq 'addon_game_mode.lua')
  Check ($Again.Count -eq 1) 'Repeat install overwrote unchanged files'
  # Mock the process boundary on every OS, including Windows. This proves the
  # install plan/failure handling; real ResourceCompiler validation is separate.
  $Compiler = Join-Path $FakeDota 'game/bin/win64/resourcecompiler.exe'
  New-Item -ItemType File -Path $Compiler | Out-Null
  $global:DualityInstallTest = @{Inputs=@(); Mode='ok'; Root=$FakeDota; Compiler=$Compiler}
  function Start-Process {
    param($FilePath, $ArgumentList, [switch]$Wait, [switch]$PassThru,
      $WindowStyle, $RedirectStandardOutput, $RedirectStandardError)
    if ($FilePath -ne $global:DualityInstallTest.Compiler) { throw 'Unexpected process in installer test' }
    Check ($ArgumentList -match '^-f -nop4 ') 'Forced resource rebuild not requested'
    Check ($WindowStyle -eq 'Hidden') 'Compiler helper should be hidden'
    $source = [regex]::Match($ArgumentList, '-i "([^"]+)"').Groups[1].Value
    Check (Test-Path -LiteralPath $source) 'Compiler source argument lost'
    $global:DualityInstallTest.Inputs += $source
    [IO.File]::WriteAllText($RedirectStandardOutput, 'MOCK ONLY - NOT SOURCE 2')
    [IO.File]::WriteAllText($RedirectStandardError, '')
    if ($global:DualityInstallTest.Mode -eq 'fail') { return [pscustomobject]@{ExitCode=17} }
    if ($global:DualityInstallTest.Mode -eq 'ok') {
      $relative = $source.Substring((Join-Path $global:DualityInstallTest.Root 'content').Length+1)
      $output = Join-Path $global:DualityInstallTest.Root ('game/' + $relative)
      $extension = [IO.Path]::GetExtension($output)
      if ($extension -in @('.js','.css','.xml')) {
        $output = [IO.Path]::ChangeExtension($output, 'v' + $extension.Substring(1) + '_c')
      } else { $output += '_c' }
      New-Item -ItemType Directory -Force (Split-Path -Parent $output) | Out-Null
      [IO.File]::WriteAllText($output, 'MOCK ONLY - NOT SOURCE 2')
    }
    return [pscustomobject]@{ExitCode=0}
  }
  $OldLayout = Join-Path $FakeDota 'game/dota_addons/duality/panorama/layout/custom_game/rift_hud.vxml_c'
  New-Item -ItemType Directory -Force (Split-Path -Parent $OldLayout) | Out-Null
  [IO.File]::WriteAllText($OldLayout, 'owner-old-compiled-layout')
  $ExtraSource = Join-Path $FakeDota 'content/dota_addons/duality/owner-extra.vpcf'
  [IO.File]::WriteAllText($ExtraSource, 'owner-resource-not-in-package')
  & $Installer -DotaPath $FakeDota -Mode Match -BuildMap
  Check ((Get-Content -Raw $Settings) -match '"auto_demo" "0"') 'Match mode left demo enabled'
  $outputs = @(
    'panorama/scripts/custom_game/rift_ui_model.vjs_c',
    'panorama/scripts/custom_game/rift_hud.vjs_c',
    'panorama/scripts/custom_game/rift_lab.vjs_c',
    'panorama/styles/custom_game/rift_hud.vcss_c',
    'panorama/layout/custom_game/rift_hud.vxml_c',
    'panorama/layout/custom_game/custom_ui_manifest.vxml_c',
    'materials/duality/lc_gold_glow.vtex_c',
    'particles/duality/lc_gold_powershot.vpcf_c',
    'maps/rift_arena.vmap_c'
  )
  foreach ($relative in $outputs) {
    Check (Test-Path (Join-Path $FakeDota ('game/dota_addons/duality/' + $relative))) ("Build output missing: " + $relative)
  }
  Check ($global:DualityInstallTest.Inputs.Count -eq 9) 'Unexpected compile count (six Panorama, two FX, one map)'
  Check ($global:DualityInstallTest.Inputs[0] -like '*rift_ui_model.js') 'Panorama model must build before HUD'
  Check (-not ($global:DualityInstallTest.Inputs -contains $ExtraSource)) 'Unrelated owner resource was compiled'
  $LayoutBackups = @(Get-ChildItem (Join-Path $FakeDota 'duality_backups') -Recurse -File | Where-Object Name -eq 'rift_hud.vxml_c')
  Check ($LayoutBackups.Count -eq 1) 'Old compiled layout not backed up'
  Check ((Get-Content -Raw $LayoutBackups[0].FullName) -eq 'owner-old-compiled-layout') 'Compiled backup content changed'
  & $Installer -DotaPath $FakeDota -Mode Demo -BuildAssets -PreserveLaunchMode
  Check ((Get-Content -Raw $Settings) -match '"auto_demo" "0"') 'Assets-only build changed the launch mode'
  $global:DualityInstallTest.Mode = 'fail'; $Rejected = $false
  try { & $Installer -DotaPath $FakeDota -BuildAssets } catch { $Rejected = $_.Exception.Message -match 'failed \(17\)' }
  Check $Rejected 'Nonzero Panorama compiler exit was ignored'
  $ModelOutput = Join-Path $FakeDota ('game/dota_addons/duality/' + $outputs[0])
  Remove-Item -LiteralPath $ModelOutput
  $global:DualityInstallTest.Mode = 'no-output'; $Rejected = $false
  try { & $Installer -DotaPath $FakeDota -BuildAssets } catch { $Rejected = $_.Exception.Message -match 'did not produce' }
  Check $Rejected 'Zero-exit/missing Panorama output was reported successful'
  [IO.File]::WriteAllText($ModelOutput, 'stale')
  (Get-Item -LiteralPath $ModelOutput).LastWriteTimeUtc = [datetime]::UtcNow.AddYears(-1)
  $Rejected = $false
  try { & $Installer -DotaPath $FakeDota -BuildAssets } catch { $Rejected = $_.Exception.Message -match 'did not produce' }
  Check $Rejected 'Zero-exit/stale Panorama output was reported successful'
  [IO.File]::WriteAllText($ModelOutput, '')
  $Rejected = $false
  try { & $Installer -DotaPath $FakeDota -BuildAssets } catch { $Rejected = $_.Exception.Message -match 'did not produce' }
  Check $Rejected 'Zero-exit/empty Panorama output was reported successful'
  # Corrupted distribution files are rejected BEFORE any destination write.
  $Bundle = Join-Path $Scratch 'bundle'
  New-Item -ItemType Directory -Force (Join-Path $Bundle 'tools') | Out-Null
  Copy-Item $Installer (Join-Path $Bundle 'tools/install_duality.ps1')
  $Payload = Join-Path $Bundle 'payload.txt';[IO.File]::WriteAllText($Payload, 'original')
  $Manifest = @{ files = @(@{path='payload.txt';sha256=(Get-FileHash $Payload).Hash.ToLowerInvariant()}) } | ConvertTo-Json -Depth 4
  [IO.File]::WriteAllText((Join-Path $Bundle 'build_manifest.json'), $Manifest)
  [IO.File]::WriteAllText($Payload, 'corrupted')
  $Rejected = $false
  try { & (Join-Path $Bundle 'tools/install_duality.ps1') -DotaPath $FakeDota } catch { $Rejected = $_.Exception.Message -match 'checksum mismatch' }
  Check $Rejected 'Corrupt bundle passed checksum validation'
  Write-Host "Installer tests passed: $global:DualityInstallChecks checks. Compiler tests use a mock; Dota launch/Source 2 are NOT validated."
} finally {
  Remove-Variable -Name DualityInstallTest,DualityInstallChecks -Scope Global -ErrorAction SilentlyContinue
  if (Test-Path $Scratch) {
    $resolvedScratch = (Resolve-Path -LiteralPath $Scratch).Path
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not $resolvedScratch.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path -Leaf $resolvedScratch) -notmatch '^duality-install-test-[a-f0-9]{32}$') { throw 'Unsafe scratch cleanup path' }
    Remove-Item -LiteralPath $resolvedScratch -Recurse -Force
  }
}
