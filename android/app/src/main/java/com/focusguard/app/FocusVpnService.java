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

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && intent.hasExtra("limit")) {
            userLimitMinutes = intent.getIntExtra("limit", 30);
        }
        checkUsageLoop();
        return START_STICKY;
    }

    private void checkUsageLoop() {
        handler.postDelayed(() -> {
            if (getTotalSocialUsage() > (userLimitMinutes * 60 * 1000L)) {
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
        
        List<String> targets = Arrays.asList(
            "com.facebook.katana", 
            "com.instagram.android", 
            "com.google.android.youtube"
        );
        
        for (String pkg : targets) {
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
            
            builder.addAllowedApplication("com.facebook.katana");
            builder.addAllowedApplication("com.instagram.android");
            builder.addAllowedApplication("com.google.android.youtube");
            
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
