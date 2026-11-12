# Copies this repository into the owner's Dota 2 addon folders (for setups that
# use copies instead of junctions). Non-destructive: never deletes anything in the
# addon folders; only copies files that are new or newer in the repository.
#
#   powershell -ExecutionPolicy Bypass -File tools\sync_addon.ps1 -WhatIf      # preview
#   powershell -ExecutionPolicy Bypass -File tools\sync_addon.ps1              # copy
#   options: -DotaPath "<...\dota 2 beta>"  -AddonName duality

param(
  [string]$DotaPath = "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta",
  [string]$AddonName = "duality",
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot

$pairs = @(
  @{ Src = (Join-Path $Repo "game");    Dst = (Join-Path $DotaPath "game\dota_addons\$AddonName") },
  @{ Src = (Join-Path $Repo "content"); Dst = (Join-Path $DotaPath "content\dota_addons\$AddonName") }
)

foreach ($p in $pairs) {
  if (-not (Test-Path $p.Src)) { throw "Missing source $($p.Src)" }
  if (-not (Test-Path $p.Dst)) { throw "Addon folder not found: $($p.Dst). Create the addon in Workshop Tools first or pass -AddonName / -DotaPath." }
  $item = Get-Item $p.Dst -Force
  if ($item.LinkType -eq "Junction") { Write-Host "Junction (already live-linked), skipping: $($p.Dst)"; continue }
  # /E subfolders, /XO skip older (never overwrite a newer file in the addon), no /MIR or /PURGE: nothing is deleted.
  $rcArgs = @($p.Src, $p.Dst, "/E", "/XO", "/NJH", "/NP")
  if ($WhatIf) { $rcArgs += "/L" }
  Write-Host "robocopy $($rcArgs -join ' ')"
  & robocopy @rcArgs | Out-Host
  if ($LASTEXITCODE -ge 8) { throw "robocopy failed with code $LASTEXITCODE" }
}
Write-Host "Done. Fully restart the custom game (dota_launch_custom_game $AddonName dota) to load changes."
