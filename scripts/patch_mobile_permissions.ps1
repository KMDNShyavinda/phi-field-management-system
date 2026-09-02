param(
  [string]$MobileDir = (Join-Path $PSScriptRoot "..\mobile")
)

$manifest = Join-Path $MobileDir "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
  $xml = Get-Content $manifest -Raw
  $permissions = @(
    '    <uses-permission android:name="android.permission.INTERNET"/>',
    '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
    '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>',
    '    <uses-permission android:name="android.permission.CAMERA"/>'
  )
  foreach ($line in $permissions) {
    $name = [regex]::Match($line, 'android:name="([^"]+)"').Groups[1].Value
    if ($xml -notmatch [regex]::Escape($name)) {
      $xml = $xml -replace '<manifest[^>]*>', "`$0`r`n$line"
    }
  }
  Set-Content -Path $manifest -Value $xml
  Write-Host "Patched $manifest"
}

$plist = Join-Path $MobileDir "ios\Runner\Info.plist"
if (Test-Path $plist) {
  $info = Get-Content $plist -Raw
  $pairs = @{
    "NSCameraUsageDescription" = "Capture inspection evidence photos."
    "NSLocationWhenInUseUsageDescription" = "Record GPS on inspections and evidence photos."
    "NSPhotoLibraryUsageDescription" = "Attach evidence photos from the library when the camera is unavailable."
  }
  foreach ($key in $pairs.Keys) {
    if ($info -notmatch $key) {
      $block = "	<key>$key</key>`r`n	<string>$($pairs[$key])</string>`r`n"
      $info = $info -replace '</dict>', "$block</dict>"
    }
  }
  Set-Content -Path $plist -Value $info
  Write-Host "Patched $plist"
}
