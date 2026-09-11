import 'package:flutter/material.dart';

import '../overlays/ball_style.dart';
import '../services/assistance_ball_service.dart';
import '../services/assistance_bubble_service.dart';
import 'detector_screen.dart';

/// Controls the Android floating "assistance ball" overlay.
const AssistanceBallService _assistanceBall = AssistanceBallService();

/// Controls the Android conversation "assistance bubble".
const AssistanceBubbleService _assistanceBubble = AssistanceBubbleService();

/// A brand dictionary the detector can run against, backed by a JSON asset.
class BrandCatalog {
  const BrandCatalog({
    required this.label,
    required this.assetPath,
    required this.icon,
  });

  final String label;
  final String assetPath;
  final IconData icon;
}

/// Catalogs available to detect against. Add an entry here (and register the
/// asset in pubspec.yaml) to expose a new brand dictionary.
const List<BrandCatalog> kCatalogs = [
  BrandCatalog(
    label: 'General Brands',
    assetPath: 'assets/brands.json',
    icon: Icons.storefront_outlined,
  ),
  BrandCatalog(
    label: 'Battery Brands',
    assetPath: 'assets/battery_brands.json',
    icon: Icons.battery_full_outlined,
  ),
];

/// Landing screen that lists the available ways to detect brands.
/// Each feature is shown as a tappable box; more can be added over time.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openDetector(BuildContext context) async {
    final catalog = await showModalBottomSheet<BrandCatalog>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Select a brand catalog',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final catalog in kCatalogs)
              ListTile(
                leading: Icon(catalog.icon),
                title: Text(catalog.label),
                onTap: () => Navigator.of(context).pop(catalog),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (catalog == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetectorScreen(
          title: catalog.label,
          assetPath: catalog.assetPath,
        ),
      ),
    );
  }

  Future<void> _openAssistanceBallSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (!_assistanceBall.isSupported) {
      notify('The assistance ball is available on Android only');
      return;
    }

    final style = await loadBallStyle();
    final active = await _assistanceBall.isActive();
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _AssistanceBallSheet(
        initialStyle: style,
        initiallyActive: active,
        onNotify: notify,
      ),
    );
  }

  Future<void> _showAssistanceBubble(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (!await _assistanceBubble.isSupported()) {
      notify('Bubbles need Android 11 or newer');
      return;
    }
    if (!await _assistanceBubble.ensureNotificationPermission()) {
      notify('Notification permission is required for the bubble');
      return;
    }

    await _assistanceBubble.showBubble();

    if (await _assistanceBubble.areBubblesAllowed()) {
      notify('Assistance bubble posted');
    } else {
      notify('Enable bubbles for this app in Settings > Notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature(
        title: 'Shelf Photo Detector',
        subtitle: 'Capture or upload a shelf photo to detect brands',
        icon: Icons.photo_camera_outlined,
        onTap: _openDetector,
      ),
      _Feature(
        title: 'Assistance Ball',
        subtitle: 'Floating button over other apps; customize color & icon',
        icon: Icons.blur_circular_outlined,
        onTap: _openAssistanceBallSheet,
      ),
      _Feature(
        title: 'Assistance Bubble',
        subtitle: 'System chat bubble (Android 11+) that opens the detector',
        icon: Icons.chat_bubble_outline,
        onTap: _showAssistanceBubble,
      ),
      // Add more detection features here as they are built.
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brand SKU Detector'),
      ),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          children: [
            for (final feature in features) _FeatureBox(feature: feature),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function(BuildContext context) onTap;
}

class _FeatureBox extends StatelessWidget {
  const _FeatureBox({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => feature.onTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  feature.icon,
                  color: scheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to customize the assistance ball's color/icon and turn it
/// on/off. Changes apply live when the ball is currently active.
class _AssistanceBallSheet extends StatefulWidget {
  const _AssistanceBallSheet({
    required this.initialStyle,
    required this.initiallyActive,
    required this.onNotify,
  });

  final BallStyle initialStyle;
  final bool initiallyActive;
  final void Function(String message) onNotify;

  @override
  State<_AssistanceBallSheet> createState() => _AssistanceBallSheetState();
}

class _AssistanceBallSheetState extends State<_AssistanceBallSheet> {
  late BallStyle _style = widget.initialStyle;
  late bool _active = widget.initiallyActive;
  bool _busy = false;

  Future<void> _applyStyle(BallStyle style) async {
    setState(() => _style = style);
    await saveBallStyle(style);
    if (_active) {
      await _assistanceBall.sendStyle(style); // live update
    }
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (!_active) {
        if (!await _assistanceBall.ensurePermission()) {
          widget.onNotify('Overlay permission is required for the ball');
          return;
        }
      }
      final nowActive = await _assistanceBall.toggle();
      if (mounted) setState(() => _active = nowActive);
      widget.onNotify(
        nowActive ? 'Assistance ball turned on' : 'Assistance ball turned off',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Assistance ball', style: theme.textTheme.titleMedium),
                const Spacer(),
                // Live preview.
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(_style.color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_style.icon, color: Colors.white, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final c in kBallColors)
                  _SwatchDot(
                    color: Color(c),
                    selected: _style.color == c,
                    onTap: () => _applyStyle(_style.copyWith(color: c)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final entry in kBallIcons.entries)
                  _IconChoice(
                    icon: entry.value,
                    selected: _style.iconKey == entry.key,
                    onTap: () => _applyStyle(_style.copyWith(iconKey: entry.key)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _toggle,
                icon: Icon(_active ? Icons.visibility_off : Icons.visibility),
                label: Text(_active ? 'Turn off ball' : 'Turn on ball'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
