import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

// --- ANA UYGULAMA YAPISI (SCAFFOLD & NAVİGASYON) ---
class OmodaLauncherScreen extends StatefulWidget {
  const OmodaLauncherScreen({super.key});

  @override
  _OmodaLauncherScreenState createState() => _OmodaLauncherScreenState();
}

class _OmodaLauncherScreenState extends State<OmodaLauncherScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _pages = [
      const DashboardScreen(),
      const UsbMusicScreen(),
      const AppDrawerScreen(),
    ];
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.storage.request();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: ThemeData.dark()
            .textTheme
            .apply(bodyColor: Colors.white, displayColor: Colors.white, fontFamily: 'Roboto'),
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Ana Ekran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.music_note),
              label: 'Müzik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.apps),
              label: 'Uygulamalar',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF1a1a1a),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey[600],
          iconSize: 28,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

// --- 1. EKRAN: DASHBOARD (ANA EKRAN) ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a1a), Color(0xFF121212)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), // No bottom padding for navbar
        child: Column(
          children: [
            const TopInfoBar(),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(
                    flex: 6, // 60% of the space
                    child: MapPlaceholder(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 4, // 40% of the space
                    child: MediaControlPanel(),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD BİLEŞENİ: HARİTA YER TUTUCU ---
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key});

  Future<void> _launchMaps() async {
    final Uri uri = Uri.parse('geo:0,0?q=');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _launchMaps,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withAlpha(51)),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.navigation, size: 60, color: Colors.blue[300]),
          const SizedBox(height: 12),
          Text(
            "Haritayı Aç",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
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
      if (mounted) {
        setState(() {
          _time =
              "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
        });
      }
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), 
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withAlpha(51))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _speed.toString(),
                          style: const TextStyle(
                              fontFamily: 'Oswald',
                              fontSize: 40,
                              fontWeight: FontWeight.bold),
                        ),
                        Text("km/h", style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: Colors.grey[400])),
                      ],
                    ),
                    Text(_time,
                        style: const TextStyle(
                            fontFamily: 'Oswald',
                            fontSize: 32,
                            fontWeight: FontWeight.w500)),
                  ],
                )
            )
        )
    );
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
                   Icon(Icons.music_note_outlined, color: Colors.grey[400], size: 50),
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
            )
        )
    );
  }
}

// --- 2. EKRAN: TAM EKRAN MÜZİK ÇALAR ---
class UsbMusicScreen extends StatefulWidget {
  const UsbMusicScreen({super.key});

  @override
  _UsbMusicScreenState createState() => _UsbMusicScreenState();
}

class _UsbMusicScreenState extends State<UsbMusicScreen> {
  late Future<List<File>> _mp3FilesFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentlyPlayingIndex;
  String _status = "Durduruldu";

  @override
  void initState() {
    super.initState();
    _mp3FilesFuture = _findMp3Files();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if(mounted) {
        setState(() {
          if (state == PlayerState.completed) {
            _currentlyPlayingIndex = null;
            _status = "Bitti";
          } else if (state == PlayerState.playing) {
             _status = "Çalıyor...";
          } else {
            _status = "Durduruldu";
          }
        });
      }
    });
  }

  Future<void> _play(String path, int index) async {
    await _audioPlayer.play(DeviceFileSource(path));
    setState(() {
      _currentlyPlayingIndex = index;
    });
  }
  
   Future<void> _togglePlayPause(String path, int index) async {
    if (_currentlyPlayingIndex == index && _audioPlayer.state == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _play(path, index);
    }
  }


  Future<List<File>> _findMp3Files() async {
    List<File> mp3Files = [];
    try {
      final mediaDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
      if (mediaDirs != null) {
        for (var dir in mediaDirs) {
          final entities = dir.list(recursive: true, followLinks: false);
          await for (var entity in entities) {
            if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
              mp3Files.add(entity);
            }
          }
        }
      }
    } catch (e) {
      print("Error scanning directories: $e");
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
      color: Colors.black.withAlpha(230),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("USB Müzik Çalar", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: FutureBuilder<List<File>>(
              future: _mp3FilesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Bu cihazda hiç MP3 dosyası bulunamadı.", style: TextStyle(fontSize: 16)),
                  );
                }
                final files = snapshot.data!;
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final isPlaying = _currentlyPlayingIndex == index && _audioPlayer.state == PlayerState.playing;
                    return Card(
                      color: isPlaying
                          ? Colors.green.withOpacity(0.3)
                          : Colors.grey[900]?.withOpacity(0.4),
                      child: ListTile(
                        leading: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                          color: Colors.lightGreenAccent,
                          size: 32,
                        ),
                        title: Text(
                          files[index].path.split('/').last,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          files[index].parent.path,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _togglePlayPause(files[index].path, index),
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

// --- 3. EKRAN: TAM EKRAN UYGULAMA LİSTESİ ---
class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

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
      color: Colors.black.withAlpha(230),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Uygulamalar", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
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
                if (apps.isEmpty) {
                  return const Center(child: Text("Hiç uygulama bulunamadı."));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150, // Larger touch targets
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index] as Map<dynamic, dynamic>;
                    final String appName = app['appName'] ?? "(No name)";
                    final String packageName = app['packageName']!;
                    return InkWell(
                      onTap: () => _launchApp(packageName),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                           color: Colors.grey[900]?.withOpacity(0.4),
                           borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (app['icon'] != null)
                              Image.memory(app['icon'] as Uint8List, width: 60, height: 60),
                            const SizedBox(height: 12),
                            Text(
                              appName,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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
