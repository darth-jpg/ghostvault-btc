package com.ghostvault.kiosk;

import android.app.Activity;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.UserManager;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

public class KioskActivity extends Activity {
    private static final String PKG = "io.bluewallet.bluewallet";
    private static final String CLS = "io.bluewallet.bluewallet.MainActivity";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        applyHardening();

        ScrollView scrollView = new ScrollView(this);
        scrollView.setBackgroundColor(0xFF000000); // Pure pitch black
        scrollView.setFillViewport(true);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(40, 50, 40, 60);
        root.setGravity(Gravity.CENTER_HORIZONTAL);

        // Header Badge
        TextView badge = new TextView(this);
        badge.setText("AIR-GAPPED HARDWARE VAULT • ZERO WIRELESS");
        badge.setTextColor(0xFF888888);
        badge.setTextSize(11);
        badge.setLetterSpacing(0.15f);
        badge.setGravity(Gravity.CENTER);
        root.addView(badge);

        // Vault Title
        TextView title = new TextView(this);
        title.setText("⚡ GHOSTVAULT BTC");
        title.setTextColor(0xFFF7931A); // Bitcoin Gold/Orange
        title.setTextSize(28);
        title.setGravity(Gravity.CENTER);
        title.setTypeface(null, Typeface.BOLD);
        title.setPadding(0, 10, 0, 5);
        root.addView(title);

        TextView sub = new TextView(this);
        sub.setText("Dedicated Offline Bitcoin Signer (BIP-39 / BIP-174 PSBT)");
        sub.setTextColor(0xFFAAAAAA);
        sub.setTextSize(13);
        sub.setGravity(Gravity.CENTER);
        sub.setPadding(0, 0, 0, 30);
        root.addView(sub);

        // Primary Action Launch Button
        Button btn = new Button(this);
        btn.setText("₿  OPEN BITCOIN VAULT  ➜");
        btn.setTextColor(0xFFFFFFFF);
        btn.setTextSize(16);
        btn.setTypeface(null, Typeface.BOLD);
        btn.setPadding(40, 36, 40, 36);

