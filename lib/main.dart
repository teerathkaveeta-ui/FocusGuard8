import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FocusGuardApp());

class FocusGuardApp extends StatelessWidget {
  const FocusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
          surface: const Color(0xFFF8F9FA),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  bool _showPermissions = true;

  @override
  Widget build(BuildContext context) {
    return _showPermissions
        ? PermissionsScreen(onComplete: () => setState(() => _showPermissions = false))
        : const DashboardScreen();
  }
}

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _accessibilityGranted = false;
  bool _usageGranted = false;
  bool _vpnAuthorized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                "FocusGuard",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const Text(
                "Grant required permissions to begin monitoring",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),
              _PermissionTile(
                icon: Icons.settings_outlined,
                title: "Accessibility Service",
                subtitle: "Enable in System Settings",
                granted: _accessibilityGranted,
                onTap: () => setState(() => _accessibilityGranted = true),
              ),
              const SizedBox(height: 16),
              _PermissionTile(
                icon: Icons.bar_chart_outlined,
                title: "Usage Access",
                subtitle: "Permit session tracking",
                granted: _usageGranted,
                onTap: () => setState(() => _usageGranted = true),
              ),
              const SizedBox(height: 16),
              _PermissionTile(
                icon: Icons.layers_outlined,
                title: "Network Blocker",
                subtitle: "Authorize local VPN",
                granted: _vpnAuthorized,
                onTap: () => setState(() => _vpnAuthorized = true),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_accessibilityGranted && _usageGranted && _vpnAuthorized)
                      ? widget.onComplete
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("Enter Dashboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: granted ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: granted ? Colors.green[500]! : const Color(0xFFF1F5F9),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: granted ? Colors.green[100] : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: granted ? Colors.green[600] : const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (granted) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const platform = MethodChannel('com.focusguard/vpn');
  int _hours = 0;
  int _minutes = 15;
  DateTime? _strictUntil;
  String _mode = 'alert'; // 'alert' or 'strict'
  bool _isActive = false;
  String? _savedPin;
  final Set<String> _selectedApps = {};

  final List<Map<String, String>> apps = [
    {'id': 'facebook', 'name': 'Facebook', 'package': 'com.facebook.katana', 'icon': 'FB'},
    {'id': 'instagram', 'name': 'Instagram', 'package': 'com.instagram.android', 'icon': 'IG'},
    {'id': 'youtube', 'name': 'YouTube', 'package': 'com.google.android.youtube', 'icon': 'YT'},
    {'id': 'tiktok', 'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icon': 'TT'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _attemptModeChange(String newMode) async {
    if (_isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Action Blocked: Please stop the current Shield before switching modes."))
      );
      return;
    }
    
    if (_savedPin != null) {
      await _showPinDialog(
        isSetting: false,
        onAuth: (pin) async {
          final prefs = await SharedPreferences.getInstance();
          final actualPin = prefs.getString('security_pin');
          if (pin == actualPin) {
            setState(() {
              _mode = newMode;
              if (_mode == 'alert') _strictUntil = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid PIN! Access Denied.")));
          }
        },
      );
    } else {
      setState(() {
        _mode = newMode;
        if (_mode == 'alert') _strictUntil = null;
      });
    }
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPin = prefs.getString('security_pin');
    });
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('security_pin', pin);
    setState(() => _savedPin = pin);
  }

  Future<void> _showPinDialog({required bool isSetting, Function(String)? onAuth}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSetting ? "Set Parental Control PIN" : "PIN Verification Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This PIN secures your shield settings.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: "****",
                counterText: "",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final enteringPin = controller.text;
              if (enteringPin.length == 4) {
                Navigator.pop(context); // Close FIRST
                if (isSetting) {
                  await _savePin(enteringPin);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Successfully Recorded")));
                } else if (onAuth != null) {
                  onAuth(enteringPin);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter exactly 4 digits")));
              }
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  Future<void> _stopMonitoring() async {
    if (_savedPin != null) {
      await _showPinDialog(
        isSetting: false,
        onAuth: (pin) async {
          if (pin == _savedPin) {
            await _performStop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect PIN!")));
          }
        },
      );
    } else {
      await _performStop();
    }
  }

  Future<void> _performStop() async {
    try {
      await platform.invokeMethod('stopVpn');
      setState(() => _isActive = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("FocusGuard Deactivated")));
    } catch (e) {
      debugPrint("Stop Error: $e");
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _strictUntil = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _startMonitoring() async {
    if (_selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select target apps")));
      return;
    }

    final totalMinutes = (_hours * 60) + _minutes;
    if (totalMinutes == 0 && _strictUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Set a limit or lock date")));
      return;
    }

    try {
      final selectedPackages = apps
          .where((app) => _selectedApps.contains(app['id']))
          .map((app) => app['package'])
          .toList();

      await platform.invokeMethod('startVpnWithLimit', {
        "limit": totalMinutes,
        "packages": selectedPackages,
        "mode": _mode,
        "strictUntil": _strictUntil?.millisecondsSinceEpoch,
      });

      setState(() => _isActive = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("FocusGuard Shield ON 🛡️")));
    } on PlatformException catch (e) {
      debugPrint("Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text("FocusGuard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          bottom: TabBar(
            onTap: (index) {
              final newMode = index == 0 ? 'alert' : 'strict';
              if (_isActive && newMode != _mode) {
                // If active, prevent switching tab visually by forcing it back or showing warning
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Shield Active: Terminate current shield to switch modes."))
                );
              } else if (newMode != _mode) {
                _attemptModeChange(newMode);
              }
            },
            tabs: const [
              Tab(text: "ALERT MODE", icon: Icon(Icons.notifications_active_outlined)),
              Tab(text: "STRICT MODE", icon: Icon(Icons.lock_person_outlined)),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'contact') {
                  platform.invokeMethod('contactDeveloper');
                } else if (val == 'pin') {
                  _showPinDialog(isSetting: true);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'contact', child: Text("Contact Me")),
                PopupMenuItem(value: 'pin', child: Text(_savedPin == null ? "Set Security Lock PIN" : "Modify Security Lock")),
              ],
            ),
          ],
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: TabBarView(
          physics: _isActive ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          children: [
            _buildModeView('alert'),
            _buildModeView('strict'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeView(String modeName) {
    bool isCurrentTabActiveMode = _isActive && _mode == modeName;
    bool isOtherTabActive = _isActive && _mode != modeName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildShieldHealth(modeName),
          const SizedBox(height: 16),
          if (isOtherTabActive)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(child: Text("Another Shield mode is currently active. Stop it first to use this mode.", 
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "${modeName.toUpperCase()} CONFIGURATION", 
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)
                    ),
                  ),
                  const Divider(height: 1),
                  _buildConfigPage(
                    modeName == 'alert' ? "Focus Alerts" : "Strict Shield",
                    modeName == 'alert' 
                      ? "Alerts you with sound/vibration when target apps are opened. No blocking."
                      : "Completely blocks internet access for target apps once time limit is reached.",
                    modeName == 'strict'
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isActive ? null : _startMonitoring,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: modeName == 'alert' ? const Color(0xFF2563EB) : Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isCurrentTabActiveMode ? Colors.green[50] : Colors.grey[100],
                              disabledForegroundColor: isCurrentTabActiveMode ? Colors.green[700] : Colors.grey[400],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: isCurrentTabActiveMode
                                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_user), SizedBox(width: 8), Text("Shield Active", style: TextStyle(fontWeight: FontWeight.bold))])
                                : Text("ACTIVATE ${modeName.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        if (isCurrentTabActiveMode) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _stopMonitoring,
                              icon: const Icon(Icons.stop_circle, color: Colors.red),
                              label: const Text("TERMINATE SHIELD", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShieldHealth(String modeName) {
    bool isThisModeActive = _isActive && _mode == modeName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isThisModeActive ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isThisModeActive ? Colors.green[100]! : Colors.blue[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(isThisModeActive ? Icons.verified_user : Icons.shield_outlined, color: isThisModeActive ? Colors.green : Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isThisModeActive ? "Shield is Standing Guard" : "Shield Standby", 
                     style: TextStyle(fontWeight: FontWeight.bold, color: isThisModeActive ? Colors.green[900] : Colors.blue[900], fontSize: 15)),
                Text(isThisModeActive ? "Monitoring selected apps for usage." : "Configure and tap Start.", 
                     style: TextStyle(fontSize: 11, color: isThisModeActive ? Colors.green[700] : Colors.blue[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigPage(String title, String desc, bool isStrict) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeSelector("HOURS", _hours, (v) => setState(() => _hours = v), 23),
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: Text(":", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              _timeSelector("MINUTES", _minutes, (v) => setState(() => _minutes = v), 59),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text("Target Application (Select One)", 
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: apps.map((app) => SizedBox(width: 135, child: _appTile(app))).toList(),
          ),
          if (isStrict) ...[
            const SizedBox(height: 24),
            InkWell(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off_outlined, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Terminal Lock Date (Optional)", 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                          Text(
                            _strictUntil == null 
                              ? "No hard lock set" 
                              : "Locked until: ${_strictUntil.toString().split('.')[0]}",
                            style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.calendar_month, color: Colors.red, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text("Privacy & Security Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              if (_savedPin != null) const Icon(Icons.lock, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Security & Safe Usage Details:\n\n"
            "🛡️ FocusGuard operates 100% locally on your phone. No internet data is tracked or shared.\n\n"
            "⚠️ ATTENTION: Because FocusGuard uses a local VPN to managed network traffic, some generic antiviruses may flag it as 'suspicious' or a 'virus'. This is a FALSE POSITIVE.\n\n"
            "🛡️ This app contains NO viral code. It only blocks social media apps to help you focus.\n\n"
            "🛡️ You can verify your internet remains safe for all other applications.",
            style: TextStyle(fontSize: 11, color: Colors.grey[700], height: 1.6),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showPinDialog(isSetting: true),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _savedPin != null ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _savedPin != null ? "Security Lock: ENABLED" : "Security Lock: UNSET", 
                    style: TextStyle(
                      color: _savedPin != null ? Colors.green[700] : Colors.orange[700], 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                const Spacer(),
                const Text("Modify Settings", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500)),
                const Icon(Icons.chevron_right, size: 16, color: Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSelector(String label, int value, Function(int) onChanged, int max) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              IconButton(icon: const Icon(Icons.keyboard_arrow_up), onPressed: () => onChanged(value < max ? value + 1 : 0)),
              Text(value.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => onChanged(value > 0 ? value - 1 : max)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _appTile(Map<String, String> app) {
    final selected = _selectedApps.contains(app['id']);
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedApps.remove(app['id']);
          } else {
            _selectedApps.clear();
            _selectedApps.add(app['id']!);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? Colors.blue : const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: selected ? Colors.blue : Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(app['icon']!, style: TextStyle(color: selected ? Colors.white : Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(app['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            if (selected) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
          ],
        ),
      ),
    );
  }
}
