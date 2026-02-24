import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

class OmodaLauncherScreen extends StatefulWidget {
  const OmodaLauncherScreen({super.key});

  @override
  _OmodaLauncherScreenState createState() => _OmodaLauncherScreenState();
}

class _OmodaLauncherScreenState extends State<OmodaLauncherScreen> {
  String _currentScreen = "HOME"; // HOME, APPS, MUSIC

  void _navigateTo(String screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.storage.request();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white, fontFamily: 'Roboto'),
      ),
      home: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildScreen(),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case "APPS":
        return AppDrawerScreen(onBack: () => _navigateTo("HOME"));
      case "MUSIC":
        return UsbMusicScreen(onBack: () => _navigateTo("HOME"));
      default:
        return HomeScreen(
          onOpenApps: () => _navigateTo("APPS"),
          onOpenMusic: () => _navigateTo("MUSIC"),
        );
    }
  }
}

// --- ANA EKRAN TASARIMI ---
class HomeScreen extends StatelessWidget {
  final VoidCallback onOpenApps;
  final VoidCallback onOpenMusic;

  const HomeScreen({super.key, required this.onOpenApps, required this.onOpenMusic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a1a), Color(0xFF121212)])),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const TopInfoBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  const Expanded(child: MediaControlPanel()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButtonsPanel(
                      onOpenApps: onOpenApps,
                      onOpenMusic: onOpenMusic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- BİLEŞEN: HIZ GÖSTERGESİ (GPS) & SAAT ---
class TopInfoBar extends StatefulWidget {
  const TopInfoBar({super.key});

  @override
  _TopInfoBarState createState() => _TopInfoBarState();
}

class _TopInfoBarState extends State<TopInfoBar> {
  int _speed = 0;
  String _time = "00:00";
  StreamSubscription<LocationData>? _locationSubscription;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _time = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      });
    });
  }

  void _initLocation() {
    Location location = Location();
    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      if (mounted && currentLocation.speed != null) {
        setState(() {
          _speed = (currentLocation.speed! * 3.6).toInt(); // m/s -> km/h
        });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(51))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _speed.toString(),
                          style: const TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 50, fontWeight: FontWeight.bold),
                        ),
                        Text("km/h", style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: Colors.grey[400])),
                      ],
                    ),
                    Text(_time,
                        style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 40, fontWeight: FontWeight.w500)),
                  ],
                ))));
  }
}

// --- BİLEŞEN: MEDYA KONTROL ---
class MediaControlPanel extends StatelessWidget {
  const MediaControlPanel({super.key});

  static const platform = MethodChannel('com.example.omodalauncher/media');

  Future<void> _sendMediaKeyEvent(int keyCode) async {
    try {
      await platform.invokeMethod('sendMediaKeyEvent', {'keyCode': keyCode});
    } on PlatformException catch (e) {
      print("Failed to send media key event: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withAlpha(51))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.music_note, color: Colors.grey[400], size: 50),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 40,
                        onPressed: () => _sendMediaKeyEvent(88), // KEYCODE_MEDIA_PREVIOUS
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill),
                        iconSize: 60,
                        onPressed: () => _sendMediaKeyEvent(85), // KEYCODE_MEDIA_PLAY_PAUSE
                        color: Colors.cyanAccent,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 40,
                        onPressed: () => _sendMediaKeyEvent(87), // KEYCODE_MEDIA_NEXT
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            )));
  }
}

// --- BİLEŞEN: BUTONLAR ---
class ActionButtonsPanel extends StatelessWidget {
  final VoidCallback onOpenApps;
  final VoidCallback onOpenMusic;

  const ActionButtonsPanel({super.key, required this.onOpenApps, required this.onOpenMusic});

  Future<void> _launchMaps() async {
    final Uri uri = Uri.parse('geo:0,0?q=destination');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
       print('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildButton(
            context,
            icon: Icons.navigation,
            label: "Harita",
            color: const Color(0xFF1565C0),
            onPressed: _launchMaps),
        const SizedBox(height: 10),
        _buildButton(
            context,
            icon: Icons.music_video_rounded,
            label: "USB Müzik",
            color: const Color(0xFF2E7D32),
            onPressed: onOpenMusic),
        const SizedBox(height: 10),
        _buildButton(
            context,
            icon: Icons.apps,
            label: "Uygulamalar",
            color: const Color(0xFF424242),
            onPressed: onOpenApps),
      ],
    );
  }

  Widget _buildButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 28, color: Colors.white),
        label: Text(label, style: const TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 0),
          elevation: 8,
          shadowColor: color.withAlpha(128),
        ),
      ),
    );
  }
}