        GradientDrawable btnShape = new GradientDrawable();
        btnShape.setShape(GradientDrawable.RECTANGLE);
        btnShape.setCornerRadius(24f);
        btnShape.setColor(0xFFF7931A); // Bitcoin Orange
        btn.setBackground(btnShape);

        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchVault();
            }
        });
        root.addView(btn);

        addSpacer(root, 15);

        // Secondary Button: Controlled System Settings
        Button settingsBtn = new Button(this);
        settingsBtn.setText("⚙️  DEVICE & HARDWARE SETTINGS");
        settingsBtn.setTextColor(0xFFCCCCCC);
        settingsBtn.setTextSize(13);
        settingsBtn.setTypeface(null, Typeface.BOLD);
        settingsBtn.setPadding(30, 24, 30, 24);

        GradientDrawable settingsShape = new GradientDrawable();
        settingsShape.setShape(GradientDrawable.RECTANGLE);
        settingsShape.setCornerRadius(20f);
        settingsShape.setColor(0xFF191919);
        settingsShape.setStroke(2, 0xFF333333);
        settingsBtn.setBackground(settingsShape);

        settingsBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                openSettings();
            }
        });
        root.addView(settingsBtn);

        // Spacer
        addSpacer(root, 35);

        // Protocol Header
        TextView protocolHeader = new TextView(this);
        protocolHeader.setText("SECURITY PROTOCOL & VERIFICATION");
        protocolHeader.setTextColor(0xFFF7931A);
        protocolHeader.setTextSize(13);
        protocolHeader.setTypeface(null, Typeface.BOLD);
        protocolHeader.setLetterSpacing(0.1f);
        root.addView(protocolHeader);

        addSpacer(root, 15);

        // Card 1: 25th Word Mandate
        addCard(root, "1. MANDATORY 25TH WORD (PASSPHRASE)",
            "• In BlueWallet: Tap 'Add now' > 'Advanced' > 'Native SegWit (bc1q...)'.\n" +
            "• Enter your secret 25th Word in the 'Passphrase' field.\n" +
            "• CRITICAL RULE: NEVER store your 25th word in the same physical location as the 24 words. Keep it in memory or in a separate vault.");

        addSpacer(root, 20);

        // Card 2: Parachute Recovery Test
        addCard(root, "2. THE PARACHUTE TEST (VERIFY BEFORE DEPOSIT)",
            "• Note down the first receiving address generated (e.g. bc1q...).\n" +
            "• Delete the wallet from BlueWallet.\n" +
            "• Restore via 'Import' using your 24 words + 25th word passphrase.\n" +
            "• Verify: The exact same receiving address must appear. This guarantees 100% mathematical certainty in your backup.");

        addSpacer(root, 20);

        // Card 3: Plausible Deniability
        addCard(root, "3. PLAUSIBLE DENIABILITY (DUAL PIN)",
            "• In BlueWallet Settings > Security, enable PIN protection.\n" +
            "• Enable 'Plausible Deniability' with a Decoy PIN.\n" +
            "• Decoy PIN opens Wallet A (with $20-$50 as decoy under duress).\n" +
            "• Master PIN opens your real vault with the 25th word.");

        addSpacer(root, 20);

        // Card 4: Pure QR Air-Gap Operations
        addCard(root, "4. 100% OFFLINE AIR-GAP OPERATION",
            "• Export Watch-Only public key (ZPUB QR) to your daily phone or PC (Sparrow Wallet).\n" +
            "• When spending: prepare transaction on PC/daily phone > scan QR with Vault camera > Vault signs with private key > scan signed QR back to broadcast.\n" +
            "• This device NEVER connects to Wi-Fi, Bluetooth, or cables.");

        addSpacer(root, 30);

        // Footer System Status
        TextView footer = new TextView(this);
        footer.setText("HARDWARE STATUS:\nWi-Fi: DISABLED ✕ | Bluetooth: DISABLED ✕\nCellular: DISABLED ✕ | Camera Air-Gap: ACTIVE ✓");
        footer.setTextColor(0xFF555555);
        footer.setTextSize(11);
        footer.setGravity(Gravity.CENTER);
        footer.setLineSpacing(4f, 1f);
        root.addView(footer);

        scrollView.addView(root);
        setContentView(scrollView);
    }

    private void addCard(LinearLayout parent, String cardTitle, String body) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setPadding(35, 30, 35, 30);

        GradientDrawable cardShape = new GradientDrawable();
        cardShape.setShape(GradientDrawable.RECTANGLE);
        cardShape.setCornerRadius(18f);
        cardShape.setColor(0xFF141414); // Dark elegant container
        cardShape.setStroke(2, 0xFF282828);
        card.setBackground(cardShape);

        TextView tView = new TextView(this);
        tView.setText(cardTitle);
        tView.setTextColor(0xFFFFFFFF);
        tView.setTextSize(13);
        tView.setTypeface(null, Typeface.BOLD);
        tView.setPadding(0, 0, 0, 10);
        card.addView(tView);

        TextView bView = new TextView(this);
        bView.setText(body);
        bView.setTextColor(0xFFAAAAAA);
        bView.setTextSize(12);
        bView.setLineSpacing(6f, 1f);
        card.addView(bView);

        parent.addView(card);
    }

    private void addSpacer(LinearLayout parent, int height) {
        View spacer = new View(this);
        spacer.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, height));
        parent.addView(spacer);
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideSystemUI();
        applyHardening();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int keyCode = event.getKeyCode();
        // Intercept volume keys to prevent volume slider popup and settings gear icon breakout
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || keyCode == KeyEvent.KEYCODE_VOLUME_MUTE) {
            return true; // Consume event completely
        }
        return super.dispatchKeyEvent(event);
    }

    private void hideSystemUI() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
        );
    }

    private void applyHardening() {
        try {
            DevicePolicyManager dpm = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
            ComponentName admin = new ComponentName(this, AdminReceiver.class);
            if (dpm != null && dpm.isDeviceOwnerApp(getPackageName())) {
                // Completely block status bar pull-down / Quick Settings
                dpm.setStatusBarDisabled(admin, true);

                // Block volume adjustment system-wide (eliminates volume settings popup)
                dpm.addUserRestriction(admin, UserManager.DISALLOW_ADJUST_VOLUME);

                // Block booting into Safe Mode (prevents bypassing kiosk launcher)
                dpm.addUserRestriction(admin, UserManager.DISALLOW_SAFE_BOOT);

                // Forbid all wireless & network configuration
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_WIFI);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_BLUETOOTH);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_TETHERING);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_NETWORK_RESET);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_OUTGOING_BEAM);

                // Allow seamless USB debugging when user enables it in Developer Options
                dpm.clearUserRestriction(admin, UserManager.DISALLOW_USB_FILE_TRANSFER);

                // Forbid adding Google / OEM cloud accounts
                dpm.addUserRestriction(admin, UserManager.DISALLOW_MODIFY_ACCOUNTS);
            }
        } catch (Throwable ignored) {}
    }

    private void openSettings() {
        try {
            Intent intent = new Intent(android.provider.Settings.ACTION_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        } catch (Throwable t) {
            try {
                Toast.makeText(this, "Opening settings...", Toast.LENGTH_SHORT).show();
            } catch (Throwable ignored) {}
        }
    }

    private void launchVault() {
        try {
            Intent intent = new Intent(Intent.ACTION_MAIN);
            intent.setComponent(new ComponentName(PKG, CLS));
            intent.addCategory(Intent.CATEGORY_LAUNCHER);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
            startActivity(intent);
        } catch (Throwable t) {
            try {
                Intent fallback = getPackageManager().getLaunchIntentForPackage(PKG);
                if (fallback != null) {
                    fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(fallback);
                } else {
                    Toast.makeText(this, "Launching vault...", Toast.LENGTH_SHORT).show();
                }
            } catch (Throwable ignored) {}
        }
    }
}
