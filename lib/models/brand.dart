/// A tracked brand loaded from `assets/brands.json`.
///
/// [name] is the canonical brand name shown in results. [aliases] holds
/// alternate spellings/short forms that should also count as this brand when
/// found in the OCR text (e.g. "Coke" for "Coca-Cola").
class Brand {
  const Brand({required this.name, this.aliases = const []});

  final String name;
  final List<String> aliases;

  /// All strings that should match this brand: the canonical name plus aliases.
  List<String> get matchTerms => [name, ...aliases];

  factory Brand.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    return Brand(
      name: (json['name'] as String).trim(),
      aliases: rawAliases is List
          ? rawAliases.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }
}
