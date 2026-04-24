# FocusGuard Android Studio Setup Guide

Aapne mangae gaye complete Java/Kotlin source code ki files maine `/native-android/` folder mein generate kar di hain. Aap in files ko Android Studio mein navigate karke use kar sakte hain.

## Files Generated:
1. **/native-android/AndroidManifest.xml**: Isme saari Permissions aur Service declarations hain.
2. **/native-android/FocusAccessibilityService.kt**: Monitoring logic for social media apps.
3. **/native-android/VpnBlockerService.kt**: Hardware-level internet toggling ka alternate (Local VPN).
4. **MainActivity.kt (Logic Details)**: User interface interaction logic.

## Setup Instructions for Android Studio:

### 1. New Project Start Karein
Android Studio mein **Empty Compose Activity** choose karein. Package name `com.focusguard.app` rakhein.

### 2. Permissions Add Karein
`AndroidManifest.xml` ko replace karein jo maine generate ki hai. Isme system settings aur foreground service ki permissions hain.

### 3. Accessibility Config (/res/xml/)
Ek nayi file banayein `res/xml/accessibility_service_config.xml`:
```xml
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/xml/android"
    android:accessibilityEventTypes="typeWindowStateChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagDefault|flagIncludeNotImportantViews"
    android:canRetrieveWindowContent="true"
    android:description="@string/accessibility_description" />
```

### 4. Background Monitoring (Very Important)
FocusGuard ko work karne ke liye user ko device Settings mein jaakar Manually **Accessibility Permission** enable karni hogi.

---

## Logic Explanation:
- **Connectivity Control**: Aaj kal ke Android versions (10+) mein seedhe Wi-Fi toggle karna mushkil hai privacy ki wajah se. Isliye maine `VpnBlockerService.kt` di hai. Ye ek local VPN create karke internet block karta hai bina external server ke.
- **Background Persistence**: AccessibilityService Android OS dwara kill nahi ki jaati, isliye ye 24/7 background mein run karegi.

Aap repository ke `/native-android/` folder mein saari logic detail dekh sakte hain.
