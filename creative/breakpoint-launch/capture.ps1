param([string]$Name, [int]$Seconds = 8, [string]$Gesture = 'none')
$adb = 'C:\Users\Manas\AppData\Local\Android\Sdk\platform-tools\adb.exe'
$remote = "/sdcard/bp-$Name.mp4"
$take = Start-Process -FilePath $adb -ArgumentList @('-s','RZCY329AH3J','shell','screenrecord','--bit-rate','20000000','--time-limit',"$Seconds",$remote) -WindowStyle Hidden -PassThru
Start-Sleep -Seconds 2
switch ($Gesture) {
  'scroll' { & $adb -s RZCY329AH3J shell input swipe 540 1780 540 1080 850 }
  'listen' { & $adb -s RZCY329AH3J shell input tap 863 1190 }
  'category' { & $adb -s RZCY329AH3J shell input tap 640 640 }
  'send' { & $adb -s RZCY329AH3J shell input tap 960 2055 }
}
$take.WaitForExit()
& $adb -s RZCY329AH3J pull $remote "$PSScriptRoot/public/footage/$Name.mp4"
& $adb -s RZCY329AH3J shell screencap -p /sdcard/breakpoint-capture.png
& $adb -s RZCY329AH3J pull /sdcard/breakpoint-capture.png "$PSScriptRoot/review/current.png"
