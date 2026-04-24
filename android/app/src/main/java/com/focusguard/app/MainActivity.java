package com.focusguard.app;

import android.app.AppOpsManager;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.provider.Settings;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.focusguard/vpn";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("startVpnWithLimit")) {
                    Object limitArg = call.argument("limit");
                    Object packagesArg = call.argument("packages");
                    Object modeArg = call.argument("mode");
                    
                    int limit = limitArg instanceof Integer ? (int) limitArg : 30;
                    java.util.List<String> packages = (java.util.List<String>) packagesArg;
                    String mode = modeArg instanceof String ? (String) modeArg : "alert";
                    
                    if (!hasUsageStatsPermission()) {
                        startActivity(new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS));
                    }
                    
                    Intent vpnIntent = VpnService.prepare(this);
                    if (vpnIntent != null) {
                        startActivityForResult(vpnIntent, 0);
                    } else {
                        startVpnService(limit, packages, mode);
                    }
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
    }

    private boolean hasUsageStatsPermission() {
        AppOpsManager appOps = (AppOpsManager) getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), getPackageName());
        return mode == AppOpsManager.MODE_ALLOWED;
    }

    private void startVpnService(int limit, java.util.List<String> packages, String mode) {
        Intent intent = new Intent(this, FocusVpnService.class);
        intent.putExtra("limit", limit);
        if (packages != null) {
            intent.putStringArrayListExtra("packages", new java.util.ArrayList<>(packages));
        }
        intent.putExtra("mode", mode);
        startService(intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == RESULT_OK) {
            startVpnService(30);
        }
        super.onActivityResult(requestCode, resultCode, data);
    }
}
