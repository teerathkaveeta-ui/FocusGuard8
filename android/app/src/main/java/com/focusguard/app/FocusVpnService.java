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
    private Map<String, Long> sessionBaseUsage = new java.util.HashMap<>();
    private long startTime = 0;

    @Override
    public void onCreate() {
        super.onCreate();
        tts = new TextToSpeech(this, this);
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
        startTime = System.currentTimeMillis();
        captureBaseUsage(); 
        
        checkUsageLoop();
        return START_STICKY;
    }

    @Override
    public void onInit(int status) {
        if (status == TextToSpeech.SUCCESS) {
            tts.setLanguage(Locale.US);
            ttsReady = true;
        }
    }

    private void captureBaseUsage() {
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        Map<String, UsageStats> stats = usm.queryAndAggregateUsageStats(now - (now % 86400000), now);
        sessionBaseUsage.clear();
        for (String pkg : targetPackages) {
            if (stats.containsKey(pkg)) {
                sessionBaseUsage.put(pkg, stats.get(pkg).getTotalTimeInForeground());
            } else {
                sessionBaseUsage.put(pkg, 0L);
            }
        }
    }

    private long getSessionUsage() {
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        Map<String, UsageStats> stats = usm.queryAndAggregateUsageStats(now - (now % 86400000), now);
        
        long currentTotal = 0;
        for (String pkg : targetPackages) {
            if (stats.containsKey(pkg)) {
                long totalTime = stats.get(pkg).getTotalTimeInForeground();
                long base = sessionBaseUsage.containsKey(pkg) ? sessionBaseUsage.get(pkg) : 0;
                currentTotal += Math.max(0, totalTime - base);
            }
        }
        return currentTotal;
    }

    private void checkUsageLoop() {
        handler.postDelayed(() -> {
            long now = System.currentTimeMillis();
            updateForegroundPackage();
            
            boolean isTargetActive = targetPackages.contains(currentForegroundPackage);
            long sessionTimeUsed = getSessionUsage();
            boolean isTimeOver = sessionTimeUsed > (userLimitMinutes * 60 * 1000L);
            boolean isLockedDate = strictUntilMillis > 0 && now < strictUntilMillis;

            // Logic 1: Strict Mode (Block and Alert)
            if (mode.equals("strict")) {
                if (isTimeOver || isLockedDate) {
                    // Only establish tunnel if the target app is actually in foreground
                    // This "stops" the VPN effect when they leave the social app
                    if (isTargetActive) {
                        if (vpnInterface == null) {
                            startBlocking();
                        }
                    } else {
                        stopBlocking();
                    }
                    
                    if (!hasAlertedStrict) {
                        triggerAlert("Strict Mode: Focus Limit Exceeded. App restricted.");
                        hasAlertedStrict = true;
                    }
                } else {
                    stopBlocking();
                    hasAlertedStrict = false;
                }
            }
            
            // Logic 2: Alert Mode (Notify only)
            if (mode.equals("alert")) {
                stopBlocking(); // Never block in Alert mode
                if (isTimeOver && !hasAlertedAlert) {
                    triggerAlert("Alert Mode: Limit Reached. Kindly close the app.");
                    hasAlertedAlert = true;
                } else if (!isTimeOver) {
                    hasAlertedAlert = false;
                }
            }

            checkUsageLoop();
        }, 2000); // Check every 2s for better foreground detection
    }

    private void updateForegroundPackage() {
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        List<UsageStats> stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 1000 * 60, now);
        if (stats != null) {
            long lastTime = 0;
            for (UsageStats s : stats) {
                if (s.getLastTimeUsed() > lastTime) {
                    currentForegroundPackage = s.getPackageName();
                    lastTime = s.getLastTimeUsed();
                }
            }
        }
    }

    private void triggerAlert(String message) {
        handler.post(() -> {
            Toast.makeText(FocusVpnService.this, message, Toast.LENGTH_LONG).show();
            
            Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            if (v != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    v.vibrate(VibrationEffect.createWaveform(new long[]{0, 500, 200, 500}, -1));
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
        if (tts != null) {
            tts.stop();
            tts.shutdown();
        }
        handler.removeCallbacksAndMessages(null);
        super.onDestroy();
    }
}
