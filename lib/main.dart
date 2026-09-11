import 'package:flutter/material.dart';

import 'overlays/assistance_ball_overlay.dart';
import 'screens/home_screen.dart';
import 'services/assistance_ball_service.dart';

void main() {
  runApp(const MyApp());
}

/// Entry point booted by flutter_overlay_window inside the separate overlay
/// engine. Must be a top-level, `vm:entry-point`-annotated function named
/// `overlayMain` — this hosts the floating assistance ball.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: AssistanceBallOverlay(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const AssistanceBallService _ball = AssistanceBallService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When the ball is enabled, it should only be visible while the app is NOT in
  /// the foreground: hide it when we come back (resumed), show it when we leave
  /// (paused).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ball.isSupported) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _ball.hide();
        break;
      case AppLifecycleState.paused:
        () async {
          if (await _ball.isEnabled()) await _ball.show();
        }();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brand SKU Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
