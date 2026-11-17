param(
  [string]$LoveDir = "d:\CursorProject\rollKnight\tools\love-11.5-win64"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$zipPath = Join-Path $dist "rollKnight.zip"
$loveFile = Join-Path $dist "rollKnight.love"
$exeFile = Join-Path $dist "rollKnight.exe"

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
if (Test-Path $loveFile) { Remove-Item $loveFile -Force }

Compress-Archive -Path (Join-Path $root "conf.lua"), (Join-Path $root "main.lua"), (Join-Path $root "src"), (Join-Path $root "tests") -DestinationPath $zipPath -Force
Move-Item $zipPath $loveFile -Force

$loveExe = Join-Path $LoveDir "love.exe"
if (-not (Test-Path $loveExe)) {
  throw "love.exe not found at $loveExe"
}

cmd /c copy /b "`"$loveExe`"+`"$loveFile`"" "`"$exeFile`"" | Out-Null
Get-ChildItem -LiteralPath $LoveDir -Filter "*.dll" | ForEach-Object {
  Copy-Item $_.FullName -Destination $dist -Force
}
Copy-Item (Join-Path $LoveDir "license.txt") -Destination $dist -Force -ErrorAction SilentlyContinue

Write-Output "Built standalone executable at: $exeFile"
