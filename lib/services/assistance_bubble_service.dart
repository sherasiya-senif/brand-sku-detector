import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Controls the Android conversation "assistance bubble" (Method 2 — Bubbles,
/// Android 11+). The bubble itself is created natively (see MainActivity.kt /
/// BubbleActivity.kt); this is a thin platform-channel wrapper.
class AssistanceBubbleService {
  const AssistanceBubbleService();

  static const MethodChannel _channel = MethodChannel('assistance_bubble');

  /// Bubbles are Android-only and require Android 11 (API 30)+.
  Future<bool> isSupported() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('isSupported') ?? false;
  }

  /// Whether bubbles are enabled for the app/device (Settings > Notifications >
  /// Bubbles). The user can turn this off, in which case the notification still
  /// posts but does not float.
  Future<bool> areBubblesAllowed() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('areBubblesAllowed') ?? false;
  }

  /// Ensures POST_NOTIFICATIONS is granted (Android 13+); returns whether it is.
  Future<bool> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('ensureNotificationPermission') ??
        false;
  }

  /// Posts the conversation notification that becomes the floating bubble.
  Future<bool> showBubble() async {
    if (!Platform.isAndroid) return false;
    return await _channel.invokeMethod<bool>('showBubble') ?? false;
  }
}
