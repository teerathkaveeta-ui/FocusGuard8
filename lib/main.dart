import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  static const platform = MethodChannel('com.focusguard/vpn');
  late TabController _tabController;
  int _hours = 0;
  int _minutes = 15;
  DateTime? _strictUntil;
  String _mode = 'alert';
  String? _savedPin;
  final Set<String> _selectedApps = {};
  bool _isActive = false;

  final List<Map<String, String>> apps = [
    {'id': 'facebook', 'name': 'Facebook', 'package': 'com.facebook.katana', 'icon': 'FB'},
    {'id': 'instagram', 'name': 'Instagram', 'package': 'com.instagram.android', 'icon': 'IG'},
    {'id': 'youtube', 'name': 'YouTube', 'package': 'com.google.android.youtube', 'icon': 'YT'},
    {'id': 'tiktok', 'name': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icon': 'TT'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_isActive && _savedPin != null) {
          // Temporarily revert the index change until authorized
          final targetIndex = _tabController.index;
          _tabController.index = _mode == 'alert' ? 0 : 1;
          
          _showPinDialog(
            isSetting: false,
            onAuth: (pin) {
              if (pin == _savedPin) {
                setState(() {
                  _tabController.index = targetIndex;
                  _mode = targetIndex == 0 ? 'alert' : 'strict';
                  if (_mode == 'alert') _strictUntil = null;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect PIN!")));
              }
            },
          );
        } else {
          setState(() {
            _mode = _tabController.index == 0 ? 'alert' : 'strict';
            if (_mode == 'alert') _strictUntil = null;
          });
        }
      }
    });
  }

  Future<void> _showPinDialog({required bool isSetting, Function(String)? onAuth}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isSetting ? "Set Security PIN" : "Enter PIN to Unlock"),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: "4 Digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                if (isSetting) {
                  setState(() => _savedPin = controller.text);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Saved Successfully")));
                } else if (onAuth != null) {
                  onAuth(controller.text);
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Confirm"),
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
    return Scaffold(
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
              PopupMenuItem(value: 'pin', child: Text(_savedPin == null ? "Modify, Change your pin or lock your shield" : "Modify Security Lock")),
            ],
          ),
        ],
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildShieldHealth(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(
                        width: 3.0,
                        color: _mode == 'alert' ? Colors.orange : Colors.red,
                      ),
                      insets: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    labelColor: _mode == 'alert' ? Colors.orange[800] : Colors.red[800],
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Alert Mode", icon: Icon(Icons.notifications_active_outlined)),
                      Tab(text: "Strict Mode", icon: Icon(Icons.gpp_maybe_outlined)),
                    ],
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("CUSTOM TIME LIMIT", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _timeSelector("HR", _hours, (v) => setState(() => _hours = v), 23),
                            const Text(" : ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            _timeSelector("MIN", _minutes, (v) => setState(() => _minutes = v), 59),
                          ],
                        ),
                        if (_mode == 'strict') ...[
                          const SizedBox(height: 24),
                          const Text("LOCK UNTIL (FIXED DATE)", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDateTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _strictUntil == null 
                                          ? "Select Expiry Date & Time" 
                                          : "Lock until: ${_strictUntil!.day}/${_strictUntil!.month} ${_strictUntil!.hour}:${_strictUntil!.minute}",
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                  if (_strictUntil != null) IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _strictUntil = null)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        const Text("SHIELD APPLICATIONS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.5),
                          itemCount: apps.length,
                          itemBuilder: (context, index) => _appTile(apps[index]),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isActive ? null : _startMonitoring,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _mode == 'alert' ? const Color(0xFF2563EB) : Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.green[100],
                              disabledForegroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: _isActive
                                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_rounded), SizedBox(width: 8), Text("Shield Active", style: TextStyle(fontWeight: FontWeight.bold))])
                                : Text(_mode == 'alert' ? "ENABLE ALERTS" : "ACTIVATE STRICT LOCK", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        if (_isActive) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: _stopMonitoring,
                              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                              label: const Text("STOP SHIELD", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.red)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _showPinDialog(isSetting: true),
                  icon: const Icon(Icons.lock_outline, color: Colors.blueGrey, size: 20),
                  tooltip: "Set Parental PIN",
                ),
                Text(
                  _savedPin != null ? "PIN Lock Enabled" : "No PIN Protection",
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _mode == 'alert' 
                ? "Alert Mode: Plays voice notification & vibrates when limit ends."
                : "Strict Mode: Blocks network for selected apps after limit/date.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildShieldHealth() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Focus Shield Active", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    const Text("Play Protect may flag this app as it manages network. It is safe and local-only.", style: TextStyle(fontSize: 11, color: Colors.blueGrey)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.blue),
          const Text(
            "Note: The VPN icon removal depends on system. Shield blocks only foreground social apps.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
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
              decoration: BoxDecoration(color: selected ? Colors.blue : Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(app['icon']!, style: TextStyle(color: selected ? Colors.white : Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(app['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}
