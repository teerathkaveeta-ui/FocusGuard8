import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const FocusGuardApp());

class FocusGuardApp extends StatelessWidget {
  const FocusGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusGuard Pro',
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
  int _minutesLimit = 15;
  String _mode = 'alert';
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
      setState(() {
        _mode = _tabController.index == 0 ? 'alert' : 'strict';
      });
    });
  }

  Future<void> _startMonitoring() async {
    if (_selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select at least one app")));
      return;
    }

    try {
      final selectedPackages = apps
          .where((app) => _selectedApps.contains(app['id']))
          .map((app) => app['package'])
          .toList();

      await platform.invokeMethod('startVpnWithLimit', {
        "limit": _minutesLimit,
        "packages": selectedPackages,
        "mode": _mode,
      });

      setState(() => _isActive = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("FocusGuard Activated! ⚔️")));
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
              child: const Icon(Icons.smartphone, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text("FocusGuard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.wifi, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text("INTERNET ON", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Alert Mode", icon: Icon(Icons.warning_amber_rounded)),
                        Tab(text: "Strict Mode", icon: Icon(Icons.security_rounded)),
                      ],
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                              const SizedBox(width: 8),
                              const Text("TIME LIMIT", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [1, 15, 60].map((t) {
                              final active = _minutesLimit == t;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _minutesLimit = t),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: active ? const Color(0xFFEFF6FF) : Colors.transparent,
                                      side: BorderSide(color: active ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: Text(t >= 60 ? "1 hr" : "$t min", style: TextStyle(color: active ? const Color(0xFF1D4ED8) : Colors.grey[700], fontSize: 12)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text("TARGET APPS", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.8),
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              final selected = _selectedApps.contains(app['id']);
                              return InkWell(
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedApps.remove(app['id']);
                                  } else {
                                    _selectedApps.add(app['id']!);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: selected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(color: selected ? Colors.blue[600] : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                        alignment: Alignment.center,
                                        child: Text(app['icon']!, style: TextStyle(color: selected ? Colors.white : Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(app['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                      if (selected) const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isActive ? null : _startMonitoring,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.green[100],
                                disabledForegroundColor: Colors.green[700],
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: _isActive
                                  ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check), SizedBox(width: 8), Text("Session Active", style: TextStyle(fontWeight: FontWeight.bold))])
                                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow), SizedBox(width: 8), Text("Start Limit", style: TextStyle(fontWeight: FontWeight.bold))]),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(child: Text("FocusGuard Protocol v1.0.2", style: TextStyle(color: Colors.grey, fontSize: 11))),
            ],
          ),
        ),
      ),
    );
  }
}
