# 🛡️ GhostVault BTC — Technical Security Audit & Threat Modeling

**System:** Android Hardened Appliance  
**Operational Mode:** Air-Gapped Dedicated Hardware Signer (Kiosk / Device Owner)  
**Standard:** Bitcoin BIP-39, BIP-84 (Native SegWit), BIP-174 (PSBT)  

---

## 1. 📊 Attack Surface & Mitigation Matrix

| Attack Vector | Standard Smartphone | GhostVault Hardened Appliance | Mitigation Layer |
| :--- | :--- | :--- | :--- |
| **Remote Exploits (Wi-Fi/4G/5G)** | Vulnerable to network malware | **Zero Attack Surface**. Radios disabled via `svc` and locked via `DISALLOW_CONFIG_WIFI` | RF Air-Gap |
| **Proximity RF (Bluetooth / NFC)** | Vulnerable to pairing & BlueBorne exploits | Bluetooth hard-disabled; NFC service disabled; Google Wallet NFC uninstalled | RF Air-Gap |
| **Quick Settings Tampering** | Anyone can pull down status bar to enable Wi-Fi | **Status bar pull-down disabled** via `setStatusBarDisabled(true)` | MDM / Device Owner |
| **OS Telemetry & Background Exfiltration** | Constant background sync to Google, OEM & analytics | **55+ telemetry & tracking packages stripped** for user 0 | Extreme Debloat |
| **Account Exfiltration** | Cloud backup of app data / keys | **0 Accounts registered** (`Accounts: 0`); Play Services sync removed | Zero Cloud |
| **Malicious USB / Juice Jacking** | MTP / ADB exposure on PC connection | USB data transfer disabled (`DISALLOW_USB_FILE_TRANSFER`); Charging-only enforced | Hardware / USB Lock |
| **Physical Screen Spying (Software)** | Screen recording or background malware capture | BlueWallet enforces `FLAG_SECURE` (blocks screenshot and screen capture) | Android Window Manager |
| **Physical Seed Theft ($5 Wrench Attack)** | Attacker gains full control of all funds | **BIP-39 25th Word (Passphrase)** stores real wealth in a mathematically hidden vault | Cryptographic Separation |

---

## 2. 🔐 Defense-in-Depth Architecture

### Layer 1: Hardware & Physical Isolation (Air-Gap)
* **SIM Tray:** Must remain completely empty.
* **Camera & Screen Only:** Optical QR code transmission is the only permissible bridge between the vault and the outside world.
* **Charging Safety:** Always charge the vault via a dedicated AC wall outlet or an inline "USB Data Blocker" dongle.

### Layer 2: Android Enterprise Framework (Device Owner Mode)
Unlike consumer launchers, `GhostKiosk` operates as an authorized **Device Owner** (Enterprise Mobility Management):
```java
// Hardware & Network Locks
dpm.setStatusBarDisabled(admin, true);
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_WIFI);
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_BLUETOOTH);
dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_TETHERING);
dpm.addUserRestriction(admin, UserManager.DISALLOW_NETWORK_RESET);
dpm.addUserRestriction(admin, UserManager.DISALLOW_OUTGOING_BEAM);
dpm.addUserRestriction(admin, UserManager.DISALLOW_USB_FILE_TRANSFER);
```
This guarantees that even if a physical user taps settings menus, the operating system kernel rejects configuration changes.

### Layer 3: Cryptographic Vault (Native SegWit + BIP-39)
* **Native SegWit (P2WPKH / `bc1q...`):** Modern, battle-tested Bitcoin transaction format with lowest fees and signature verification efficiency.
* **BIP-174 (Partially Signed Bitcoin Transactions):** The vault never interacts with the Bitcoin blockchain directly; it receives unsigned PSBTs via animated QR codes (BC-UR), validates inputs and change addresses locally, signs with private keys in offline memory, and displays the signed PSBT.

---

## 3. 🛡️ Physical Security Best Practices for the User

1. **Set a Strong Numeric PIN (6 to 8 digits) on the Lock Screen:**
   * Do NOT use biometric fingerprint or facial recognition. Biometrics can be coerced physically; a secret PIN exists only in your mind.
2. **Permanent USB Port Lockdown:**
   * Once setup and recovery verification are complete, navigate to **Settings > Developer Options** and toggle **"USB Debugging" OFF**. The physical USB port will refuse all computer communication.
3. **Stainless Steel Seed Storage:**
   * Store your 24 words punched into stainless steel or titanium to survive fires and floods.
   * **Never** store the 25th word on the same plate.
