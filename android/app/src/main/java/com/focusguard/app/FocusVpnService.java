package com.focusguard.app;

import android.app.usage.UsageStats;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.content.Intent;
import android.net.VpnService;
import android.os.Handler;
import android.os.ParcelFileDescriptor;
import android.os.Vibrator;
import android.os.VibrationEffect;
import android.os.Build;
import android.speech.tts.TextToSpeech;
import android.widget.Toast;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Locale;

public class FocusVpnService extends VpnService implements TextToSpeech.OnInitListener {
    private ParcelFileDescriptor vpnInterface = null;
    private final Handler handler = new Handler();
    private Runnable usageLoopRunnable = null;
    private int userLimitMinutes = 30;
    private long strictUntilMillis = 0;
    private List<String> targetPackages = Arrays.asList(
        "com.facebook.katana", 
        "com.instagram.android", 
        "com.google.android.youtube",
        "com.zhiliaoapp.musically"
    );
    private String mode = "alert";
    private TextToSpeech tts;
    private boolean ttsReady = false;
    private boolean hasAlertedAlert = false;
    private boolean hasAlertedStrict = false;
    private String currentForegroundPackage = "";
    private long sessionElapsedMillis = 0;
    private long lastForegroundCheckTime = 0;
    private long startTime = 0;
    private boolean hasWarnedStrict = false;
    private long warningStartTime = 0;

    @Override
    public void onCreate() {
        super.onCreate();
        tts = new TextToSpeech(this, this);
    }

    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS) {
            tts.setLanguage(Locale.US);
            ttsReady = true;
        }
    }

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
            if (intent.hasExtra("strictUntil")) {
                strictUntilMillis = intent.getLongExtra("strictUntil", 0);
            }
        }
        
        hasAlertedAlert = false;
        hasAlertedStrict = false;
        hasWarnedStrict = false;
        warningStartTime = 0;
        startTime = System.currentTimeMillis();
        sessionElapsedMillis = 0;
        lastForegroundCheckTime = System.currentTimeMillis();
        
        // Ensure no old loop is running
        if (usageLoopRunnable != null) {
            handler.removeCallbacks(usageLoopRunnable);
        }

        // If starting in Alert mode, force unblock immediately
        if ("alert".equals(mode)) {
            stopBlocking();
        }

        startUsageLoop();
        return START_STICKY;
    }

    private void startUsageLoop() {
        usageLoopRunnable = new Runnable() {
            @Override
            public void run() {
                long now = System.currentTimeMillis();
                updateForegroundPackage();
                
                boolean isTargetActive = targetPackages != null && targetPackages.contains(currentForegroundPackage);
                
                // Only count time if it's a target social app, NOT our own app
                if (isTargetActive && !getPackageName().equals(currentForegroundPackage)) {
                    if (lastForegroundCheckTime > 0) {
                        sessionElapsedMillis += (now - lastForegroundCheckTime);
                    }
                }
                lastForegroundCheckTime = now;

                boolean isTimeOver = sessionElapsedMillis > (userLimitMinutes * 60 * 1000L);
                boolean isLockedDate = strictUntilMillis > 0 && now < strictUntilMillis;

                // Logic 1: Strict Mode (Block and Alert)
                if ("strict".equals(mode)) {
                    if (isTimeOver || isLockedDate) {
                        // Grace period check for the first time session limit is hit
                        if (isTimeOver && !hasWarnedStrict && !isLockedDate) {
                            triggerAlert("Strict Mode: Limit reached! Preparing to block in 10 seconds.");
                            hasWarnedStrict = true;
                            warningStartTime = now;
                        }

                        // Block if grace period is over or if it's a hard date lock
                        boolean shouldBlock = isLockedDate || (hasWarnedStrict && now > (warningStartTime + 10000));

                        if (shouldBlock) {
                            if (isTargetActive) {
                                if (vpnInterface == null) {
                                    startBlocking();
                                }
                            } else {
                                stopBlocking();
                            }

                            if (!hasAlertedStrict) {
                                triggerAlert("FocusGuard: Usage limit exceeded. Target application restricted.");
                                hasAlertedStrict = true;
                            }
                        }
                    } else {
                        stopBlocking();
                        hasAlertedStrict = false;
                        hasWarnedStrict = false;
                    }
                }
                
                // Logic 2: Alert Mode (Notify only, NEVER block)
                if ("alert".equals(mode)) {
                    stopBlocking(); 
                    if (isTimeOver && !hasAlertedAlert) {
                        triggerAlert("Alert: You've reached your usage limit. FocusGuard suggests taking a break.");
                        hasAlertedAlert = true;
                    } else if (!isTimeOver) {
                        hasAlertedAlert = false;
                    }
                }

                handler.postDelayed(this, 1500); 
            }
        };
        handler.post(usageLoopRunnable);
    }

    private void updateForegroundPackage() {
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        List<UsageStats> stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 5000, now);
        if (stats != null && !stats.isEmpty()) {
            long lastTime = 0;
            String topPkg = "";
            for (UsageStats s : stats) {
                if (s.getLastTimeUsed() > lastTime) {
                    topPkg = s.getPackageName();
                    lastTime = s.getLastTimeUsed();
                }
            }
            if (!topPkg.isEmpty()) {
                currentForegroundPackage = topPkg;
            }
        }
    }

    private void triggerAlert(String message) {
        handler.post(() -> {
            Toast.makeText(FocusVpnService.this, message, Toast.LENGTH_LONG).show();
            
            Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            if (v != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(new long[]{0, 500, 200, 500, 200, 500}, -1));
                } else {
                    v.vibrate(1000);
                }
            }

            if (ttsReady) {
                tts.speak(message, TextToSpeech.QUEUE_FLUSH, null, null);
            }
        });
    }

    private void startBlocking() {
        VpnService.Builder builder = new VpnService.Builder();
        try {
            // Use 10.0.0.2 as a local sink.
            // DO NOT set 0.0.0.0 as route if possible, but VpnService needs a route to catch traffic.
            // IMPORTANT: If we only add specific applications, the route should only apply to them.
            builder.setSession("FocusGuard")
                   .addAddress("10.0.0.2", 24)
                   .addRoute("0.0.0.0", 0); // Catch traffic for identified apps
            
            boolean added = false;
            for (String pkg : targetPackages) {
                try {
                    builder.addAllowedApplication(pkg);
                    added = true;
                } catch (Exception e) {}
            }
            
            // If no apps can be blocked, don't start
            if (!added) return;

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
    public void onTaskRemoved(Intent rootIntent) {
        stopSelf();
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public void onDestroy() {
        stopBlocking();
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        handler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }
}
