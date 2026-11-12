# Links this repository into the Dota 2 addon trees with directory junctions.
# Non-destructive: refuses to touch an existing folder that is not already our junction.
#
#   powershell -ExecutionPolicy Bypass -File tools\link_addon.ps1            # auto-detect Dota
#   powershell -ExecutionPolicy Bypass -File tools\link_addon.ps1 -DotaPath "D:\SteamLibrary\steamapps\common\dota 2 beta"
#   add -WhatIf to only print what would happen.

param(
  [string]$DotaPath = "",
  [string]$AddonName = "rift_arena",
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot

function Find-Dota {
  $steam = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
  if (-not $steam) { throw "Steam not found in registry. Pass -DotaPath." }
  $libs = @($steam)
  $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
  if (Test-Path $vdf) {
    foreach ($m in (Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' -AllMatches).Matches) {
      $libs += ($m.Groups[1].Value -replace '\\\\', '\')
    }
  }
  foreach ($l in ($libs | Select-Object -Unique)) {
    $p = Join-Path $l "steamapps\common\dota 2 beta"
    if (Test-Path (Join-Path $p "game\dota")) { return $p }
  }
  throw "Dota 2 not found in Steam libraries: $($libs -join ', '). Pass -DotaPath."
}

if (-not $DotaPath) { $DotaPath = Find-Dota }
Write-Host "Dota 2: $DotaPath"

$gameAddons = Join-Path $DotaPath "game\dota_addons"
$contentAddons = Join-Path $DotaPath "content\dota_addons"
if (-not (Test-Path $gameAddons) -or -not (Test-Path $contentAddons)) {
  throw "game\dota_addons or content\dota_addons missing. Install 'Dota 2 Workshop Tools' DLC and launch Tools once."
}

$links = @(
  @{ Link = (Join-Path $gameAddons $AddonName);    Target = (Join-Path $Repo "game") },
  @{ Link = (Join-Path $contentAddons $AddonName); Target = (Join-Path $Repo "content") }
)

foreach ($l in $links) {
  if (Test-Path $l.Link) {
    $item = Get-Item $l.Link -Force
    if ($item.LinkType -eq "Junction" -and ($item.Target -contains $l.Target -or "$($item.Target)" -eq $l.Target)) {
      Write-Host "OK (already linked): $($l.Link) -> $($l.Target)"
      continue
    }
    Write-Warning "EXISTS, not touching: $($l.Link). Move/rename it yourself if it is an old copy."
    continue
  }
  if ($WhatIf) { Write-Host "Would link: $($l.Link) -> $($l.Target)"; continue }
  New-Item -ItemType Junction -Path $l.Link -Target $l.Target | Out-Null
  Write-Host "Linked: $($l.Link) -> $($l.Target)"
}
Write-Host "Done. Launch Dota 2 Workshop Tools and choose addon '$AddonName'."
