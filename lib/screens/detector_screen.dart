import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_result.dart';
import '../services/brand_detector.dart';
import '../services/brand_repository.dart';
import '../services/ocr_service.dart';
import '../services/result_aggregator.dart';
import 'camera_capture_screen.dart';

/// Lets a salesperson capture one or more photos of an outlet's shelf and
/// detects which tracked brands appear across them, fully on-device.
///
/// A wide shelf won't fit in one usable photo, so photos accumulate into a
/// session: each is detected on its own and merged into a single deduped brand
/// list, with each brand's count summed across all photos.
class DetectorScreen extends StatefulWidget {
  const DetectorScreen({
    super.key,
    this.title = 'Brand & SKU Detector',
    this.assetPath = 'assets/brands.json',
  });

  /// Shown in the app bar.
  final String title;

  /// Path to the brand-dictionary JSON asset to detect against.
  final String assetPath;

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocr = OcrService();
  late final BrandRepository _brands =
      BrandRepository(assetPath: widget.assetPath);
  final BrandDetector _detector = const BrandDetector();
  final ResultAggregator _aggregator = ResultAggregator();

  final List<File> _images = [];
  final List<String> _rawByPhoto = []; // one photo's joined OCR text per entry
  bool _busy = false;
  bool _hasRun = false;
  List<BrandResult> _results = const [];

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  /// Picks one or more photos from the gallery and adds them to the session.
  Future<void> _pickFromGallery() async {
    if (_busy) return;
    try {
      // No downscale (maxWidth) and near-lossless quality: keep as much detail
      // as possible so small shelf text stays legible for OCR.
      final picked = await _picker.pickMultiImage(imageQuality: 100);
      if (picked.isEmpty) return; // user cancelled
      await _processPicked(picked);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Could not pick images: $e');
    }
  }

  /// Captures a photo with the in-app camera (max sensor resolution) and adds
  /// it to the session.
  Future<void> _captureFromCamera() async {
    if (_busy) return;
    final picked = await Navigator.of(context).push<XFile>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (picked == null || !mounted) return; // user backed out
    await _processPicked([picked]);
  }

  /// Runs OCR + detection on each picked file and folds the results into the
  /// running session, updating the UI after every photo.
  Future<void> _processPicked(List<XFile> picked) async {
    setState(() => _busy = true);
    try {
      final brands = await _brands.loadBrands();
      for (final x in picked) {
        final lines = await _ocr.recognizeLines(x.path);
        _aggregator.add(_detector.detect(lines, brands));
        if (!mounted) return;
        setState(() {
          _images.add(File(x.path));
          _rawByPhoto.add(lines.join('\n'));
          _results = _aggregator.results();
          _hasRun = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Could not process an image: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Clears the session to start scanning a new shelf.
  void _reset() {
    if (_busy) return;
    setState(() {
      _images.clear();
      _rawByPhoto.clear();
      _aggregator.clear();
      _results = const [];
      _hasRun = false;
    });
  }

  void _showRawText() {
    final text = _rawByPhoto.isEmpty
        ? 'No text was recognized.'
        : [
            for (var i = 0; i < _rawByPhoto.length; i++)
              '— Photo ${i + 1} —\n${_rawByPhoto[i]}',
          ].join('\n\n');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw recognized text'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionButtons(),
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              _buildImagePreview(),
              if (_hasRun) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showRawText,
                        icon: const Icon(Icons.text_snippet_outlined),
                        label: const Text('View raw text'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Start over'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final adding = _images.isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(adding ? 'Add Photos' : 'Upload Photos'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : _captureFromCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(adding ? 'Add Capture' : 'Capture Photo'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Text(
          'Upload or capture a shelf photo to begin.\n'
          'For a wide shelf, take several overlapping photos.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_images.length} photo${_images.length == 1 ? '' : 's'} in this scan',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _images[i],
                width: 130,
                height: 130,
                fit: BoxFit.cover,
                // Decode the thumbnail small; OCR still reads the full-res file.
                cacheWidth: 260,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (!_hasRun) {
      return _busy
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Detecting brands…')),
            )
          : const SizedBox.shrink();
    }

    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No tracked brands detected in these photos.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detected brands (${_results.length}) · '
          '${_images.length} photo${_images.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._results.map(_buildResultCard),
      ],
    );
  }

  Widget _buildResultCard(BrandResult r) {
    // Confident matches stay clean (just the check + count). Fuzzy-only matches
    // get an amber "Likely" chip so they can be quickly verified.
    final likelyColor = Colors.amber.shade800;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          r.isFuzzy ? Icons.error_outline : Icons.check_circle_outline,
          color: r.isFuzzy ? likelyColor : null,
        ),
        title: Text(r.brandName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.isFuzzy) ...[
              _statusChip('Likely', likelyColor),
              const SizedBox(width: 8),
            ],
            Chip(label: Text('${r.count}×')),
          ],
        ),
      ),
    );
  }

  /// Compact tonal status chip (e.g. "Likely") in [color].
  Widget _statusChip(String label, Color color) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
