package com.ghostvault.kiosk;

import android.app.Activity;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.os.UserManager;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.LinearLayout;
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

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setBackgroundColor(0xFF000000); // Pitch black
        layout.setGravity(Gravity.CENTER);
        layout.setPadding(60, 60, 60, 60);

        TextView badge = new TextView(this);
        badge.setText("AIR-GAPPED BITCOIN VAULT");
        badge.setTextColor(0xFF888888);
        badge.setTextSize(12);
        badge.setLetterSpacing(0.2f);
        badge.setGravity(Gravity.CENTER);
        layout.addView(badge);

        TextView title = new TextView(this);
        title.setText("⚡ GHOSTVAULT");
        title.setTextColor(0xFFF7931A); // Bitcoin Gold/Orange
        title.setTextSize(32);
        title.setGravity(Gravity.CENTER);
        title.setTypeface(null, android.graphics.Typeface.BOLD);
        title.setPadding(0, 10, 0, 10);
        layout.addView(title);

        TextView sub = new TextView(this);
        sub.setText("100% Offline Hardware Signer\nZero Wireless • Zero Network • Pure QR Air-Gap");
        sub.setTextColor(0xFFAAAAAA);
        sub.setTextSize(14);
        sub.setGravity(Gravity.CENTER);
        sub.setPadding(0, 10, 0, 70);
        layout.addView(sub);

        Button btn = new Button(this);
        btn.setText("OPEN BITCOIN VAULT  ➜");
        btn.setTextColor(0xFFFFFFFF);
        btn.setTextSize(16);
        btn.setTypeface(null, android.graphics.Typeface.BOLD);
        btn.setPadding(60, 36, 60, 36);

        GradientDrawable shape = new GradientDrawable();
        shape.setShape(GradientDrawable.RECTANGLE);
        shape.setCornerRadius(28f);
        shape.setColor(0xFFF7931A); // Bitcoin Orange button
        btn.setBackground(shape);

        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchVault();
            }
        });
        layout.addView(btn);

        setContentView(layout);
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideSystemUI();
        applyHardening();
        launchVault();
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

                // Forbid all wireless & network configuration
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_WIFI);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_BLUETOOTH);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_CONFIG_TETHERING);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_NETWORK_RESET);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_OUTGOING_BEAM);
                dpm.addUserRestriction(admin, UserManager.DISALLOW_USB_FILE_TRANSFER);
            }
        } catch (Throwable ignored) {}
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
