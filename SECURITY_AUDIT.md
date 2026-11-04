# 🛡️ GhostVault BTC — Technical Security Audit & Threat Modeling

**System:** Android Hardened Appliance  
**Operational Mode:** Air-Gapped Dedicated Hardware Signer (Kiosk / Device Owner)  
**Standard:** Bitcoin BIP-39, BIP-84 (Native SegWit), BIP-174 (PSBT)  

---

## 1. 📊 Attack Surface & Mitigation Matrix

| Attack Vector | Standard Smartphone | GhostVault Hardened Appliance | Mitigation Layer |
| :--- | :--- | :--- | :--- |
| **Remote Exploits (Wi-Fi/4G/5G)** | Vulnerable to network malware & zero-days | **Isolated**. Radios disabled via `svc` with state validation; network changes blocked via `DISALLOW_CONFIG_WIFI` & `DISALLOW_NETWORK_RESET` | Android Service + MDM Policy |
| **Proximity RF (Bluetooth / NFC)** | Vulnerable to pairing & BlueBorne exploits | Bluetooth service disabled (`bluetooth_on=0`); `com.android.nfc` package disabled; Google Wallet uninstalled | Android Service + MDM Policy |
| **Quick Settings Tampering** | Anyone can pull down status bar to enable Wi-Fi | **Status bar pull-down disabled** via DevicePolicyManager `setStatusBarDisabled(true)` | MDM / Device Owner |
| **OS Telemetry & Background Exfiltration** | Constant background sync to Google, OEM & analytics | **44 universal telemetry packages stripped** for user 0 (55+ in OEM scripts) | Package Manager Debloat |
| **Account Exfiltration** | Cloud backup of app data / keys | **0 Accounts registered** (`Accounts: 0`); account modification locked via `DISALLOW_MODIFY_ACCOUNTS` | Zero Cloud MDM |
| **Malicious USB / Juice Jacking** | MTP / ADB exposure on PC connection | USB Debugging disabled post-setup; physical data blockers recommended for charging | Hardware & Physical Policy |
| **Physical Screen Spying (Software)** | Screen recording or background malware capture | BlueWallet enforces `FLAG_SECURE` (blocks screenshot and screen capture) | Android Window Manager |
| **Physical Seed Theft ($5 Wrench Attack)** | Attacker gains full control of all funds | **BIP-39 25th Word (Passphrase)** stores real wealth in a mathematically hidden vault | Cryptographic Separation |

---

## 2. 🔐 Defense-in-Depth Architecture

### Layer 1: Hardware & Physical Isolation (Air-Gap)
* **SIM Tray:** Must remain completely empty.
* **Camera & Screen Only:** Optical QR code transmission is the only permissible bridge between the vault and the outside world.
* **Airplane Mode & Radio Controls:** Airplane mode is enabled via `cmd connectivity airplane-mode enable`, and Wi-Fi, Bluetooth, and cellular radios are disabled via Android `svc` commands with global property validation (`settings get global wifi_on`, etc.). Because Android's framework lacks a permanent `DISALLOW_AIRPLANE_MODE` restriction, air-gap integrity is enforced through Device Owner restrictions that prevent re-enabling network configurations even if system settings are opened.
* **Charging Safety:** Always charge the vault via a dedicated AC wall outlet or an inline "USB Data Blocker" dongle that physically cuts the data pins (`D+` / `D-`).

### Layer 2: Android Enterprise Framework (Device Owner Mode)
Unlike consumer launchers, `GhostKiosk` operates as an authorized **Device Owner** (Enterprise Mobility Management):
```java
// Status bar & Hardware lockouts
dpm.setStatusBarDisabled(admin, true);
dpm.addUserRestriction(admin, UserManager.DISALLOW_ADJUST_VOLUME);
dpm.addUserRestriction(admin, UserManager.DISALLOW_SAFE_BOOT);

// Wireless & Network locks
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_WIFI);
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_BLUETOOTH);
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_TETHERING);
dpm.addUserRestriction(admin, UserManager.DISALLOW_NETWORK_RESET);
dpm.addUserRestriction(admin, UserManager.DISALLOW_OUTGOING_BEAM);

// Cloud Account Lockout
dpm.addUserRestriction(admin, UserManager.DISALLOW_MODIFY_ACCOUNTS);

// USB Data Policy: Cleared in code to allow ADB maintenance while Developer Options are active.
// Physical protection is enforced by turning off USB Debugging post-setup.
dpm.clearUserRestriction(admin, UserManager.DISALLOW_USB_FILE_TRANSFER);
```
This guarantees that even if a physical user accesses device settings (e.g. to adjust screen timeout or set a lock screen PIN), the Android framework prevents adding accounts or modifying wireless configurations.

### Layer 3: Cryptographic Vault & Binary Integrity
* **Verified Binaries:** All installed wallet binaries (`BlueWallet.apk`) are cryptographically verified against official release SHA-256 hashes prior to installation (`D411E0C58E325D2BC057506007EBE7052743BFC7DCDAA94AF4ACE0BB18434454`).
* **Google Play Services Handling:** `com.google.android.gms` is intentionally preserved in the base debloat script to avoid breaking Android System WebView and core ROM stability. However, cloud sync is completely neutered because no Google account is registered, `DISALLOW_MODIFY_ACCOUNTS` blocks adding accounts, and all network interfaces are shut down.
* **Native SegWit (P2WPKH / `bc1q...`):** Modern, battle-tested Bitcoin transaction format with lowest fees and signature verification efficiency.
* **BIP-174 (Partially Signed Bitcoin Transactions):** The vault never interacts with the Bitcoin blockchain directly; it receives unsigned PSBTs via animated QR codes (BC-UR), validates inputs and change addresses locally, signs with private keys in offline memory, and displays the signed PSBT.

---

## 3. 🛡️ Physical Security Best Practices for the User

1. **Set a Strong Numeric PIN (6 to 8 digits) on the Lock Screen:**
   * Do NOT use biometric fingerprint or facial recognition. Biometrics can be coerced physically; a secret PIN exists only in your mind.
2. **Pre-Seed USB Cable Disconnect & Port Lockdown:**
   * Immediately after running the automated provisioning script, **unplug the USB cable** and navigate to **Settings > Developer Options** to toggle **"USB Debugging" OFF** *before* opening BlueWallet to create the wallet.
   * This guarantees that entropy calculation, seed mnemonic display, and the 25th word passphrase entry occur with 0% chance of physical or host-PC interception (e.g. malicious screencap/adb daemons).
3. **Stainless Steel Seed Storage:**
   * Store your 24 words punched into stainless steel or titanium to survive fires and floods.
   * **Never** store the 25th word on the same plate.

---

## 4. 🔄 Reversibility & Device Restoration

* The `setup_universal.ps1 -Stage Revert` script re-enables Wi-Fi, Bluetooth, Cellular, and NFC interfaces, restores user-0 system packages via `pm install-existing`, and unsets the default home kiosk launcher.
* **Device Owner Removal Note:** On modern Android versions (Android 7.0+), Android security architecture prevents unregistering an active Device Owner via ADB without a factory reset unless the application is compiled with `testOnly="true"`. To return the phone to 100% clean factory stock, performing a standard Android Factory Reset (**Settings > System > Reset options > Erase all data**) is the recommended, guaranteed method.
