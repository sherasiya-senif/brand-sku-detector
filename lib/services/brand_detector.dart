import '../models/brand.dart';
import '../models/brand_result.dart';

/// Matches OCR text against the predefined brand list and counts occurrences.
///
/// Matching is deliberately simple (per the product decision): normalize text
/// to lowercase whole words and count how many times each brand's name/aliases
/// appear across the recognized lines. No fuzzy matching.
class BrandDetector {
  const BrandDetector();

  /// Counts brand occurrences across [lines] (one string per recognized line).
  ///
  /// Returns only brands with at least one match, sorted by count descending
  /// then by name for stable ordering.
  List<BrandResult> detect(List<String> lines, List<Brand> brands) {
    // Normalize each line to " word word " form so terms can be matched as
    // whole words using simple substring search (no lookbehind needed).
    final haystacks = lines.map(_normalizePadded).toList();

    final results = <BrandResult>[];
    for (final brand in brands) {
      // Dedupe normalized terms so a name and an equivalent alias
      // (e.g. "Coca-Cola" and "Coca Cola") aren't counted twice.
      final terms = <String>{
        for (final term in brand.matchTerms) _normalizePadded(term),
      }..removeWhere((t) => t.trim().isEmpty);

      var count = 0;
      for (final haystack in haystacks) {
        for (final term in terms) {
          count += _countOccurrences(haystack, term);
        }
      }

      if (count > 0) {
        results.add(BrandResult(brandName: brand.name, count: count));
      }
    }

    results.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.brandName.compareTo(b.brandName);
    });
    return results;
  }

  /// Lowercases, replaces any non-alphanumeric run with a single space, and
  /// pads with a leading/trailing space so whole-word matches are exact.
  String _normalizePadded(String input) {
    final collapsed = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
    return ' $collapsed ';
  }

  /// Non-overlapping count of [term] (already padded, e.g. " coke ") inside
  /// [haystack] (already padded). Overlaps by one space are intentional so
  /// adjacent matches like " coke coke " both count.
  int _countOccurrences(String haystack, String term) {
    if (term.trim().isEmpty) return 0;
    var count = 0;
    var start = 0;
    while (true) {
      final index = haystack.indexOf(term, start);
      if (index < 0) break;
      count++;
      // Step forward but keep the trailing space available as the next term's
      // leading space, so back-to-back occurrences are all counted.
      start = index + term.length - 1;
    }
    return count;
  }
}
