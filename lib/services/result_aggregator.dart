import '../models/brand_result.dart';

/// Merges brand results from several photos of the same shelf into one deduped
/// list — used when a wide shelf is captured across multiple overlapping shots.
///
/// Each brand's count is the **sum** of its per-photo counts across all photos.
/// A brand read confidently in *any* photo is treated as confident; it stays
/// "fuzzy" only if every photo that found it did so fuzzily.
class ResultAggregator {
  final Map<String, BrandResult> _byName = {};

  /// Whether no photos have contributed results yet.
  bool get isEmpty => _byName.isEmpty;

  /// Folds one photo's [photoResults] into the running total.
  void add(List<BrandResult> photoResults) {
    for (final r in photoResults) {
      final existing = _byName[r.brandName];
      if (existing == null) {
        _byName[r.brandName] = r;
      } else {
        _byName[r.brandName] = BrandResult(
          brandName: r.brandName,
          count: existing.count + r.count,
          isFuzzy: existing.isFuzzy && r.isFuzzy,
        );
      }
    }
  }

  /// The merged brands, sorted confident-first, then count desc, then name —
  /// the same ordering [BrandDetector] uses for a single photo.
  List<BrandResult> results() {
    final list = _byName.values.toList();
    list.sort((a, b) {
      if (a.isFuzzy != b.isFuzzy) return a.isFuzzy ? 1 : -1;
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.brandName.compareTo(b.brandName);
    });
    return list;
  }

  /// Forgets all accumulated results (starting a new shelf scan).
  void clear() => _byName.clear();
}
