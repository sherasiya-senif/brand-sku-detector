import 'dart:math' as math;

import '../models/brand.dart';
import '../models/brand_result.dart';

/// Matches OCR text against the predefined brand list and counts occurrences.
///
/// Matching is whole-word but **fault-tolerant**: each brand term is compared to
/// windows of recognized words by edit distance, so small OCR errors (e.g.
/// "energlzer" for "Energizer") still match. The allowed number of errors scales
/// with term length and is zero for short terms, so short names like "Bru" or
/// "NPP" only match exactly and don't cause false positives.
class BrandDetector {
  const BrandDetector();

  /// Counts brand occurrences across [lines] (one string per recognized line).
  ///
  /// Returns only brands with at least one match. A brand matched only via fuzzy
  /// (edit-distance) matching is flagged [BrandResult.isFuzzy]. Results are
  /// sorted confident-first, then by count descending, then by name.
  List<BrandResult> detect(List<String> lines, List<Brand> brands) {
    // Tokenize each line into normalized words once.
    final tokenizedLines =
        lines.map(_tokenize).where((t) => t.isNotEmpty).toList();

    final results = <BrandResult>[];
    for (final brand in brands) {
      final terms = _orderedTerms(brand.matchTerms);
      if (terms.isEmpty) continue;

      final match = _matchTerms(tokenizedLines, terms);
      final total = match.exact + match.fuzzy;
      if (total == 0) continue;

      // Brand is present — now look for which of its SKUs (product lines) also
      // appear. SKU words are generic, so we only attribute them to a brand we
      // already detected.
      final detectedSkus = <String>[];
      for (final sku in brand.skus) {
        final skuTerms = _orderedTerms(sku.matchTerms);
        if (skuTerms.isEmpty) continue;
        final skuMatch = _matchTerms(tokenizedLines, skuTerms);
        if (skuMatch.exact + skuMatch.fuzzy > 0 &&
            !detectedSkus.contains(sku.name)) {
          detectedSkus.add(sku.name);
        }
      }

      results.add(BrandResult(
        brandName: brand.name,
        count: total,
        isFuzzy: match.exact == 0,
        skus: detectedSkus,
      ));
    }

    results.sort((a, b) {
      // Confident (exact) matches first.
      if (a.isFuzzy != b.isFuzzy) return a.isFuzzy ? 1 : -1;
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.brandName.compareTo(b.brandName);
    });
    return results;
  }

  /// Normalizes + dedupes [rawTerms] and orders them longest-first so more
  /// specific (multi-word) terms are tried before short ones at each position.
  List<String> _orderedTerms(List<String> rawTerms) {
    final terms = <String>{
      for (final term in rawTerms) _normalize(term),
    }..removeWhere((t) => t.isEmpty);
    return terms.toList()..sort((a, b) => b.length.compareTo(a.length));
  }

  /// Counts exact and fuzzy matches of [orderedTerms] across [tokenizedLines].
  ({int exact, int fuzzy}) _matchTerms(
    List<List<String>> tokenizedLines,
    List<String> orderedTerms,
  ) {
    var exact = 0;
    var fuzzy = 0;
    for (final tokens in tokenizedLines) {
      for (var start = 0; start < tokens.length; start++) {
        // Count at most once per starting position: the first term that
        // matches wins, so a term set's own terms don't stack on one word.
        for (final term in orderedTerms) {
          final distance = _matchDistanceAt(tokens, start, term);
          if (distance == null) continue;
          if (distance == 0) {
            exact++;
          } else {
            fuzzy++;
          }
          break;
        }
      }
    }
    return (exact: exact, fuzzy: fuzzy);
  }

  /// Returns the edit distance if [term] matches the window of [tokens] starting
  /// at [start] within the length-scaled tolerance, or null if it doesn't match.
  ///
  /// [term] is a normalized string that may contain spaces (multi-word brands);
  /// its word count determines the window size compared against the tokens.
  int? _matchDistanceAt(List<String> tokens, int start, String term) {
    final termWords = term.split(' ');
    final end = start + termWords.length;
    if (end > tokens.length) return null;

    final window = tokens.sublist(start, end).join(' ');
    final allowed = _allowedDistance(term);
    if (allowed == 0) {
      return window == term ? 0 : null;
    }
    final distance = _levenshtein(window, term);
    return distance <= allowed ? distance : null;
  }

  /// Number of OCR character errors tolerated for [term], scaled by its length
  /// (alphanumeric chars, spaces excluded). Short terms allow none to avoid
  /// false positives; longer terms absorb more error safely.
  int _allowedDistance(String term) {
    final len = term.replaceAll(' ', '').length;
    if (len <= 4) return 0;
    if (len <= 7) return 1;
    if (len <= 11) return 2;
    return 3;
  }

  /// Splits [input] into normalized words (lowercase, alphanumeric runs only).
  List<String> _tokenize(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }

  /// Lowercases and reduces any run of non-alphanumeric characters to a single
  /// space, trimmed. Used for both brand terms and recognized lines.
  String _normalize(String input) => input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  /// Classic Levenshtein edit distance between [a] and [b] (insertions,
  /// deletions, substitutions), using a single rolling row.
  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
        current[j + 1] = math.min(
          math.min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }
    return previous[b.length];
  }
}
