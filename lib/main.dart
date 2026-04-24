import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MaterialApp(
      home: FocusGuardDashboard(),
      debugShowCheckedModeBanner: false,
    ));

class FocusGuardDashboard extends StatefulWidget {
  const FocusGuardDashboard({super.key});
  @override
  _FocusGuardDashboardState createState() => _FocusGuardDashboardState();
}

class _FocusGuardDashboardState extends State<FocusGuardDashboard> {
  static const platform = MethodChannel('com.focusguard/vpn');
  double _minutesLimit = 30;

  Future<void> _saveAndStart() async {
    try {
      await platform.invokeMethod('startVpnWithLimit', {"limit": _minutesLimit.toInt()});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("FocusGuard Activated! ⚔️")),
      );
    } on PlatformException catch (e) {
      debugPrint("Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("FocusGuard Pro", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigoAccent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_rounded, size: 100, color: Colors.indigoAccent),
            const SizedBox(height: 32),
            Text(
              "Set Daily Social Limit",
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "${_minutesLimit.toInt()} Minutes",
              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _minutesLimit,
              min: 1,
              max: 120,
              activeColor: Colors.indigoAccent,
              inactiveColor: Colors.white10,
              onChanged: (v) => setState(() => _minutesLimit = v),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveAndStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("START MONITORING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Facebook, Instagram aur YouTube ka internet block ho jayega jab limit khatam hogi.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }
}
