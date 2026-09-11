import 'package:flutter/material.dart';

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

  Future<void> _toggleAssistanceBall(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    void notify(String message) =>
        messenger.showSnackBar(SnackBar(content: Text(message)));

    if (!_assistanceBall.isSupported) {
      notify('The assistance ball is available on Android only');
      return;
    }

    if (!await _assistanceBall.ensurePermission()) {
      notify('Overlay permission is required to show the assistance ball');
      return;
    }

    final active = await _assistanceBall.toggle();
    notify(active ? 'Assistance ball turned on' : 'Assistance ball turned off');
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
        subtitle: 'Floating button over other apps; tap to open the detector',
        icon: Icons.blur_circular_outlined,
        onTap: _toggleAssistanceBall,
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
