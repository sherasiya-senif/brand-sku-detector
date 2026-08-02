import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/brand.dart';

/// Loads the predefined brand dictionary from the bundled JSON asset.
///
/// The asset ([assetPath]) is data-driven: editing `assets/brands.json` changes
/// the tracked brands with no code changes.
class BrandRepository {
  BrandRepository({this.assetPath = 'assets/brands.json'});

  final String assetPath;

  List<Brand>? _cache;

  /// Returns the brand list, parsing the asset on first call and caching it.
  Future<List<Brand>> loadBrands() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('brands.json must be a JSON array of brands');
    }

    _cache = decoded
        .whereType<Map<String, dynamic>>()
        .map(Brand.fromJson)
        .where((b) => b.name.isNotEmpty)
        .toList();
    return _cache!;
  }
}
