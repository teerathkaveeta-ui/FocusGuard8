package com.focusguard.app;

import android.app.AppOpsManager;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.List;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.focusguard/vpn";
    private int lastLimit = 30;
    private List<String> lastPackages = null;
    private String lastMode = "alert";
    private long lastStrictUntil = 0;

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("startVpnWithLimit")) {
                    Object limitArg = call.argument("limit");
                    Object packagesArg = call.argument("packages");
                    Object modeArg = call.argument("mode");
                    Object strictUntilArg = call.argument("strictUntil");
                    
                    lastLimit = limitArg instanceof Integer ? (int) limitArg : 30;
                    lastPackages = (List<String>) packagesArg;
                    lastMode = modeArg instanceof String ? (String) modeArg : "alert";
                    lastStrictUntil = (strictUntilArg instanceof Number) ? ((Number) strictUntilArg).longValue() : 0;
                    
                    if (!hasUsageStatsPermission()) {
                        startActivity(new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS));
                    }
                    
                    Intent vpnIntent = VpnService.prepare(this);
                    if (vpnIntent != null) {
                        startActivityForResult(vpnIntent, 0);
                    } else {
                        startVpnService(lastLimit, lastPackages, lastMode, lastStrictUntil);
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

    private void startVpnService(int limit, List<String> packages, String mode, long strictUntil) {
        Intent intent = new Intent(this, FocusVpnService.class);
        intent.putExtra("limit", limit);
        if (packages != null) {
            intent.putStringArrayListExtra("packages", new ArrayList<>(packages));
        }
        intent.putExtra("mode", mode);
        intent.putExtra("strictUntil", strictUntil);
        startService(intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode == RESULT_OK) {
            startVpnService(lastLimit, lastPackages, lastMode, lastStrictUntil);
        }
        super.onActivityResult(requestCode, resultCode, data);
    }
}
