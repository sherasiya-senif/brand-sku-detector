/// A tracked brand loaded from `assets/brands.json`.
///
/// [name] is the canonical brand name shown in results. [aliases] holds
/// legitimate alternate spellings/short forms that should also count as this
/// brand when found in the OCR text (e.g. "Coke" for "Coca-Cola").
///
/// [misreads] holds known OCR mis-recognitions — text ML Kit is likely to
/// output in place of this brand even though it is not a real name for it
/// (e.g. "3SPL"/"35PL" for "BSPL"). Kept separate from [aliases] so the two
/// concerns stay distinct, but both are matched against the recognized text.
///
/// [skus] are the brand's product lines / sub-brand names printed on the item
/// (e.g. Exide "Express", Amaron "Flo"). Each is matched like a mini-brand and,
/// when the parent brand is detected, reported as that brand's SKU.
class Brand {
  const Brand({
    required this.name,
    this.aliases = const [],
    this.misreads = const [],
    this.skus = const [],
  });

  final String name;
  final List<String> aliases;
  final List<String> misreads;
  final List<BrandSku> skus;

  /// All strings that should match this brand: the canonical name plus
  /// legitimate aliases and known OCR misreads.
  List<String> get matchTerms => [name, ...aliases, ...misreads];

  factory Brand.fromJson(Map<String, dynamic> json) {
    final rawSkus = json['skus'];
    return Brand(
      name: (json['name'] as String).trim(),
      aliases: _parseList(json['aliases']),
      misreads: _parseList(json['misreads']),
      skus: rawSkus is List
          ? rawSkus
              .whereType<Map<String, dynamic>>()
              .map(BrandSku.fromJson)
              .where((s) => s.name.isNotEmpty)
              .toList()
          : const [],
    );
  }
}

/// A single product line / model of a [Brand] (its "SKU"), matched the same
/// fuzzy way as a brand via its name, aliases, and known OCR misreads.
class BrandSku {
  const BrandSku({
    required this.name,
    this.aliases = const [],
    this.misreads = const [],
  });

  final String name;
  final List<String> aliases;
  final List<String> misreads;

  /// All strings that should match this SKU.
  List<String> get matchTerms => [name, ...aliases, ...misreads];

  factory BrandSku.fromJson(Map<String, dynamic> json) => BrandSku(
        name: (json['name'] as String? ?? '').trim(),
        aliases: _parseList(json['aliases']),
        misreads: _parseList(json['misreads']),
      );
}

/// Parses a JSON value into a trimmed, non-empty list of strings.
List<String> _parseList(dynamic raw) => raw is List
    ? raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
    : const [];
