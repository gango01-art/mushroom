# Runs only against a disposable fake Dota tree. Mock compiler != Source 2 validation.
$ErrorActionPreference = 'Stop'
$Repo = Split-Path -Parent $PSScriptRoot
$Installer = Join-Path $Repo 'tools/install_duality.ps1'
$Scratch = Join-Path ([IO.Path]::GetTempPath()) ('duality-install-test-' + [guid]::NewGuid().ToString('N'))
$FakeDota = Join-Path $Scratch 'Dota path with spaces'
$Checks = 0
function Check([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw $Message }; $script:Checks++
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
  if ($env:OS -ne 'Windows_NT') {
    $Compiler = Join-Path $FakeDota 'game/bin/win64/resourcecompiler.exe'
    $Mock = @'
#!/usr/bin/env python3
import pathlib,sys
source=pathlib.Path(sys.argv[sys.argv.index('-i')+1])
assert source.exists(),sys.argv
assert ' ' in str(source), 'Space-containing argument was lost'
game=pathlib.Path(sys.argv[sys.argv.index('-game')+1])
root=game.parents[1]
out=root/'game'/source.relative_to(root/'content')
out=out.with_name(out.name+'_c')
out.parent.mkdir(parents=True,exist_ok=True)
out.write_bytes(b'TEST MOCK ONLY - NOT SOURCE 2')
print('TEST compiler invocation completed')
'@
    [IO.File]::WriteAllText($Compiler, $Mock)
    & /usr/bin/chmod +x $Compiler
    & $Installer -DotaPath $FakeDota -Mode Match -BuildMap
    Check ((Get-Content -Raw $Settings) -match '"auto_demo" "0"') 'Match mode left demo enabled'
    $Compiled = Join-Path $FakeDota 'game/dota_addons/duality/maps/rift_arena.vmap_c'
    Check (Test-Path $Compiled) 'Mock build output missing'
    Check (Test-Path (Join-Path $FakeDota 'game/dota_addons/duality/particles/duality/lc_gold_powershot.vpcf_c')) 'Particle compile not invoked'
    Check (Test-Path (Join-Path $FakeDota 'game/dota_addons/duality/materials/duality/lc_gold_glow.vtex_c')) 'Texture compile not invoked'
    & $Installer -DotaPath $FakeDota -Mode Demo -BuildAssets -PreserveLaunchMode
    Check ((Get-Content -Raw $Settings) -match '"auto_demo" "0"') 'FX-only build changed the launch mode'
    [IO.File]::WriteAllText($Compiler, "#!/usr/bin/env python3`nimport sys`nsys.exit(17)`n")
    $Rejected = $false
    try { & $Installer -DotaPath $FakeDota -BuildMap } catch { $Rejected = $_.Exception.Message -match 'failed \(17\)' }
    Check $Rejected 'Nonzero compiler exit was ignored'
    Remove-Item $Compiled
    Get-ChildItem (Join-Path $FakeDota 'game/dota_addons/duality') -Recurse -File | Where-Object Extension -in @('.vtex_c','.vpcf_c') | Remove-Item
    [IO.File]::WriteAllText($Compiler, "#!/usr/bin/env python3`nprint('NO OUTPUT')`n")
    $Rejected = $false
    try { & $Installer -DotaPath $FakeDota -BuildMap } catch { $Rejected = $_.Exception.Message -match 'did not produce' }
    Check $Rejected 'Zero-exit/no-map build was reported successful'
  }
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
  Write-Host "Installer tests passed: $Checks checks. Compiler tests use a mock; Dota launch/Source 2 are NOT validated."
} finally {
  if (Test-Path $Scratch) { Remove-Item -LiteralPath $Scratch -Recurse -Force }
}
