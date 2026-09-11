import 'dart:io' show Platform;

import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../overlays/ball_style.dart';

/// Controls the Android "assistance ball" floating overlay (Method 1 —
/// SYSTEM_ALERT_WINDOW). Thin wrapper over flutter_overlay_window so the UI
/// layer never touches the plugin directly.
class AssistanceBallService {
  const AssistanceBallService();

  /// Overlay windows are Android-only.
  bool get isSupported => Platform.isAndroid;

  /// Whether the floating ball is currently shown.
  Future<bool> isActive() async {
    if (!isSupported) return false;
    return await FlutterOverlayWindow.isActive();
  }

  /// Ensures the "draw over other apps" permission is granted, prompting the
  /// user via the system settings screen when it is not. Returns whether the
  /// permission ended up granted.
  Future<bool> ensurePermission() async {
    if (!isSupported) return false;
    if (await FlutterOverlayWindow.isPermissionGranted()) return true;
    // Opens Settings.ACTION_MANAGE_OVERLAY_PERMISSION; resolves once the user
    // returns. Re-check because the plugin's return value can be null on some
    // OEM builds.
    await FlutterOverlayWindow.requestPermission();
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  /// Shows the floating ball. Assumes permission has already been granted.
  Future<void> show() async {
    if (!isSupported) return;
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'Assistance Ball',
      overlayContent: 'Tap to open the detector',
      flag: OverlayFlag.defaultFlag,
      // centerRight keeps the resting ball on screen; the menu panel grows in
      // place from here (we can't reposition the window from the overlay
      // isolate, only resize it — see AssistanceBallOverlay).
      alignment: OverlayAlignment.centerRight,
      positionGravity: PositionGravity.auto,
      height: 130,
      width: 130,
    );
    // Push the saved color/icon to the overlay isolate. Send immediately and
    // again shortly after, to beat the overlay engine's boot race.
    final style = await loadBallStyle();
    await sendStyle(style);
    Future<void>.delayed(
      const Duration(milliseconds: 300),
      () => sendStyle(style),
    );
  }

  /// Sends the given style to the running overlay (live update).
  Future<void> sendStyle(BallStyle style) async {
    if (!isSupported) return;
    await FlutterOverlayWindow.shareData(style.toMap());
  }

  /// Removes the floating ball.
  Future<void> hide() async {
    if (!isSupported) return;
    await FlutterOverlayWindow.closeOverlay();
  }

  /// Shows the ball if hidden, hides it if shown. Returns the new active state.
  Future<bool> toggle() async {
    if (await isActive()) {
      await hide();
      return false;
    }
    await show();
    return true;
  }
}
