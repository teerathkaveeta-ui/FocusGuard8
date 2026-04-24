/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { 
  Wifi, 
  WifiOff, 
  Smartphone, 
  AlertTriangle, 
  ShieldAlert, 
  Clock, 
  Vibrate, 
  Bell, 
  CheckCircle2, 
  Play, 
  History,
  Terminal,
  ExternalLink,
  ChevronRight,
  ChevronDown,
  Info,
  Layers,
  Activity,
  Settings as SettingsIcon,
  ShieldCheck
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

// --- Constants ---

const TARGET_APPS = [
  { id: 'facebook', name: 'Facebook', package: 'com.facebook.katana', icon: 'FB' },
  { id: 'instagram', name: 'Instagram', package: 'com.instagram.android', icon: 'IG' },
  { id: 'youtube', name: 'YouTube', package: 'com.google.android.youtube', icon: 'YT' },
  { id: 'tiktok', name: 'TikTok', package: 'com.zhiliaoapp.musically', icon: 'TT' },
];

// --- Components ---

const TabButton = ({ 
  active, 
  onClick, 
  label, 
  icon: Icon, 
  activeClass 
}) => (
  <button
    onClick={onClick}
    className={`flex items-center gap-2 px-6 py-3 font-medium transition-all duration-300 border-b-2 ${
      active ? activeClass : 'border-transparent text-gray-500 hover:text-gray-700'
    }`}
  >
    <Icon className="w-4 h-4" />
    {label}
  </button>
);

const AppSelector = ({ 
  selected, 
  onToggle 
}) => (
  <div className="grid grid-cols-2 gap-3">
    {TARGET_APPS.map(app => (
      <button
        key={app.id}
        onClick={() => onToggle(app.id)}
        className={`flex items-center gap-3 p-3 rounded-xl border-2 transition-all ${
          selected.includes(app.id) 
            ? 'border-blue-500 bg-blue-50 text-blue-700' 
            : 'border-gray-100 bg-white text-gray-600 hover:border-gray-200'
        }`}
      >
        <div className={`w-8 h-8 rounded-lg flex items-center justify-center font-bold text-xs ${
          selected.includes(app.id) ? 'bg-blue-600 text-white' : 'bg-gray-100'
        }`}>
          {app.icon}
        </div>
        <span className="text-sm font-medium">{app.name}</span>
        {selected.includes(app.id) && <CheckCircle2 className="w-4 h-4 ml-auto" />}
      </button>
    ))}
  </div>
);

const TimeButton = ({ 
  label, 
  active, 
  onClick 
}) => (
  <button
    onClick={onClick}
    className={`px-4 py-2 rounded-lg border flex-1 text-sm font-medium transition-all ${
      active ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-gray-200 hover:border-blue-200'
    }`}
  >
    {label}
  </button>
);

const KotlinCodeBlock = () => {
  const [isOpen, setIsOpen] = useState(false);
  
  return (
    <div className="mt-8 border-t pt-8">
      <button 
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 text-gray-900 font-bold text-lg hover:text-blue-600 transition-colors"
      >
        <Terminal className="w-5 h-5" />
        Android Technical Implementation Plan
        <ChevronDown className={`w-5 h-5 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </button>
      
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="overflow-hidden"
          >
            <div className="bg-gray-900 rounded-xl p-6 mt-4 text-gray-300 text-sm font-mono overflow-x-auto">
              <div className="mb-4 text-blue-400">// AccessibilityService Detection Logic</div>
              <pre>{`class FocusAccessibilityService : AccessibilityService() {
    private val targetPackages = setOf("com.facebook.katana", "com.instagram.android")
    private var isLimitExceeded = false

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (targetPackages.contains(packageName) && isLimitExceeded) {
                // RESTRICT CORE: Turn OFF Connectivity
                toggleNetwork(false)
            } else {
                // RESTORE CORE: Turn ON Connectivity
                toggleNetwork(true)
            }
        }
    }

    private fun toggleNetwork(enabled: Boolean) {
        val wifiManager = getSystemService(Context.WIFI_SERVICE) as WifiManager
        // Note: wifiManager.setWifiEnabled is deprecated in Android 10+
        // Requires Settings.System permissions or Local VPN workaround as recommended.
        wifiManager.isWifiEnabled = enabled
    }
}`}</pre>
              
              <div className="mt-8 mb-4 text-green-400">// Till End Logic with AlarmManager</div>
              <pre>{`fun scheduleRestrictionEnd(endTimeMillis: Long) {
    val intent = Intent(this, RestrictionReceiver::class.java)
    val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, 0)
    
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarmManager.setExactAndAllowWhileIdle(
        AlarmManager.RTC_WAKEUP,
        endTimeMillis,
        pendingIntent
    )
}`}</pre>

              <div className="mt-8 p-4 bg-blue-900/30 border border-blue-800 rounded-lg">
                <p className="text-blue-200 font-bold mb-2">💡 Feasibility Check: Android 13+</p>
                <p>Since Android 10, apps cannot toggle Mobile Data or Wi-Fi programmatically for privacy reasons. The most robust workaround is implementing a <strong>Local VPN Service</strong> (\`VpnService\`). When the restricted app is in focus, the VPN routes traffic from that app (or all apps) to a "null" sink, effectively blocking the internet without needing system-level hardware toggles.</p>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default function App() {
  const [showPermissions, setShowPermissions] = useState(true);
  const [permissions, setPermissions] = useState({
    accessibility: false,
    usage: false,
    vpn: false
  });
  
  const [mode, setMode] = useState('alert');
  const [selectedApps, setSelectedApps] = useState([]);
  const [timeLimit, setTimeLimit] = useState(15); // minutes
  const [isCustomTime, setIsCustomTime] = useState(false);
  const [customHours, setCustomHours] = useState(0);
  const [customMinutes, setCustomMinutes] = useState(0);
  const [tillEndDate, setTillEndDate] = useState('');
  const [tillEndTime, setTillEndTime] = useState('');
  const [alertType, setAlertType] = useState('both');
  const [connectivity, setConnectivity] = useState('both');
  const [isActive, setIsActive] = useState(false);
  
  // Simulation State
  const [currentApp, setCurrentApp] = useState('Home');
  const [internetStatus, setInternetStatus] = useState(true);
  const [progress, setProgress] = useState(0);

  const toggleApp = (id) => {
    setSelectedApps(prev => 
      prev.includes(id) ? prev.filter(a => a !== id) : [...prev, id]
    );
  };

  const startLimit = () => {
    if (selectedApps.length === 0) {
      alert("Please select at least one app.");
      return;
    }

    const totalMinutes = isCustomTime ? (customHours * 60 + customMinutes) : timeLimit;
    
    if (totalMinutes <= 0) {
      alert("Please set a time limit greater than 0.");
      return;
    }

    if (mode === 'strict' && (!tillEndDate || !tillEndTime)) {
      alert("Please select an end date and time for Strict Mode.");
      return;
    }

    setIsActive(true);
    setProgress(100); // Simulate reaching limit immediately for demo
  };

  // Logic Simulation Effect
  useEffect(() => {
    if (!isActive) {
      setInternetStatus(true);
      return;
    }

    const appIds = TARGET_APPS.filter(a => selectedApps.includes(a.id)).map(a => a.name);
    const isRestrictedApp = appIds.includes(currentApp);

    if (mode === 'strict' && progress >= 100) {
      setInternetStatus(!isRestrictedApp);
    } else if (mode === 'alert' && progress >= 100 && isRestrictedApp) {
      // Logic for alert mode could trigger a vibrate/ring simulation
      console.log('Alert Triggered!');
    }
  }, [currentApp, isActive, mode, progress, selectedApps]);

  if (showPermissions) {
    return (
      <div className="min-h-screen bg-[#F8F9FA] flex items-center justify-center p-4">
        <motion.div 
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="max-w-md w-full bg-white rounded-3xl shadow-xl shadow-blue-100/50 border overflow-hidden p-8"
        >
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg shadow-blue-200">
               <ShieldCheck className="text-white w-8 h-8" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900">FocusGuard</h1>
            <p className="text-sm text-gray-500 mt-2 italic">Grant required permissions to begin monitoring</p>
          </div>

          <div className="space-y-4">
            <button 
              onClick={() => setPermissions(p => ({ ...p, accessibility: true }))}
              className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left ${
                permissions.accessibility ? 'border-green-500 bg-green-50' : 'border-gray-100 hover:border-blue-100 bg-white'
              }`}
            >
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${permissions.accessibility ? 'bg-green-100 text-green-600' : 'bg-blue-50 text-blue-500'}`}>
                <SettingsIcon className="w-5 h-5" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-bold text-gray-900 leading-none mb-1">Accessibility Service</p>
                <p className="text-xs text-gray-500">Enable in System Settings</p>
              </div>
              {permissions.accessibility && <CheckCircle2 className="w-5 h-5 text-green-500" />}
            </button>

            <button 
              onClick={() => setPermissions(p => ({ ...p, usage: true }))}
              className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left ${
                permissions.usage ? 'border-green-500 bg-green-50' : 'border-gray-100 hover:border-blue-100 bg-white'
              }`}
            >
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${permissions.usage ? 'bg-green-100 text-green-600' : 'bg-blue-50 text-blue-500'}`}>
                <Activity className="w-5 h-5" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-bold text-gray-900 leading-none mb-1">Usage Access</p>
                <p className="text-xs text-gray-500">Permit session tracking</p>
              </div>
              {permissions.usage && <CheckCircle2 className="w-5 h-5 text-green-500" />}
            </button>

            <button 
              onClick={() => setPermissions(p => ({ ...p, vpn: true }))}
              className={`w-full flex items-center gap-4 p-4 rounded-2xl border-2 transition-all text-left ${
                permissions.vpn ? 'border-green-500 bg-green-50' : 'border-gray-100 hover:border-blue-100 bg-white'
              }`}
            >
              <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${permissions.vpn ? 'bg-green-100 text-green-600' : 'bg-blue-50 text-blue-500'}`}>
                <Layers className="w-5 h-5" />
              </div>
              <div className="flex-1">
                <p className="text-sm font-bold text-gray-900 leading-none mb-1">Network Blocker</p>
                <p className="text-xs text-gray-500">Authorize local VPN</p>
              </div>
              {permissions.vpn && <CheckCircle2 className="w-5 h-5 text-green-500" />}
            </button>
          </div>

          <button
            onClick={() => setShowPermissions(false)}
            disabled={!permissions.accessibility || !permissions.usage || !permissions.vpn}
            className={`w-full mt-8 py-4 rounded-2xl font-bold transition-all ${
              permissions.accessibility && permissions.usage && permissions.vpn
                ? 'bg-blue-600 text-white shadow-lg shadow-blue-200 hover:bg-blue-700 active:scale-95'
                : 'bg-gray-100 text-gray-400 cursor-not-allowed'
            }`}
          >
            Enter Dashboard
          </button>
        </motion.div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F8F9FA] font-sans text-gray-900">
      {/* --- Fixed Header --- */}
      <header className="bg-white border-b px-6 py-4 sticky top-0 z-50 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="bg-blue-600 p-2 rounded-lg">
            <Smartphone className="text-white w-5 h-5" />
          </div>
          <h1 className="font-bold text-xl tracking-tight">FocusGuard</h1>
        </div>
        <div className="flex items-center gap-3">
          <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold ${
            internetStatus ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
          }`}>
            {internetStatus ? <Wifi className="w-3.5 h-3.5" /> : <WifiOff className="w-3.5 h-3.5" />}
            {internetStatus ? 'INTERNET ON' : 'INTERNET CUT'}
          </div>
        </div>
      </header>

      <main className="max-w-md mx-auto p-4 pb-24">
        
        {/* --- Tabs --- */}
        <div className="bg-white rounded-2xl shadow-sm border overflow-hidden mb-6">
          <div className="flex bg-gray-50/50">
            <TabButton 
              label="Alert Mode" 
              icon={AlertTriangle} 
              active={mode === 'alert'} 
              onClick={() => setMode('alert')}
              activeClass="border-yellow-400 text-yellow-700 bg-white"
            />
            <TabButton 
              label="Strict Mode" 
              icon={ShieldAlert} 
              active={mode === 'strict'} 
              onClick={() => setMode('strict')}
              activeClass="border-red-500 text-red-700 bg-white"
            />
          </div>

          <div className="p-6">
            <AnimatePresence mode="wait">
              <motion.div
                key={mode}
                initial={{ opacity: 0, x: mode === 'alert' ? -20 : 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: mode === 'alert' ? 20 : -20 }}
                transition={{ duration: 0.2 }}
                className="space-y-6"
              >
                {/* --- Section: Time Limit --- */}
                <div>
                  <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                    <Clock className="w-4 h-4" /> Time Limit
                  </h3>
                  <div className="flex gap-2 mb-4">
                    {[1, 15, 60].map(t => (
                      <TimeButton 
                        key={t}
                        label={t >= 60 ? '1 hr' : `${t} min`}
                        active={!isCustomTime && timeLimit === t}
                        onClick={() => {
                          setTimeLimit(t);
                          setIsCustomTime(false);
                        }}
                      />
                    ))}
                    <button 
                      onClick={() => setIsCustomTime(true)}
                      className={`px-4 py-2 rounded-lg border text-sm font-medium transition-all ${
                        isCustomTime ? 'border-blue-500 bg-blue-50 text-blue-700' : 'border-gray-200 hover:border-blue-200'
                      }`}
                    >
                      Custom
                    </button>
                  </div>

                  <AnimatePresence>
                    {isCustomTime && (
                      <motion.div 
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        className="overflow-hidden"
                      >
                        <div className="grid grid-cols-2 gap-4 p-4 bg-gray-50 rounded-xl border border-gray-100">
                          <div className="space-y-2">
                            <label className="text-[10px] font-bold text-gray-400 uppercase">Hours</label>
                            <input 
                              type="number" 
                              min="0"
                              max="23"
                              value={customHours}
                              onChange={(e) => setCustomHours(Math.max(0, parseInt(e.target.value) || 0))}
                              className="w-full bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                              placeholder="0"
                            />
                          </div>
                          <div className="space-y-2">
                            <label className="text-[10px] font-bold text-gray-400 uppercase">Minutes</label>
                            <input 
                              type="number" 
                              min="0"
                              max="59"
                              value={customMinutes}
                              onChange={(e) => setCustomMinutes(Math.max(0, parseInt(e.target.value) || 0))}
                              className="w-full bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500"
                              placeholder="0"
                            />
                          </div>
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>
                </div>

                {/* --- Section: Mode Specifics --- */}
                {mode === 'alert' ? (
                  <div>
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                      <Bell className="w-4 h-4" /> Alert Type
                    </h3>
                    <div className="flex gap-3">
                      {[
                        { id: 'vibrate', label: 'Vibrate', icon: Vibrate },
                        { id: 'ring', label: 'Ring', icon: Bell },
                        { id: 'both', label: 'Both', icon: Smartphone },
                      ].map(type => (
                        <button
                          key={type.id}
                          onClick={() => setAlertType(type.id)}
                          className={`flex-1 flex flex-col items-center gap-2 p-3 rounded-xl border-2 transition-all ${
                            alertType === type.id 
                              ? 'border-yellow-400 bg-yellow-50 text-yellow-700' 
                              : 'border-gray-100 bg-white hover:border-gray-200'
                          }`}
                        >
                          <type.icon className="w-5 h-5" />
                          <span className="text-xs font-bold">{type.label}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                ) : (
                  <div>
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                      <Wifi className="w-4 h-4" /> Connectivity Toggle
                    </h3>
                    <div className="flex gap-3">
                      {[
                        { id: 'wifi', label: 'Wi-Fi', icon: Wifi },
                        { id: 'data', label: 'Mobile Data', icon: Smartphone },
                        { id: 'both', label: 'Both', icon: ShieldAlert },
                      ].map(type => (
                        <button
                          key={type.id}
                          onClick={() => setConnectivity(type.id)}
                          className={`flex-1 flex flex-col items-center gap-2 p-3 rounded-xl border-2 transition-all ${
                            connectivity === type.id 
                              ? 'border-red-500 bg-red-50 text-red-700' 
                              : 'border-gray-100 bg-white hover:border-gray-200'
                          }`}
                        >
                          <type.icon className="w-5 h-5" />
                          <span className="text-xs font-bold">{type.label}</span>
                        </button>
                      ))}
                    </div>
                    
                    <div className="mt-6 pt-6 border-t border-gray-100">
                       <label className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-3 block flex items-center gap-2">
                          <History className="w-4 h-4" /> Till End Date & Time
                       </label>
                       <div className="grid grid-cols-2 gap-3">
                          <div className="space-y-2">
                            <label className="text-[10px] font-bold text-gray-400 uppercase">Date</label>
                            <input 
                              type="date" 
                              value={tillEndDate}
                              onChange={(e) => setTillEndDate(e.target.value)}
                              className="w-full bg-white border border-gray-200 rounded-xl px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500"
                            />
                          </div>
                          <div className="space-y-2">
                            <label className="text-[10px] font-bold text-gray-400 uppercase">Time</label>
                            <input 
                              type="time" 
                              value={tillEndTime}
                              onChange={(e) => setTillEndTime(e.target.value)}
                              className="w-full bg-white border border-gray-200 rounded-xl px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-500/20 focus:border-red-500"
                            />
                          </div>
                       </div>
                       <p className="mt-3 text-[10px] text-gray-500 leading-relaxed italic">
                          * Restriction cycle will remain active until this specific moment.
                       </p>
                    </div>
                  </div>
                )}

                {/* --- Section: App Selection --- */}
                <div>
                  <h3 className="text-sm font-bold text-gray-400 uppercase tracking-widest mb-3">Target Apps</h3>
                  <AppSelector 
                    selected={selectedApps} 
                    onToggle={toggleApp} 
                  />
                </div>

                <button
                  onClick={startLimit}
                  disabled={isActive}
                  className={`w-full py-4 rounded-xl font-bold flex items-center justify-center gap-2 transition-all transform active:scale-95 ${
                    isActive 
                      ? 'bg-green-100 text-green-600 cursor-default' 
                      : 'bg-blue-600 hover:bg-blue-700 text-white shadow-lg shadow-blue-200' 
                  }`}
                >
                  {isActive ? (
                    <>
                      <CheckCircle2 className="w-5 h-5" />
                      Session Active
                    </>
                  ) : (
                    <>
                      <Play className="w-5 h-5 fill-current" />
                      Start Limit
                    </>
                  )}
                </button>
              </motion.div>
            </AnimatePresence>
          </div>
        </div>

        {/* --- Simulation Tooltip --- */}
        {isActive && (
          <motion.div 
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-gray-900 rounded-2xl p-6 shadow-2xl space-y-4 border border-gray-800"
          >
            <div className="flex items-center justify-between">
              <h2 className="text-white font-bold text-sm tracking-widest uppercase flex items-center gap-2">
                <Terminal className="w-4 h-4 text-blue-400" /> System Simulator
              </h2>
              <button 
                onClick={() => setIsActive(false)}
                className="text-gray-400 hover:text-white text-xs underline"
              >
                Stop Monitoring
              </button>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <span className="text-[10px] text-gray-500 font-bold uppercase">Simulated Status</span>
                <div className="flex items-center gap-2 text-white font-mono text-sm">
                  <div className={`w-2 h-2 rounded-full animate-pulse ${progress >= 100 ? 'bg-red-500' : 'bg-green-500'}`} />
                  {progress >= 100 ? 'LIMIT EXCEEDED' : 'MONITORING'}
                </div>
              </div>
              <div className="space-y-2 text-right">
                <span className="text-[10px] text-gray-500 font-bold uppercase">Current Network</span>
                <div className={`font-mono text-sm font-bold ${internetStatus ? 'text-green-400' : 'text-red-400'}`}>
                  {internetStatus ? 'ONLINE ⚡' : 'OFFLINE 🛡️'}
                </div>
              </div>
            </div>

            {mode === 'strict' && tillEndDate && (
              <div className="pt-2 border-t border-gray-800">
                <div className="flex items-center justify-between">
                   <span className="text-[10px] text-gray-500 font-bold uppercase">Scheduled End</span>
                   <span className="text-blue-400 font-mono text-[10px] font-bold">
                      {tillEndDate} @ {tillEndTime}
                   </span>
                </div>
              </div>
            )}

            <div className="pt-2">
              <span className="text-[10px] text-gray-500 font-bold uppercase mb-2 block">Foreground App (Switch to test)</span>
              <div className="flex flex-wrap gap-2">
                {['Home', 'Facebook', 'Instagram', 'Mail', 'Browser'].map(app => (
                  <button 
                    key={app}
                    onClick={() => setCurrentApp(app)}
                    className={`px-3 py-1 rounded-md text-xs font-medium transition-all ${
                      currentApp === app 
                        ? 'bg-blue-600 text-white border-blue-500' 
                        : 'bg-gray-800 text-gray-400 border-gray-700 hover:bg-gray-700'
                    } border`}
                  >
                    {app}
                  </button>
                ))}
              </div>
            </div>

            {isActive && currentApp !== 'Home' && selectedApps.includes(TARGET_APPS.find(a => a.name === currentApp)?.id) && (
              <div className="bg-red-900/40 p-3 rounded-lg border border-red-800/50 flex items-start gap-3">
                <Info className="w-4 h-4 text-red-400 mt-0.5 shrink-0" />
                <p className="text-xs text-red-200 leading-relaxed font-medium">
                  <strong>System Action:</strong> Restricted app detected. 
                  {mode === 'strict' ? ' Network cut triggered.' : ' Alert feedback active (Vibrate/Ring).'}
                </p>
              </div>
            )}
          </motion.div>
        )}

        {/* --- Android Implementation Summary --- */}
        <KotlinCodeBlock />

        <div className="mt-8 text-center">
          <p className="text-gray-400 text-xs">FocusGuard Protocol v1.0.2</p>
          <div className="flex justify-center gap-4 mt-2">
            <button className="text-gray-400 hover:text-blue-600 flex items-center gap-1 text-[10px] font-bold">
              PRIVACY POLICY <ExternalLink className="w-2.5 h-2.5" />
            </button>
            <button className="text-gray-400 hover:text-blue-600 flex items-center gap-1 text-[10px] font-bold">
              TERMS OF SERVICE <ExternalLink className="w-2.5 h-2.5" />
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}
