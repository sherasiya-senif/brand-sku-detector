/// A detected brand and how many times its name/aliases were read in the photo.
///
/// [count] is a simple occurrence count of matched text, not an exact facing
/// count — the same package can print a brand name more than once.
///
/// [isFuzzy] is true when the brand was matched **only** through fuzzy
/// (edit-distance) matching — i.e. no exact name/alias/misread was read. Such
/// hits are lower-confidence and are surfaced as "possible" so a person can
/// verify them.
class BrandResult {
  const BrandResult({
    required this.brandName,
    required this.count,
    this.isFuzzy = false,
    this.skus = const [],
  });

  final String brandName;
  final int count;
  final bool isFuzzy;

  /// Detected product line / model names for this brand (e.g. "Express" for
  /// Exide). Empty when none were recognized or the catalog has no SKUs.
  final List<String> skus;
}
