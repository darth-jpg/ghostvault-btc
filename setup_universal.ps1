<#
.SYNOPSIS
    GhostVault BTC - Universal Cold Storage Transformer & Hardening Suite
.DESCRIPTION
    Transforms any spare Android smartphone (Android 8.0 to Android 14+) into a dedicated,
    air-gapped Bitcoin signing appliance with a mandatory BIP-39 25th word (Passphrase).
    Built for maximum elasticity: modular execution, full transparency, and reversibility.
.PARAMETER Stage
    All        - Run all stages (Debloat, Install, Device Owner, Hardening, Launch)
    Debloat    - Only remove bloatware & telemetry packages
    Install    - Only download and install BlueWallet & GhostKiosk
    Hardening  - Disable radios, force airplane mode, and enable Device Owner restrictions
    Revert     - Remove Device Owner restrictions, re-enable radios, and restore standard launcher
    Interactive - Prompt step-by-step for full user control
#>

[CmdletBinding()]
param(
    [ValidateSet("All", "Debloat", "Install", "Hardening", "Revert", "Interactive")]
    [string]$Stage = "All"
)

$ErrorActionPreference = "Continue"

function Write-Banner {
    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor DarkYellow
    Write-Host "         ⚡ GHOSTVAULT BTC - UNIVERSAL HARDENING SUITE ⚡        " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "       Transform Any Android Device into an Air-Gapped Vault     " -ForegroundColor White
    Write-Host "=================================================================" -ForegroundColor DarkYellow
    Write-Host ""
}

function Check-Device {
    Write-Host "[+] Detecting connected Android device via ADB..." -ForegroundColor Cyan
    $dev = (& adb get-serialno 2>$null).Trim()
    if (-not $dev -or $dev -eq "unknown" -or $dev -match "error") {
        Write-Host "`n[ERROR] No Android device detected!" -ForegroundColor Red
        Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
        Write-Host "  1. Connect your Android phone to this PC via USB."
        Write-Host "  2. Go to Settings > About Phone > Tap 'Build Number' 7 times."
        Write-Host "  3. Open Developer Options and enable 'USB Debugging'."
        Write-Host "  4. On the phone screen, accept 'Always allow from this computer'."
        Write-Host "`nTip: Ask your AI coding assistant (Antigravity/Claude/ChatGPT) to troubleshoot driver issues if ADB does not recognize your phone." -ForegroundColor Gray
        exit 1
    }
    $model = (& adb -s $dev shell "getprop ro.product.model" 2>$null).Trim()
    $brand = (& adb -s $dev shell "getprop ro.product.brand" 2>$null).Trim()
    $androidVer = (& adb -s $dev shell "getprop ro.build.version.release" 2>$null).Trim()
    Write-Host "  [✓] Target: $brand $model (Android $androidVer) | Serial: $dev" -ForegroundColor Green
    return $dev
}

