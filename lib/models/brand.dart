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
class Brand {
  const Brand({
    required this.name,
    this.aliases = const [],
    this.misreads = const [],
  });

  final String name;
  final List<String> aliases;
  final List<String> misreads;

  /// All strings that should match this brand: the canonical name plus
  /// legitimate aliases and known OCR misreads.
  List<String> get matchTerms => [name, ...aliases, ...misreads];

  factory Brand.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) => raw is List
        ? raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : const [];

    return Brand(
      name: (json['name'] as String).trim(),
      aliases: parseList(json['aliases']),
      misreads: parseList(json['misreads']),
    );
  }
}
