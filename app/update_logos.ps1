Add-Type -AssemblyName System.Drawing

$sourcePath = "C:\Users\Manas\.gemini\antigravity\brain\ced04f0b-5034-4d98-9143-86a3ee1af515\.user_uploaded\media_1788445484943.jpg"
$srcImg = [System.Drawing.Image]::FromFile($sourcePath)

function Resize-And-Save($targetPath, $width, $height) {
    $dir = [System.IO.Path]::GetDirectoryName($targetPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $bmp = New-Object System.Drawing.Bitmap($width, $height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcImg, 0, 0, $width, $height)
    $bmp.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Updated: $targetPath ($width x $height)"
}

# Flutter App Asset PNGs (512x512)
Resize-And-Save "C:\Users\Public\New67\app\assets\icons\app_logo.png" 512 512
Resize-And-Save "C:\Users\Public\New67\app\assets\illustrations\app_logo.png" 512 512
Resize-And-Save "C:\Users\Public\New67\app\assets\illustrations\cie_daily_splash_logo.png" 512 512
Resize-And-Save "C:\Users\Public\New67\app\assets\illustrations\cie_daily_splash_emblem.png" 512 512
Resize-And-Save "C:\Users\Public\New67\app\assets\illustrations\splash_poster.png" 512 512
Resize-And-Save "C:\Users\Public\New67\assets\icons\app_logo.png" 512 512
Resize-And-Save "C:\Users\Public\New67\assets\illustrations\app_logo.png" 512 512

# Android Launcher Mipmap Icons
Resize-And-Save "C:\Users\Public\New67\app\android\app\src\main\res\mipmap-mdpi\ic_launcher.png" 48 48
Resize-And-Save "C:\Users\Public\New67\app\android\app\src\main\res\mipmap-hdpi\ic_launcher.png" 72 72
Resize-And-Save "C:\Users\Public\New67\app\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png" 96 96
Resize-And-Save "C:\Users\Public\New67\app\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" 144 144
Resize-And-Save "C:\Users\Public\New67\app\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" 192 192

$srcImg.Dispose()
Write-Host "Logo and launcher icons updated successfully!"