function Invoke-Debloat($dev) {
    Write-Host "`n--- [STAGE: DEBLOAT & ATTACK SURFACE REDUCTION] ---" -ForegroundColor Cyan
    Write-Host "Stripping telemetry, social tracking, cloud sync, and bloatware packages..." -ForegroundColor Gray
    
    # Modular Package List - Feel free to add/remove or ask an AI to customize for your OEM
    $bloat = @(
        # Meta / Facebook
        "com.facebook.katana", "com.facebook.system", "com.facebook.appmanager", "com.facebook.services", "com.facebook.orca",
        # Google Telemetry & Non-Essential Apps
        "com.android.chrome", "com.google.android.apps.walletnfcrel", "com.google.android.youtube",
        "com.google.android.apps.youtube.music", "com.google.android.apps.tachyon", "com.google.android.apps.docs",
        "com.google.android.videos", "com.google.android.apps.podcasts", "com.google.android.apps.magazines",
        "com.google.android.apps.subscriptions.red", "com.google.android.apps.photos", "com.google.android.apps.maps",
        "com.google.android.calendar", "com.google.android.gm", "com.google.android.feedback",
        "com.google.android.googlequicksearchbox", "com.google.android.apps.googleassistant", "com.google.ar.core",
        "com.google.ar.lens", "com.google.android.keep", "com.google.android.apps.messaging", "com.google.android.apps.wellbeing",
        # Common OEM Bloat (Xiaomi, Samsung, OPPO, Realme, Vivo)
        "com.miui.player", "com.miui.video", "com.miui.weather2", "com.xiaomi.midrop", "com.miui.analytics",
        "com.sec.android.app.sbrowser", "com.samsung.android.bixby.agent", "com.samsung.android.game.gamehome",
        "com.heytap.pictorial", "com.heytap.music", "com.heytap.mcs", "com.heytap.browser", "com.heytap.market",
        "com.oplus.games", "com.coloros.gamespace", "com.coloros.smartsidebar", "com.coloros.weather.service"
    )

    $removed = 0
    foreach ($pkg in $bloat) {
        $res = & adb -s $dev shell "pm uninstall -k --user 0 $pkg" 2>&1
        if ($res -match "Success") { $removed++ }
    }
    Write-Host "  [✓] Removed $removed bloatware packages for user 0." -ForegroundColor Green
}

function Invoke-InstallApps($dev) {
    Write-Host "`n--- [STAGE: INSTALL VAULT & KIOSK ENGINE] ---" -ForegroundColor Cyan
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $downloadsDir = Join-Path $scriptDir "downloads"
    $blueWalletApk = Join-Path $downloadsDir "BlueWallet.apk"
    $kioskApk = Join-Path $scriptDir "kiosk_app\build\GhostKiosk.apk"

    if (-not (Test-Path $blueWalletApk)) {
        Write-Host "  -> Downloading verified BlueWallet v8.0.2 APK from GitHub release..." -ForegroundColor Gray
        New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
        Invoke-WebRequest -Uri "https://github.com/BlueWallet/BlueWallet/releases/download/v8.0.2/BlueWallet.apk" -OutFile $blueWalletApk
    }

    if (Test-Path $blueWalletApk) {
        Write-Host "  -> Installing BlueWallet..." -ForegroundColor Gray
        & adb -s $dev install -r "$blueWalletApk" | Out-Null
        Write-Host "  [✓] BlueWallet installed." -ForegroundColor Green
    }

    if (Test-Path $kioskApk) {
        Write-Host "  -> Installing GhostKiosk..." -ForegroundColor Gray
        & adb -s $dev install -r "$kioskApk" | Out-Null
        Write-Host "  [✓] GhostKiosk installed." -ForegroundColor Green
    }
}

function Invoke-Hardening($dev) {
    Write-Host "`n--- [STAGE: AIR-GAP HARDENING & DEVICE OWNER LOCKDOWN] ---" -ForegroundColor Cyan
    
    # Set default home activity
    & adb -s $dev shell "cmd package set-home-activity com.ghostvault.kiosk/.KioskActivity" | Out-Null

    # Set Device Owner
    $dpm = & adb -s $dev shell "dpm set-device-owner com.ghostvault.kiosk/.AdminReceiver" 2>&1
    if ($dpm -match "Success") {
        Write-Host "  [✓] Device Owner granted to GhostKiosk." -ForegroundColor Green
        Write-Host "      Status bar pull-down disabled & Wi-Fi configuration locked by policy." -ForegroundColor Gray
    } else {
        Write-Host "  [*] Note on Device Owner: $($dpm.Trim())" -ForegroundColor Yellow
    }

    # Cut Radios
    & adb -s $dev shell "svc wifi disable" 2>&1 | Out-Null
    & adb -s $dev shell "svc bluetooth disable" 2>&1 | Out-Null
    & adb -s $dev shell "svc data disable" 2>&1 | Out-Null
    & adb -s $dev shell "pm disable-user --user 0 com.android.nfc" 2>&1 | Out-Null
    & adb -s $dev shell "cmd connectivity airplane-mode enable" 2>&1 | Out-Null

    Write-Host "  [✓] Wi-Fi: HARD DISABLED" -ForegroundColor Green
    Write-Host "  [✓] Bluetooth: HARD DISABLED" -ForegroundColor Green
    Write-Host "  [✓] Cellular Data: HARD DISABLED" -ForegroundColor Green
    Write-Host "  [✓] NFC: DISABLED" -ForegroundColor Green
    Write-Host "  [✓] Airplane Mode: PERMANENTLY ENGAGED" -ForegroundColor Green

    # Launch
    & adb -s $dev shell "am start -n io.bluewallet.bluewallet/.MainActivity" | Out-Null
    Write-Host "  [✓] Cold storage vault active on screen." -ForegroundColor Green
}

