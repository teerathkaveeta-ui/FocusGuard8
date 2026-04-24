# FocusGuard 🛡️

FocusGuard is a comprehensive digital well-being and social media restriction application. It empowers users to regain control over their screen time through strict connectivity management and customizable restriction modes.

## 🚀 Key Features

- **App Restriction Dashboard**: Select specific social media apps (Facebook, Instagram, YouTube, TikTok) to monitor.
- **Dual Restriction Modes**:
  - **Alert Mode**: Soft reminders with configurable vibrations, ringing, or both.
  - **Strict Mode**: Hard connectivity blocks using a Local VPN workaround.
- **Custom Time Management**: Set duration limits or specific "Till End" timestamps for manual control.
- **Permission Management**: Built-in flow to authorize Accessibility Services, Usage Stats, and VPN connectivity on Android devices.
- **Real-time Feedback**: Visual feedback on current session status and remaining time.

## 📂 Project Structure

This repository contains two main parts:

### 1. Web Dashboard (Frontend)
Located in the root and `/src/` directory. Built with:
- **React 19 + TypeScript**: Modern functional components.
- **Vite**: Ultra-fast build tool and development server.
- **Tailwind CSS**: Utility-first styling.
- **Motion (Framer Motion)**: For smooth UI transitions and animations.
- **Lucide React**: Beautiful, consistent iconography.

### 2. Native Android Code
Located in the `/native-android/` directory. This contains the essential logic for building an installable Android `.apk`:
- `MainActivity.kt`: Handles the initial permission setup UI.
- `FocusAccessibilityService.kt`: Detects when restricted apps are in the foreground.
- `VpnBlockerService.kt`: Implements the local VPN "null-route" to block internet connectivity on a per-app basis.
- `AndroidManifest.xml`: Configures system permissions and services.

## 🛠️ Getting Started

### Prerequisites
- [Node.js](https://nodejs.org/) (v18 or higher)
- [Android Studio](https://developer.android.com/studio) (for building the native app)

### Run the Web Dashboard
1. Install dependencies:
   ```bash
   npm install
   ```
2. Start the development server:
   ```bash
   npm run dev
   ```
3. Open the provided local URL in your browser.

### Building the Android App
1. Open Android Studio.
2. Create a new "Empty Compose Activity" project with package name `com.focusguard.app`.
3. Copy the contents of `/native-android/` files into your project.
4. Build and install the `.apk` on your device.

## ⚠️ Important Note
To function correctly, the Android app requires:
- **Accessibility Service**: Must be manually enabled in System Settings.
- **Usage Access**: Must be authorized to track app sessions.
- **VPN Permission**: Must be granted to allow the network blocker to function.

## 📜 License
Apache-2.0
