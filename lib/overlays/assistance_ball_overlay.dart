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

/// Resting ball window size (dp) and expanded menu-panel size (dp).
///
/// The overlay isolate can only *resize* its window (resizeOverlay), not move
/// it — moveOverlay/updateOverlayPosition are handled on channels that aren't
/// available here. So the menu is a fixed-size panel that grows in place from
/// the ball's anchor (centerRight) rather than a full-screen dialog.
const int _kBallDp = 56;
const int _kPanelWidthDp = 300;
const int _kPanelHeightDp = 232;

/// The floating "assistance ball" rendered inside the system overlay window.
///
/// Collapsed, it is a small draggable circle. Tapping it grows the overlay into
/// a quick-actions menu panel shown *over other apps*; the close button (or an
/// action) collapses it back to the ball.
class AssistanceBallOverlay extends StatefulWidget {
  const AssistanceBallOverlay({super.key});

  @override
  State<AssistanceBallOverlay> createState() => _AssistanceBallOverlayState();
}

class _AssistanceBallOverlayState extends State<AssistanceBallOverlay>
    with WidgetsBindingObserver {
  bool _expanded = false;

  /// Current ball look, pushed from the app isolate via shareData.
  BallStyle _style = BallStyle.defaults;
  StreamSubscription<dynamic>? _dataSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The overlay engine persists across hide/show. When the overlay window is
    // re-attached (re-shown), snap back to the collapsed ball so we never resume
    // in a stale expanded state.
    if (state == AppLifecycleState.resumed && _expanded && mounted) {
      setState(() => _expanded = false);
    }
  }

  Future<void> _expand() async {
    // Grow to the fixed menu-panel size. Drag is disabled while expanded.
    // resizeOverlay takes dp (native applies dpToPx).
    await FlutterOverlayWindow.resizeOverlay(
      _kPanelWidthDp,
      _kPanelHeightDp,
      false,
    );
    if (mounted) setState(() => _expanded = true);
  }

  Future<void> _collapse() async {
    await FlutterOverlayWindow.resizeOverlay(_kBallDp, _kBallDp, true);
    if (mounted) setState(() => _expanded = false);
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

  /// Remove the floating ball entirely.
  ///
  /// The overlay engine (and this widget) persists across hide/show — the plugin
  /// only stops the service, it never recreates the engine — so we must reset to
  /// the collapsed ball state before closing. Otherwise a later re-show reuses
  /// the stale expanded state and paints the menu card clipped into the small
  /// ball window (the "A…ssistance" corner) with no way to interact.
  Future<void> _hideBall() async {
    await _collapse();
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return _expanded ? _buildPanel() : _buildBall();
  }

  Widget _buildBall() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _expand,
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

  Widget _buildPanel() {
    return Material(
      color: Colors.white,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Assistance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _collapse,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Open SKU Detector'),
            onTap: () async {
              await _openApp();
              await _collapse();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Hide ball'),
            onTap: _hideBall,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
