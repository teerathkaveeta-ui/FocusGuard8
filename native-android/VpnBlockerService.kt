package com.focusguard.app

import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log

/**
 * VpnBlockerService:
 * Implements a local "Null VPN" to block internet traffic.
 * This is the only reliable way to block data on non-rooted Android 10+ devices.
 */
class VpnBlockerService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null

    companion object {
        private var isRunning = false

        fun startBlocking(context: Context) {
            if (isRunning) return
            val intent = Intent(context, VpnBlockerService::class.java).apply {
                action = "START"
            }
            context.startService(intent)
        }

        fun stopBlocking(context: Context) {
            val intent = Intent(context, VpnBlockerService::class.java).apply {
                action = "STOP"
            }
            context.startService(intent)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> startVpn()
            "STOP" -> stopVpn()
        }
        return START_STICKY
    }

    private fun startVpn() {
        if (isRunning) return
        
        try {
            val builder = Builder()
                .setSession("FocusGuard Blocker")
                .addAddress("10.0.0.2", 32)
                .addRoute("0.0.0.0", 0) // Route ALL traffic through this VPN
                
            vpnInterface = builder.establish()
            isRunning = true
            Log.d("FocusGuard", "VPN Interference established (Internet Blocked)")
        } catch (e: Exception) {
            Log.e("FocusGuard", "Failed to start VPN", e)
        }
    }

    private fun stopVpn() {
        vpnInterface?.close()
        vpnInterface = null
        isRunning = false
        stopSelf()
        Log.d("FocusGuard", "VPN Stopped (Internet Restored)")
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
