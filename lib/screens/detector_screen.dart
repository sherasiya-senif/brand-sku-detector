import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/brand_result.dart';
import '../services/brand_detector.dart';
import '../services/brand_repository.dart';
import '../services/ocr_service.dart';

/// Lets a salesperson upload or capture a photo of an outlet's shelf and
/// detects which tracked brands appear on it, fully on-device.
class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocr = OcrService();
  final BrandRepository _brands = BrandRepository();
  final BrandDetector _detector = const BrandDetector();

  File? _image;
  bool _busy = false;
  bool _hasRun = false;
  List<BrandResult> _results = const [];

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 90,
      );
      if (picked == null) return; // user cancelled

      setState(() {
        _image = File(picked.path);
        _busy = true;
        _hasRun = false;
        _results = const [];
      });

      final lines = await _ocr.recognizeLines(picked.path);
      final brands = await _brands.loadBrands();
      final results = _detector.detect(lines, brands);

      if (!mounted) return;
      setState(() {
        _results = results;
        _hasRun = true;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showError('Could not process the image: $e');
    }
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
        title: const Text('Brand & SKU Detector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildImagePreview(),
              const SizedBox(height: 16),
              _buildResults(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Upload Photo'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Capture Photo'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Text('Upload or capture a shelf photo to begin'),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(_image!, height: 240, fit: BoxFit.cover),
    );
  }

  Widget _buildResults() {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Detecting brands…'),
          ],
        ),
      );
    }

    if (!_hasRun) return const SizedBox.shrink();

    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No tracked brands detected in this photo.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detected brands (${_results.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._results.map(
          (r) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(r.brandName),
              trailing: Chip(label: Text('${r.count}×')),
            ),
          ),
        ),
      ],
    );
  }
}
