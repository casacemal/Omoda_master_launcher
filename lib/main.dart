import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:chery_master_launcher/omoda_launcher_screen.dart';

void main() {
  runApp(const OmodaMasterLauncher());
}

class OmodaMasterLauncher extends StatelessWidget {
  const OmodaMasterLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Omoda Master Launcher',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFFB71C1C),
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'NotoSans'),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const platform = MethodChannel('com.example.omodalauncher/apps');

  String _timeString = "";
  String _dateString = "";
  late Timer _timer;
  bool _isPlaying = true;
  late Future<List<dynamic>?> _appsFuture;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _getApps();
  }

  Future<void> _getApps() async {
    _appsFuture = platform.invokeMethod<List<dynamic>>('getInstalledApps');
  }

  Future<void> _launchApp(String packageName) async {
    try {
      await platform.invokeMethod('launchApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to launch app: '${e.message}'.");
    }
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm').format(now);
      _dateString = DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _runCommand(String desc, String cmd) async {
    final List<String> allowed = [
      'am',
      'pm',
      'input',
      'settings',
      'appops',
      'reboot'
    ];
    final String baseCmd = cmd.split(' ')[0];

    if (!allowed.contains(baseCmd)) {
      _showNotify("Güvenlik Engeli: $baseCmd izni yok.");
      return;
    }

    try {
      debugPrint("İşlem: $desc | Komut: $cmd");
      List<String> parts = cmd.split(' ');
      await Process.run(parts[0], parts.sublist(1));
      _showNotify("$desc başlatıldı.");
    } catch (e) {
      _showNotify("Sistem Komutu Gönderildi: $desc");
      debugPrint("Shell Execute Error (Genellikle yetki eksikliği): $e");
    }
  }

  void _showNotify(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB71C1C),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF121212), Color(0xFF050505)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildMediaCard(),
                              const SizedBox(height: 16),
                              _buildStatusCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildAppGrid(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 90,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(right: BorderSide(color: Colors.white10, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(2, 0))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child:
                Icon(Icons.directions_car, color: Color(0xFFB71C1C), size: 36),
          ),
          _SidebarItem(
              icon: Icons.home_rounded,
              label: "Ana Sayfa",
              onTap: () => _runCommand("Ana Ekran", "input keyevent 3")),
          _SidebarItem(
              icon: Icons.ac_unit_rounded,
              label: "Klima",
              onTap: () => _runCommand("Klima Paneli",
                  "am start -n com.yfve.hvac/com.yfve.hvac.MainActivity")),
          _SidebarItem(
            icon: Icons.directions_car_filled_rounded,
            label: "Araç Modu",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OmodaLauncherScreen()),
              );
            },
          ),
          _SidebarItem(
              icon: Icons.map_rounded,
              label: "Harita",
              onTap: () => _runCommand(
                  "Navigasyon", "am start -a android.intent.action.VIEW")),
          const Spacer(),
          _SidebarItem(
            icon: Icons.settings_backup_restore_rounded,
            label: "Sistem",
            isHighlight: true,
            onTap: () {
              _runCommand("Sistem Uyanışı", "pm enable com.yfve.launcher");
              _runCommand("Orijinal Dashboard",
                  "am start -n com.yfve.launcher/com.yfve.launcher.LauncherActivity");
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_timeString,
                style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Oswald',
                    height: 1.0)),
            Text(_dateString,
                style: const TextStyle(
                    fontSize: 16, color: Colors.white54, letterSpacing: 1.2)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(13),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              _TopIcon(Icons.wifi, Colors.greenAccent.shade400),
              const SizedBox(width: 16),
              _TopIcon(Icons.bluetooth, Colors.blueAccent.shade400),
              const SizedBox(width: 16),
              _TopIcon(Icons.gps_fixed, Colors.amberAccent.shade400),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMediaCard() {
    return _DashboardCard(
      height: 140,
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFF7F0000)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Color(0xFFB71C1C), blurRadius: 15)
              ],
            ),
            child: const Icon(Icons.music_note_rounded,
                size: 45, color: Colors.white),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ŞİMDİ ÇALIYOR",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                SizedBox(height: 8),
                Text("Omoda Master Audio",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        overflow: TextOverflow.ellipsis)),
                Text("Sistem Medya Kontrolü",
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
                _isPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                size: 50,
                color: Colors.white),
            onPressed: () {
              setState(() {
                _isPlaying = !_isPlaying;
              });
              _runCommand("Medya Oynat/Duraklat", "input keyevent 85");
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return const _DashboardCard(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatusItem(Icons.speed_rounded, "0", "km/h", Colors.white),
          _StatusItem(Icons.thermostat_rounded, "22", "°C", Colors.orange),
          _StatusItem(Icons.tire_repair_rounded, "32", "psi", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildAppGrid() {
    return FutureBuilder<List<dynamic>?>(
      future: _appsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List<dynamic> apps = snapshot.data!;
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            Map<dynamic, dynamic> app = apps[index];
            return _AppIcon(
              app['icon'] != null
                  ? Image.memory(app['icon'] as Uint8List,
                      width: 40, height: 40)
                  : const Icon(Icons.apps, size: 40, color: Colors.white),
              app['appName'] ?? "(No name)",
              Colors.white,
              onTap: () => _launchApp(app['packageName']!),
            );
          },
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlight;

  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        hoverColor: Colors.white10,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon,
                  size: 28,
                  color:
                      isHighlight ? const Color(0xFFB71C1C) : Colors.white70),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isHighlight
                          ? const Color(0xFFB71C1C)
                          : Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final Widget child;
  final double height;
  const _DashboardCard({required this.child, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(13)),
        boxShadow: const [
          BoxShadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: child,
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color iconColor;
  const _StatusItem(this.icon, this.value, this.unit, this.iconColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: iconColor.withAlpha(204)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(width: 4),
            Text(unit,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

class _AppIcon extends StatelessWidget {
  final Widget icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _AppIcon(this.icon, this.label, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(13)),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const SizedBox(height: 12),
              Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _TopIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 20, color: color.withAlpha(230));
  }
}