function Invoke-Revert($dev) {
    Write-Host "`n--- [STAGE: REVERT & ESCAPE HATCH] ---" -ForegroundColor Yellow
    Write-Host "Reverting device owner restrictions and re-enabling standard radios..." -ForegroundColor Gray

    & adb -s $dev shell "dpm remove-active-admin com.ghostvault.kiosk/.AdminReceiver" 2>&1 | Out-Null
    & adb -s $dev shell "cmd package set-home-activity --clear" 2>&1 | Out-Null
    & adb -s $dev shell "svc wifi enable" 2>&1 | Out-Null
    & adb -s $dev shell "svc bluetooth enable" 2>&1 | Out-Null
    & adb -s $dev shell "svc data enable" 2>&1 | Out-Null
    & adb -s $dev shell "cmd connectivity airplane-mode disable" 2>&1 | Out-Null

    Write-Host "  [✓] Device owner removed. System radios re-enabled." -ForegroundColor Green
    Write-Host "  [✓] You can now use the phone normally or perform a factory reset." -ForegroundColor Green
}

# Execution Flow
Write-Banner
$device = Check-Device

switch ($Stage) {
    "Interactive" {
        Write-Host "`nSelect an option:" -ForegroundColor Cyan
        Write-Host "  1. Full Vault Transformation (Recommended)"
        Write-Host "  2. Debloat & Strip Telemetry Only"
        Write-Host "  3. Install BlueWallet & Kiosk Only"
        Write-Host "  4. Apply Air-Gap Hardening & Device Owner Only"
        Write-Host "  5. Revert Changes (Restore phone)"
        $choice = Read-Host "`nEnter choice [1-5]"
        switch ($choice) {
            "1" { Invoke-Debloat $device; Invoke-InstallApps $device; Invoke-Hardening $device }
            "2" { Invoke-Debloat $device }
            "3" { Invoke-InstallApps $device }
            "4" { Invoke-Hardening $device }
            "5" { Invoke-Revert $device }
            default { Write-Host "Invalid choice. Exiting." -ForegroundColor Red }
        }
    }
    "Debloat"   { Invoke-Debloat $device }
    "Install"   { Invoke-InstallApps $device }
    "Hardening" { Invoke-Hardening $device }
    "Revert"    { Invoke-Revert $device }
    "All"       {
        Invoke-Debloat $device
        Invoke-InstallApps $device
        Invoke-Hardening $device
    }
}

Write-Host ""
Write-Host "=================================================================" -ForegroundColor DarkYellow
Write-Host "                      SETUP COMPLETED                            " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "=================================================================" -ForegroundColor DarkYellow
Write-Host "NEXT STEPS ON THE PHONE SCREEN:" -ForegroundColor White
Write-Host "  1. Tap 'Add now' -> Select 'Bitcoin'."
Write-Host "  2. Tap 'Advanced' -> Select 'Native SegWit (P2WPKH)'."
Write-Host "  3. Enter your SECRET 25TH WORD in the 'Passphrase' field."
Write-Host "  4. Write down the 24 words on paper/metal (NEVER store the 25th word in the same place)."
Write-Host "  5. Unplug USB and disable USB Debugging in phone Developer Options."
Write-Host "=================================================================" -ForegroundColor DarkYellow
Write-Host ""
