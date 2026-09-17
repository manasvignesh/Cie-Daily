$ErrorActionPreference = 'Stop'
$package = Join-Path $PSScriptRoot 'out/breakpoint-launch-source'
New-Item -ItemType Directory -Force $package,(Join-Path $package 'public/footage') | Out-Null
foreach ($name in @('src','package.json','package-lock.json','README.md','sound.cjs','prepare.cjs','capture.ps1','verify.cjs','finish.cjs','.gitignore')) {
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $package -Recurse -Force
}
foreach ($name in @('Outfit.ttf','OFL-Outfit.txt','soundtrack.wav','soundtrack-master.wav')) {
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot "public/$name") -Destination (Join-Path $package 'public') -Force
}
# Only render-ready, reviewed assets. No raw conversation history or UI dumps.
foreach ($name in @('discover-alt-clean.mp4','deck-clean.mp4','article-clean.mp4','listen-clean.mp4','spaces-clean.mp4','reels-clean.mp4','connect-detail.mp4','connect-sent-detail.png','chat-header.png','deck-panel.png','listen-panel.png','discover-poster.png','deck-poster.png','spaces-poster.png')) {
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot "public/footage/$name") -Destination (Join-Path $package 'public/footage') -Force
}
New-Item -ItemType Directory -Force (Join-Path $package 'review') | Out-Null
foreach ($name in @('PRODUCTION_REVIEW.md','technical-verification.json','audio-measurement.txt')) {
  $source = Join-Path $PSScriptRoot "review/$name"
  if (Test-Path -LiteralPath $source) { Copy-Item -LiteralPath $source -Destination (Join-Path $package 'review') -Force }
}
Compress-Archive -LiteralPath $package -DestinationPath (Join-Path $PSScriptRoot 'out/breakpoint_launch_remotion_source.zip') -Force
Write-Output 'Packaged editable source and reviewed media; no private raw captures included.'
