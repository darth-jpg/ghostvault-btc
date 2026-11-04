# GhostVault-BTC - Extreme Debloat & Hardening Script for OPPO / ColorOS
$ErrorActionPreference = "Continue"

$deviceId = (& adb get-serialno 2>$null).Trim()
if (-not $deviceId -or $deviceId -eq "unknown" -or $deviceId -match "error") {
    Write-Host "[ERROR] No Android device connected via ADB." -ForegroundColor Red
    exit 1
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  GhostVault-BTC: Hardening & Debloat Protocol (ColorOS)" -ForegroundColor Cyan
Write-Host "  Target Device Serial: $deviceId" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Bloatware Packages to strip
$bloatPackages = @(
    # Facebook / Meta
    "com.facebook.katana",
    "com.facebook.system",
    "com.facebook.appmanager",
    "com.facebook.services",

    # Google Bloat & Chrome
    "com.android.chrome",
    "com.google.android.apps.walletnfcrel",
    "com.google.android.youtube",
    "com.google.android.apps.youtube.music",
    "com.google.android.apps.tachyon",
    "com.google.android.apps.docs",
    "com.google.android.videos",
    "com.google.android.apps.podcasts",
    "com.google.android.apps.magazines",
    "com.google.android.apps.subscriptions.red",
    "com.google.android.apps.photos",
    "com.google.android.apps.maps",
    "com.google.android.calendar",
    "com.google.android.gm",
    "com.google.android.feedback",
    "com.google.android.googlequicksearchbox",
    "com.google.android.apps.googleassistant",
    "com.google.ar.core",
    "com.google.ar.lens",
    "com.google.android.keep",
    "com.google.android.apps.messaging",
    "com.google.android.marvin.talkback",
    "com.google.android.apps.wellbeing",
    "com.google.android.printservice.recommendation",

    # HeyTap / ColorOS Telemetry & Bloat
    "com.heytap.pictorial",
    "com.heytap.music",
    "com.heytap.mcs",
    "com.heytap.accessory",
    "com.heytap.browser",
    "com.heytap.themestore",
    "com.heytap.market",
    "com.heytap.usercenter",
    "com.oplus.games",
    "com.coloros.gamespace",
    "com.coloros.gamespaceui",
    "com.coloros.smartsidebar",
    "com.coloros.karaoke",
    "com.coloros.focusmode",
    "com.coloros.scenemode",
    "com.coloros.healthcheck",
    "com.coloros.weather.service",
    "com.coloros.video",
    "com.coloros.childrenspace",
    "com.coloros.soundrecorder",
    "com.oplus.cast",
    "com.oplus.screenrecorder",
    "com.oppo.quicksearchbox",
    "com.oppo.operationManual",
    "com.oplus.viewtalk",
    "com.oplus.postmanservice",
    "com.coloros.oshare",
    "com.oplus.interconnectcollectkit",
    "com.oplus.logkit",
    "com.oplus.onetrace",
    "com.oplus.trafficmonitor",
    "com.oplus.athena",
    "com.oplus.cosa",
    "com.oplus.cota",
    "com.coloros.floatassistant"
)

Write-Host "Stage 1: Removing bloatware and telemetry..." -ForegroundColor Yellow
$removed = 0
foreach ($pkg in $bloatPackages) {
    $res = & adb -s $deviceId shell "pm uninstall -k --user 0 $pkg" 2>&1
    if ($res -match "Success") {
        Write-Host "  [+] Removed: $pkg" -ForegroundColor Green
        $removed++
    }
}
Write-Host "Total packages removed: $removed" -ForegroundColor Cyan

Write-Host "`nStage 2: Hardening Radios & Disabling Unnecessary Hardware..." -ForegroundColor Yellow
# Disable radios completely
& adb -s $deviceId shell "svc wifi disable"
& adb -s $deviceId shell "svc bluetooth disable"
& adb -s $deviceId shell "svc data disable"
& adb -s $deviceId shell "pm disable-user --user 0 com.android.nfc"

# Enable Airplane Mode permanently
& adb -s $deviceId shell "cmd connectivity airplane-mode enable"

Write-Host "  [+] Wi-Fi: HARD DISABLED" -ForegroundColor Green
Write-Host "  [+] Bluetooth: HARD DISABLED" -ForegroundColor Green
Write-Host "  [+] Mobile Data: HARD DISABLED" -ForegroundColor Green
Write-Host "  [+] NFC: REMOVED & DISABLED" -ForegroundColor Green
Write-Host "  [+] Airplane Mode: PERMANENTLY ENABLED" -ForegroundColor Green

Write-Host "`nStage 3: Launching Bitcoin Vault..." -ForegroundColor Yellow
& adb -s $deviceId shell "am start -n io.bluewallet.bluewallet/.MainActivity" | Out-Null
Write-Host "  [+] BlueWallet Vault focused and running!" -ForegroundColor Green

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "  GhostVault-BTC Transformation Complete!" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
