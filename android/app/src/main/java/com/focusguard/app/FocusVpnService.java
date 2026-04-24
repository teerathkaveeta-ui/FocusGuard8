package com.focusguard.app;

import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.os.Handler;
import android.os.ParcelFileDescriptor;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

public class FocusVpnService extends VpnService {
    private ParcelFileDescriptor vpnInterface = null;
    private final Handler handler = new Handler();
    private int userLimitMinutes = 30;
    private List<String> targetPackages = Arrays.asList(
        "com.facebook.katana", 
        "com.instagram.android", 
        "com.google.android.youtube"
    );
    private String mode = "alert";

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            if (intent.hasExtra("limit")) {
                userLimitMinutes = intent.getIntExtra("limit", 30);
            }
            if (intent.hasExtra("packages")) {
                targetPackages = intent.getStringArrayListExtra("packages");
            }
            if (intent.hasExtra("mode")) {
                mode = intent.getStringExtra("mode");
            }
        }
        checkUsageLoop();
        return START_STICKY;
    }

    private void checkUsageLoop() {
        handler.postDelayed(() -> {
            if (mode.equals("strict") && getTotalSocialUsage() > (userLimitMinutes * 60 * 1000L)) {
                if (vpnInterface == null) {
                    startBlocking();
                }
            } else {
                stopBlocking();
            }
            checkUsageLoop();
        }, 15000);
    }

    private long getTotalSocialUsage() {
        long total = 0;
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        Map<String, UsageStats> stats = usm.queryAndAggregateUsageStats(now - 86400000, now);
        
        for (String pkg : targetPackages) {
            if (stats.containsKey(pkg)) {
                total += stats.get(pkg).getTotalTimeInForeground();
            }
        }
        return total;
    }

    private void startBlocking() {
        Builder builder = new Builder();
        try {
            builder.setSession("FocusGuard")
                   .addAddress("10.0.0.2", 24)
                   .addDnsServer("8.8.8.8");
            
            for (String pkg : targetPackages) {
                try {
                    builder.addAllowedApplication(pkg);
                } catch (Exception e) {/* package might not be installed */}
            }
            
            vpnInterface = builder.establish();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void stopBlocking() {
        if (vpnInterface != null) {
            try {
                vpnInterface.close();
                vpnInterface = null;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onDestroy() {
        stopBlocking();
        handler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }
}