// --- EKRAN: UYGULAMA ÇEKMECESİ ---
class AppDrawerScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AppDrawerScreen({super.key, required this.onBack});

  @override
  _AppDrawerScreenState createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  static const platform = MethodChannel('com.example.omodalauncher/apps');
  late Future<List<dynamic>?> _appsFuture;

  @override
  void initState() {
    super.initState();
    _appsFuture = platform.invokeMethod<List<dynamic>>('getInstalledApps');
  }
  
  Future<void> _launchApp(String packageName) async {
    try {
      await platform.invokeMethod('launchApp', {'packageName': packageName});
    } on PlatformException catch (e) {
      print("Failed to launch app: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(204),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
              onPressed: widget.onBack, 
              icon: const Icon(Icons.arrow_back), 
              label: const Text("Geri Dön"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<dynamic>?>(
              future: _appsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Uygulamalar yüklenemedi: ${snapshot.error}"));
                }
                final apps = snapshot.data ?? [];
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 120, childAspectRatio: 1, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index] as Map<dynamic, dynamic>;;
                    return GestureDetector(
                      onTap: () => _launchApp(app['packageName']!),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (app['icon'] != null) 
                            Image.memory(app['icon'] as Uint8List, width: 50, height: 50),
                          const SizedBox(height: 8),
                          Text(
                            app['appName'] ?? "(No name)",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- EKRAN: USB MÜZİK LİSTESİ ---
class UsbMusicScreen extends StatefulWidget {
  final VoidCallback onBack;

  const UsbMusicScreen({super.key, required this.onBack});

  @override
  _UsbMusicScreenState createState() => _UsbMusicScreenState();
}

class _UsbMusicScreenState extends State<UsbMusicScreen> {
  late Future<List<File>> _mp3FilesFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _mp3FilesFuture = _findMp3Files();
  }

  Future<void> _play(String path, int index) async {
    await _audioPlayer.play(DeviceFileSource(path));
    setState(() {
      _currentlyPlayingIndex = index;
    });
  }

  Future<List<File>> _findMp3Files() async {
    List<File> mp3Files = [];
    List<Directory> storageDirs = [];

    // Common storage directories
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
        // This is typically /storage/emulated/0
        // To get to the root of the user-visible storage, we might go up a few levels
        Directory current = externalDir;
        while (current.parent.path != current.path) {
            current = current.parent;
            if (current.path == "/storage/emulated") break;
        }
         storageDirs.add(current);
    }
    
    // You can add other potential paths for USB OTG if you know them, e.g., /storage/xxxx-xxxx
    // This is device-dependent and can be tricky. 
    try {
      final mediaDirs = await getExternalStorageDirectories(); // Requires API 19
      if(mediaDirs != null) storageDirs.addAll(mediaDirs);
    } catch(e) {
      print("Error getting media directories: $e");
    }
   

    for (var dir in storageDirs.toSet()) { // Use a Set to avoid duplicates
      try {
        final entities = dir.list(recursive: true, followLinks: false);
        await for (var entity in entities) {
          if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
            mp3Files.add(entity);
          }
        }
      } catch (e) {
        print("Error scanning directory ${dir.path}: $e");
      }
    }

    return mp3Files;
  }
  
    @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(204),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           ElevatedButton.icon(
              onPressed: widget.onBack, 
              icon: const Icon(Icons.arrow_back), 
              label: const Text("Geri Dön"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)),
          const SizedBox(height: 16),
          const Text("Bulunan MP3 Dosyaları:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<File>>(
              future: _mp3FilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Hiç MP3 dosyası bulunamadı."));
                }
                final files = snapshot.data!;
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final isPlaying = _currentlyPlayingIndex == index;
                    return Card(
                      color: isPlaying ? Colors.green.withAlpha(100) : Colors.grey[900]?.withAlpha(128),
                      child: ListTile(
                        leading: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline, color: Colors.lightGreenAccent),
                        title: Text(files[index].path.split('/').last, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(files[index].parent.path, style: const TextStyle(color: Colors.grey)),
                         onTap: () {
                           if(isPlaying) {
                             _audioPlayer.pause();
                             setState(() {
                              _currentlyPlayingIndex = null;
                             });
                           } else {
                            _play(files[index].path, index);
                           }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
