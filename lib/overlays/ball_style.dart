import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preset colors the user can choose for the assistance ball (ARGB ints).
const List<int> kBallColors = <int>[
  0xFF673AB7, // deep purple (default)
  0xFF2196F3, // blue
  0xFF4CAF50, // green
  0xFFF44336, // red
];

/// Preset icons, keyed by a stable string sent across the isolate boundary.
/// Uses const `Icons.*` so icon tree-shaking still works in release.
const Map<String, IconData> kBallIcons = <String, IconData>{
  'storefront': Icons.storefront_outlined,
  'bolt': Icons.bolt,
  'search': Icons.search,
  'cart': Icons.shopping_cart_outlined,
};

const int _kDefaultColor = 0xFF673AB7;
const String _kDefaultIconKey = 'storefront';

const String _kPrefColor = 'ball_color';
const String _kPrefIcon = 'ball_icon';

/// The look of the assistance ball. Shared between the app isolate (picker +
/// persistence) and the overlay isolate (rendering).
class BallStyle {
  const BallStyle({required this.color, required this.iconKey});

  final int color;
  final String iconKey;

  static const BallStyle defaults = BallStyle(
    color: _kDefaultColor,
    iconKey: _kDefaultIconKey,
  );

  /// The icon for [iconKey], falling back to the default if unknown.
  IconData get icon => kBallIcons[iconKey] ?? kBallIcons[_kDefaultIconKey]!;

  BallStyle copyWith({int? color, String? iconKey}) => BallStyle(
        color: color ?? this.color,
        iconKey: iconKey ?? this.iconKey,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'color': color,
        'icon': iconKey,
      };

  factory BallStyle.fromMap(Map<dynamic, dynamic> map) => BallStyle(
        color: (map['color'] as num?)?.toInt() ?? _kDefaultColor,
        iconKey: map['icon'] as String? ?? _kDefaultIconKey,
      );
}

/// Loads the saved ball style (defaults if none saved).
Future<BallStyle> loadBallStyle() async {
  final prefs = await SharedPreferences.getInstance();
  return BallStyle(
    color: prefs.getInt(_kPrefColor) ?? _kDefaultColor,
    iconKey: prefs.getString(_kPrefIcon) ?? _kDefaultIconKey,
  );
}

/// Persists the chosen ball style.
Future<void> saveBallStyle(BallStyle style) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kPrefColor, style.color);
  await prefs.setString(_kPrefIcon, style.iconKey);
}
