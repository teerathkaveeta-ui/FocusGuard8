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
    private boolean hasAlerted = false;

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
        hasAlerted = false;
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

    private void checkUsageLoop() {
        handler.postDelayed(() -> {
            long now = System.currentTimeMillis();
            boolean isTimeOver = getTotalSocialUsage() > (userLimitMinutes * 60 * 1000L);
            boolean isStrictExpired = strictUntilMillis > 0 && now > strictUntilMillis;
            
            // If strict is set, and not expired, we are in strict block
            boolean shouldBlock = (mode.equals("strict") && isTimeOver) || (strictUntilMillis > 0 && now < strictUntilMillis);

            if (shouldBlock) {
                if (vpnInterface == null) {
                    startBlocking();
                }
            } else {
                stopBlocking();
            }

            if (isTimeOver && mode.equals("alert") && !hasAlerted) {
                triggerAlert();
                hasAlerted = true;
            }

            // Tight loop for quick blocking (3 seconds)
            checkUsageLoop();
        }, 3000); 
    }

    private void triggerAlert() {
        handler.post(() -> {
            Toast.makeText(FocusVpnService.this, "Your limit is over! Please close the app and press OK.", Toast.LENGTH_LONG).show();
            
            Vibrator v = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                v.vibrate(VibrationEffect.createOneShot(1000, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                v.vibrate(1000);
            }

            if (ttsReady) {
                tts.speak("Your limit has been reached. FocusGuard requests you to kindly close the app now.", TextToSpeech.QUEUE_FLUSH, null, null);
            }
        });
    }

    private long getTotalSocialUsage() {
        long total = 0;
        UsageStatsManager usm = (UsageStatsManager) getSystemService(Context.USAGE_STATS_SERVICE);
        long now = System.currentTimeMillis();
        // Today's usage
        Map<String, UsageStats> stats = usm.queryAndAggregateUsageStats(now - (now % 86400000), now);
        
        for (String pkg : targetPackages) {
            if (stats.containsKey(pkg)) {
                total += stats.get(pkg).getTotalTimeInForeground();
            }
        }
        return total;
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
