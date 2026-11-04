# 🤖 Pair Programming with AI — Customization & Elasticity Guide

> **GhostVault BTC is intentionally designed to be transparent, open, and elastic. You are never locked into a rigid black box. We strongly encourage every user to collaborate with an AI assistant to tailor, audit, or extend this project for their specific hardware.**

---

## 💡 Why Use AI with GhostVault?

Every Android manufacturer (Samsung OneUI, Xiaomi HyperOS/MIUI, Motorola, OnePlus OxygenOS, Google Pixel, Huawei EMUI) includes different preinstalled bloatware packages, background telemetry daemons, and system behaviors.

Instead of guessing package names or struggling with shell scripts, you can open an AI assistant (such as **Google Antigravity**, **Anthropic Claude**, **ChatGPT**, or **Cursor**) and use the prompts below to customize this vault in seconds.

---

## 🎯 Example AI Prompts You Can Use

### 1. Generating a Debloat List for Your Specific Phone
> *"I have a spare [Insert Brand and Model, e.g., Samsung Galaxy S10 / Xiaomi Redmi Note 10]. Here is the output of `adb shell pm list packages`. Can you identify all carrier bloatware, social media trackers, and OEM telemetry packages that can safely be stripped without breaking camera access or basic display functions?"*

### 2. Troubleshooting ADB & Device Connection
> *"I plugged my phone into my PC, but `adb devices` shows 'unauthorized' or 'no devices found'. I am running [Windows 11 / macOS / Linux]. How do I fix the USB driver or trust dialog?"*

### 3. Auditing the Security Code
> *"Can you review `kiosk_app/src/main/java/com/ghostvault/kiosk/KioskActivity.java` and `setup_universal.ps1` from GhostVault-BTC? I want to verify what permissions are requested, whether any data leaves the device, and confirm that all wireless radios are genuinely disabled."*

### 4. Customizing the Vault App (Swapping BlueWallet for Krux or Sparrow)
> *"I want to use GhostVault with an alternative open-source signing tool (like Krux, AirGap Vault, or a custom app) instead of BlueWallet. How do I change the target package name and intent filter in `KioskActivity.java` and `setup_universal.ps1`?"*

### 5. Reversing and Restoring the Phone
> *"I want to turn my phone back into a regular daily smartphone. Can you help me run `setup_universal.ps1 -Stage Revert` and ensure Device Owner is cleanly uninstalled?"*

---

## 🧩 Architectural Elasticity: How the Pieces Fit Together

```text
┌─────────────────────────────────────────────────────────────┐
│                       USER CHOICE                           │
│     One-Click Automated Suite   OR   Modular Step-by-Step   │
└──────────────────────────────┬──────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
 ┌──────────────────────┐              ┌──────────────────────┐
 │ setup_universal.ps1  │              │ Manual ADB Commands  │
 │  -Stage Debloat      │              │  pm uninstall ...    │
 │  -Stage Install      │              │  svc wifi disable    │
 │  -Stage Hardening    │              │  dpm set-device-owner│
 │  -Stage Revert       │              └──────────────────────┘
 └──────────┬───────────┘
            ▼
 ┌────────────────────────────────────────────────────────────┐
 │                   ANDROID SYSTEM LAYER                     │
 │  GhostKiosk (Device Owner MDM)                             │
 │   ├─ Disables Notification Pull-down (StatusBarDisabled)   │
 │   ├─ Enforces DISALLOW_CONFIG_WIFI / BLUETOOTH / TETHERING │
 │   └─ Auto-launches Vault into Immersive Fullscreen         │
 └──────────────────────────┬─────────────────────────────────┘
                            ▼
 ┌────────────────────────────────────────────────────────────┐
 │                   BITCOIN SIGNING ENGINE                   │
 │  BlueWallet (Air-Gapped Cold Storage)                      │
 │   ├─ Native SegWit (bc1q...) P2WPKH                        │
 │   ├─ Mandatory 25th Word (BIP-39 Passphrase)               │
 │   ├─ Plausible Deniability Dual-PIN Decoy Wallet           │
 │   └─ Pure Optical QR-Code PSBT Signing                     │
 └────────────────────────────────────────────────────────────┘
```

---

## 🔄 Reversibility & The "Escape Hatch"

You are never permanently trapped. If you ever upgrade your cold vault or decide to repurpose the phone:

1. **Via PowerShell Script:**
   ```powershell
   .\setup_universal.ps1 -Stage Revert
   ```
2. **Via Manual ADB Shell:**
   ```bash
   adb shell dpm remove-active-admin com.ghostvault.kiosk/.AdminReceiver
   adb shell cmd package set-home-activity --clear
   adb shell svc wifi enable
   adb shell cmd connectivity airplane-mode disable
   ```
3. **Via Hardware Factory Reset:**
   Booting into Android Recovery (holding `Power + Volume Down`) and selecting "Wipe Data / Factory Reset" completely returns the phone to stock factory firmware.
