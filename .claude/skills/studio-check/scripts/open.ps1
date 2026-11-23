# opens one built place in a NEW Roblox Studio window + prints the id of the new process.
#
# usage: powershell -File open.ps1 -Place <path to a .rbxl you built> [-State <dir>] [-Wait <seconds>]
#   -Place  a place built by build-place.sh, somewhere outside the repo. NEVER a legacy place file of the repo
#           (`Superhero Life*.rbxl`, `SHL3 Big Map.rbxl`): those hold backdoor scripts + are refused here
#   -State  where this run keeps what it opened, the folder of the place when left out:
#           before-pids.txt (every Studio that was there before, never touched) + opened-pids.txt (the ones to close)
#
# the owner opens + closes Studio windows of their own while this runs, so a new process only counts as this run's
# when its window title names the place: Studio puts the path of an opened file there. close.ps1 + window.ps1 only
# ever act on a process that's in opened-pids.txt AND still has that title.
param(
	[Parameter(Mandatory = $true)][string]$Place,
	[string]$State = "",
	[int]$Wait = 120
)
$file = Get-Item -LiteralPath $Place -ErrorAction Stop
if ($file.Extension -ne ".rbxl") { "refused: $($file.Name) isn't a place file"; exit 1 }
if ($file.Name -like "Superhero Life*" -or $file.Name -like "SHL3 Big Map*") { "refused: $($file.Name) is a legacy place, those are never opened in Studio"; exit 1 }
if (Test-Path (Join-Path $file.DirectoryName ".git")) { "refused: $($file.FullName) sits in the root of a repo, build the place somewhere outside of it"; exit 1 }
if ($State -eq "") { $State = $file.DirectoryName }
New-Item -ItemType Directory -Force -Path $State | Out-Null

$before = @(Get-Process | Where-Object { $_.ProcessName -like "RobloxStudio*" } | ForEach-Object { $_.Id })
Add-Content -Path (Join-Path $State "before-pids.txt") -Value ("before opening $($file.Name): " + ($before -join ", "))
Start-Process -FilePath $file.FullName
$new = @()
for ($i = 0; $i -lt ($Wait / 2) -and $new.Count -eq 0; $i++) {
	Start-Sleep -Seconds 2
	$new = @(Get-Process | Where-Object {
			$_.ProcessName -like "RobloxStudio*" -and $before -notcontains $_.Id -and $_.MainWindowTitle -like "*$($file.Name)*"
		} | ForEach-Object { $_.Id })
}
if ($new.Count -eq 0) { "no new Studio window names $($file.Name) after $Wait seconds"; exit 1 }
# the window is there before the place + the plugins (the MCP's among them) are loaded
Start-Sleep -Seconds 15
foreach ($id in $new) { Add-Content -Path (Join-Path $State "opened-pids.txt") -Value "$id`t$($file.FullName)" }
"before: $($before -join ', ')"
"new: $($new -join ', ')"
"title: $((Get-Process -Id $new[0]).MainWindowTitle)"
