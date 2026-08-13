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

  group('fuzzy matching', () {
    final fuzzyBrands = [
      const Brand(name: 'Energizer'),
      const Brand(name: 'Coca-Cola', aliases: ['Coca Cola', 'Coke']),
      const Brand(name: 'Bru'),
    ];

    test('single-char OCR error matches and is flagged fuzzy', () {
      // "energlzer" is "energizer" with i->l (edit distance 1).
      final results = detector.detect(['energlzer 9v'], fuzzyBrands);
      final energizer =
          results.firstWhere((r) => r.brandName == 'Energizer');
      expect(energizer.count, 1);
      expect(energizer.isFuzzy, isTrue);
    });

    test('exact read is not flagged fuzzy', () {
      final results = detector.detect(['ENERGIZER'], fuzzyBrands);
      final energizer =
          results.firstWhere((r) => r.brandName == 'Energizer');
      expect(energizer.isFuzzy, isFalse);
    });

    test('multi-word brand matches with a fuzzy window', () {
      // "coca cala" is "coca cola" with o->a (edit distance 1).
      final results = detector.detect(['coca cala 500ml'], fuzzyBrands);
      final coke = results.firstWhere((r) => r.brandName == 'Coca-Cola');
      expect(coke.count, 1);
      expect(coke.isFuzzy, isTrue);
    });

    test('short names stay exact-only (no false positive)', () {
      // "brush" is edit distance 2 from "bru" but Bru is 3 chars => threshold 0.
      final results = detector.detect(['brush and comb', 'bra'], fuzzyBrands);
      expect(results.any((r) => r.brandName == 'Bru'), isFalse);
    });

    test('confident matches sort before possible ones', () {
      final results = detector.detect(['pepsi energlzer'], [
        const Brand(name: 'Pepsi'),
        const Brand(name: 'Energizer'),
      ]);
      expect(results.first.brandName, 'Pepsi'); // exact before fuzzy
      expect(results.first.isFuzzy, isFalse);
      expect(results.last.brandName, 'Energizer');
      expect(results.last.isFuzzy, isTrue);
    });
  });

  group('sku detection', () {
    final exide = Brand(
      name: 'Exide',
      skus: const [
        BrandSku(name: 'Express'),
        BrandSku(name: 'Matrix'),
      ],
    );

    test('reports a detected SKU for a detected brand', () {
      final results = detector.detect(['EXIDE EXPRESS', '12V 7AH'], [exide]);
      expect(results.single.skus, ['Express']);
    });

    test('reports multiple SKUs, only those present', () {
      final results =
          detector.detect(['EXIDE MATRIX', 'EXIDE EXPRESS'], [exide]);
      expect(results.single.skus, containsAll(['Express', 'Matrix']));
      expect(results.single.skus.length, 2);
    });

    test('no SKU listed when only the brand is present', () {
      final results = detector.detect(['EXIDE battery'], [exide]);
      expect(results.single.skus, isEmpty);
    });

    test('SKU is not reported when its brand is absent', () {
      // "Express" present but no Exide brand token → brand not detected at all.
      final results = detector.detect(['some express delivery'], [exide]);
      expect(results, isEmpty);
    });
  });
}
