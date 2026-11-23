# a picture of ONE Studio window this run opened, drawn by the window itself (PrintWindow): the engine's own UI is in
# it (the top bar, the stock player list, the hotbar, the chat, Studio's panels), which the MCP's screen_capture leaves
# out. nothing else on the screen is read, no input is sent, the window is not moved, raised or focused.
#
# usage: powershell -File window.ps1 -Id <process id> -State <dir> -Out <file.png> [-Scale 0.5] [-Box x,y,w,h]
#   -State  the folder open.ps1 kept its opened-pids.txt in
#   -Scale  the picture is the whole window scaled by this, 1 for every pixel
#   -Box    cuts the picture to a box of the window, in the window's own pixels, before it's scaled: run once without
#           it to see where the 3D view lies (it depends on how the owner has Studio's panels laid out)
#
# a window that's minimized, or a display that's asleep, has nothing to draw: the picture comes back black or stale.
# never send input to wake either. say what could not be seen instead.
param(
	[Parameter(Mandatory = $true)][int]$Id,
	[Parameter(Mandatory = $true)][string]$State,
	[Parameter(Mandatory = $true)][string]$Out,
	[double]$Scale = 0.5,
	[int[]]$Box = @()
)
$list = Join-Path $State "opened-pids.txt"
if (-not (Test-Path $list)) { "refused: no opened-pids.txt in $State"; exit 1 }
$place = $null
foreach ($line in Get-Content $list) {
	$parts = $line -split "`t"
	if ($parts.Count -eq 2 -and $parts[0] -eq "$Id") { $place = $parts[1] }
}
if ($null -eq $place) { "refused: $Id was not opened by this run"; exit 1 }
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class StudioCheckWindow {
	[StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
	[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
	[DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdc, uint flags);
	[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
	[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
"@
[StudioCheckWindow]::SetProcessDPIAware() | Out-Null
$proc = Get-Process -Id $Id -ErrorAction Stop
if ($proc.MainWindowTitle -notlike "*$(Split-Path $place -Leaf)*") { "refused: $Id is titled `"$($proc.MainWindowTitle)`", not $(Split-Path $place -Leaf)"; exit 1 }
$h = $proc.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { "no window"; exit 1 }
if ([StudioCheckWindow]::IsIconic($h)) { "the window is minimized: nothing to draw"; exit 1 }
$r = New-Object StudioCheckWindow+RECT
[StudioCheckWindow]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $ht = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $ht
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
# 2 = PW_RENDERFULLCONTENT: without it a window that draws with the gpu comes back black
$ok = [StudioCheckWindow]::PrintWindow($h, $hdc, 2)
$g.ReleaseHdc($hdc); $g.Dispose()
$source = $bmp
if ($Box.Count -eq 4) {
	$source = $bmp.Clone((New-Object System.Drawing.Rectangle $Box[0], $Box[1], $Box[2], $Box[3]), $bmp.PixelFormat)
}
$small = New-Object System.Drawing.Bitmap ([int]($source.Width * $Scale)), ([int]($source.Height * $Scale))
$g2 = [System.Drawing.Graphics]::FromImage($small)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.DrawImage($source, 0, 0, $small.Width, $small.Height); $g2.Dispose()
New-Item -ItemType Directory -Force -Path (Split-Path $Out) | Out-Null
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$small.Dispose(); if ($source -ne $bmp) { $source.Dispose() }; $bmp.Dispose()
"${w} x ${ht} at $($r.Left),$($r.Top), drawn $ok -> $Out ($([int]($w * $Scale)) wide unless boxed)"
