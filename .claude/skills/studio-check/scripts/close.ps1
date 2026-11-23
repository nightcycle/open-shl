# stops ONE Studio window this run opened, never one that was there before.
#
# usage: powershell -File close.ps1 -Id <process id> -State <dir>
#   -State  the folder open.ps1 kept its opened-pids.txt in (the folder of the place unless it was told otherwise)
#
# the id has to be in opened-pids.txt AND the window still has to name the place it was opened for: a process id is
# handed out again once its process is gone, + the owner has Studio windows of their own. stopping the process saves
# nothing, which is the point: a built place is never saved.
param(
	[Parameter(Mandatory = $true)][int]$Id,
	[Parameter(Mandatory = $true)][string]$State
)
$list = Join-Path $State "opened-pids.txt"
if (-not (Test-Path $list)) { "refused: no opened-pids.txt in $State"; exit 1 }
$place = $null
foreach ($line in Get-Content $list) {
	$parts = $line -split "`t"
	if ($parts.Count -eq 2 -and $parts[0] -eq "$Id") { $place = $parts[1] }
}
if ($null -eq $place) { "refused: $Id was not opened by this run"; exit 1 }
$proc = Get-Process -Id $Id -ErrorAction SilentlyContinue
# between Play + Edit the window is titled plain "RobloxStudio" for a moment, the place is back in it right after
for ($i = 0; $i -lt 6 -and $null -ne $proc -and $proc.MainWindowTitle -notlike "*$(Split-Path $place -Leaf)*"; $i++) {
	Start-Sleep -Seconds 2
	$proc = Get-Process -Id $Id -ErrorAction SilentlyContinue
}
if ($null -eq $proc) { "gone already: $Id" }
elseif ($proc.ProcessName -notlike "RobloxStudio*") { "refused: $Id is $($proc.ProcessName) now"; exit 1 }
elseif ($proc.MainWindowTitle -notlike "*$(Split-Path $place -Leaf)*") { "refused: $Id is titled `"$($proc.MainWindowTitle)`", not $(Split-Path $place -Leaf)"; exit 1 }
else { Stop-Process -Id $Id -Force }
Start-Sleep -Seconds 3
"left: " + ((Get-Process | Where-Object { $_.ProcessName -like "RobloxStudio*" } | ForEach-Object { "$($_.Id) $($_.MainWindowTitle)" }) -join " | ")
