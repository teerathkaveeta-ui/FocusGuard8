package com.focusguard.app

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import android.util.Log

/**
 * FocusAccessibilityService:
 * This service monitors which app is currently in the foreground.
 */
class FocusAccessibilityService : AccessibilityService() {

    companion object {
        var instance: FocusAccessibilityService? = null
        val targetApps = mutableSetOf("com.facebook.katana", "com.instagram.android", "com.google.android.youtube")
        var isStrictLimitActive = false
    }

    override fun onServiceConnected() {
        instance = this
        Log.d("FocusGuard", "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            handleAppSwitch(packageName)
        }
    }

    private fun handleAppSwitch(packageName: String) {
        if (!isStrictLimitActive) return

        if (targetApps.contains(packageName)) {
            // Restricted app detected -> Stop Internet
            VpnBlockerService.startBlocking(this)
            Log.d("FocusGuard", "Blocking Internet for: $packageName")
        } else {
            // Safe app detected -> Restore Internet
            VpnBlockerService.stopBlocking(this)
            Log.d("FocusGuard", "Restoring Internet (current: $packageName)")
        }
    }

    override fun onInterrupt() {}

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }
}
