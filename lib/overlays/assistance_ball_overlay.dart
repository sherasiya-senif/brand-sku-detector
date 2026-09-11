import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'ball_style.dart';

/// Launcher component of this app. Keep in sync with `applicationId` /
/// `namespace` in android/app/build.gradle.kts if it is ever changed.
const String _kPackage = 'com.example.brand_sku_detector';
const String _kMainActivity = '$_kPackage.MainActivity';

/// The floating "assistance ball" rendered inside the system overlay window.
///
/// A small draggable circle; tapping it opens the app directly.
class AssistanceBallOverlay extends StatefulWidget {
  const AssistanceBallOverlay({super.key});

  @override
  State<AssistanceBallOverlay> createState() => _AssistanceBallOverlayState();
}

class _AssistanceBallOverlayState extends State<AssistanceBallOverlay> {
  /// Current ball look, pushed from the app isolate via shareData.
  BallStyle _style = BallStyle.defaults;
  StreamSubscription<dynamic>? _dataSub;

  @override
  void initState() {
    super.initState();
    // The app isolate sends {'color': int, 'icon': String} via shareData.
    _dataSub = FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && mounted) {
        setState(() => _style = BallStyle.fromMap(event));
      }
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    super.dispose();
  }

  /// Bring this app to the foreground.
  Future<void> _openApp() async {
    const intent = AndroidIntent(
      action: 'action_main',
      category: 'category_launcher',
      package: _kPackage,
      componentName: _kMainActivity,
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _openApp,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(_style.color),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _style.icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
