import 'package:flutter/material.dart';

import 'overlays/assistance_ball_overlay.dart';
import 'screens/home_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
