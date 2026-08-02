import 'package:flutter_test/flutter_test.dart';

import 'package:brand_sku_detector/models/brand.dart';
import 'package:brand_sku_detector/services/brand_detector.dart';

void main() {
  const detector = BrandDetector();
  final brands = [
    const Brand(name: 'Coca-Cola', aliases: ['Coca Cola', 'Coke']),
    const Brand(name: 'Pepsi'),
    const Brand(name: 'Bru'),
  ];

  test('matches canonical name and aliases, whole-word only', () {
    final lines = [
      'COCA-COLA 500ml',
      'ice cold coke',
      'PEPSI',
      'brush and comb', // must NOT match "Bru"
    ];
    final results = detector.detect(lines, brands);
    final byName = {for (final r in results) r.brandName: r.count};

    expect(byName['Coca-Cola'], 2); // "COCA-COLA" + "coke"
    expect(byName['Pepsi'], 1);
    expect(byName.containsKey('Bru'), isFalse); // "brush" is not a match
  });

  test('name and equivalent alias are not double counted', () {
    // "Coca Cola" alias normalizes the same as the "Coca-Cola" name.
    final results = detector.detect(['Coca Cola'], brands);
    expect(results.single.brandName, 'Coca-Cola');
    expect(results.single.count, 1);
  });

  test('returns empty when nothing matches', () {
    expect(detector.detect(['random shelf text'], brands), isEmpty);
  });

  test('results are sorted by count descending', () {
    final results = detector.detect(['coke coke pepsi'], brands);
    expect(results.first.brandName, 'Coca-Cola');
    expect(results.first.count, 2);
  });
}
