Add-Type -AssemblyName System.Drawing

function Generate-BreakpointIcon {
    param (
        [string]$outputPath,
        [int]$size
    )

    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    # 1. Fill Ink Black Background (#080B0C)
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#080B0C"))
    $graphics.FillRectangle($bgBrush, 0, 0, $size, $size)

    # 2. Draw the interrupted orange stem.
    $linePen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#FF6A1A")), ($size * 0.065)
    $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawLine($linePen, $size * 0.34, $size * 0.27, $size * 0.34, $size * 0.445)
    $graphics.DrawLine($linePen, $size * 0.34, $size * 0.61, $size * 0.34, $size * 0.78)

    # 3. Draw the warm-white twin arcs that form the B silhouette.
    $arcPen = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#EDE9E0")), ($size * 0.065)
    $arcPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $arcPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $graphics.DrawBezier($arcPen, $size * 0.405, $size * 0.28, $size * 0.69, $size * 0.28, $size * 0.76, $size * 0.42, $size * 0.54, $size * 0.53)
    $graphics.DrawBezier($arcPen, $size * 0.405, $size * 0.53, $size * 0.73, $size * 0.53, $size * 0.78, $size * 0.77, $size * 0.405, $size * 0.78)

    # 4. Signal dot: the breakpoint that completes the mark.
    $dotBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#FF6A1A"))
    $dotSize = $size * 0.105
    $dotX = ($size * 0.34) - ($dotSize / 2)
    $dotY = ($size * 0.53) - ($dotSize / 2)
    $graphics.FillEllipse($dotBrush, $dotX, $dotY, $dotSize, $dotSize)

    # 5. Save to PNG
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $bgBrush.Dispose()
    $linePen.Dispose()
    $arcPen.Dispose()
    $dotBrush.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$appRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$repoRoot = (Resolve-Path (Join-Path $appRoot "..")).Path
$resDir = Join-Path $appRoot "android\app\src\main\res"

$sizes = @{
    "mipmap-mdpi"    = 48
    "mipmap-hdpi"    = 72
    "mipmap-xhdpi"   = 96
    "mipmap-xxhdpi"  = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($target in $sizes.GetEnumerator()) {
    $folder = Join-Path $resDir $target.Key
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
    $iconPath = Join-Path $folder "ic_launcher.png"
    $roundIconPath = Join-Path $folder "ic_launcher_round.png"

    Generate-BreakpointIcon -outputPath $iconPath -size $target.Value
    Generate-BreakpointIcon -outputPath $roundIconPath -size $target.Value
    Write-Host "Generated $($target.Key) icon ($($target.Value)x$($target.Value))"
}

# Web Icon 512x512
$webIconPath = Join-Path $appRoot "android\app\src\main\ic_launcher-web.png"
Generate-BreakpointIcon -outputPath $webIconPath -size 512
Write-Host "Generated Web Launcher Icon 512x512"

# Canonical in-app/export assets.
$assetTargets = @(
    (Join-Path $appRoot "assets\icons\app_logo.png"),
    (Join-Path $appRoot "assets\illustrations\app_logo.png"),
    (Join-Path $repoRoot "assets\icons\app_logo.png"),
    (Join-Path $repoRoot "assets\illustrations\app_logo.png")
)
foreach ($assetPath in $assetTargets) {
    Generate-BreakpointIcon -outputPath $assetPath -size 1024
    Write-Host "Generated $assetPath"
}
