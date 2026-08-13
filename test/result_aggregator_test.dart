import 'package:flutter_test/flutter_test.dart';

import 'package:brand_sku_detector/models/brand_result.dart';
import 'package:brand_sku_detector/services/result_aggregator.dart';

void main() {
  test('sums counts across photos', () {
    final agg = ResultAggregator()
      ..add([const BrandResult(brandName: 'Pepsi', count: 2)])
      ..add([const BrandResult(brandName: 'Pepsi', count: 3)])
      ..add([const BrandResult(brandName: 'Pepsi', count: 1)]);

    final pepsi = agg.results().single;
    expect(pepsi.count, 6); // 2 + 3 + 1
  });

  test('a brand confident in any photo is not marked fuzzy', () {
    final agg = ResultAggregator()
      ..add([const BrandResult(brandName: 'Exide', count: 1, isFuzzy: true)])
      ..add([const BrandResult(brandName: 'Exide', count: 1, isFuzzy: false)]);

    expect(agg.results().single.isFuzzy, isFalse);
  });

  test('stays fuzzy only when every photo was fuzzy', () {
    final agg = ResultAggregator()
      ..add([const BrandResult(brandName: 'Exide', count: 1, isFuzzy: true)])
      ..add([const BrandResult(brandName: 'Exide', count: 2, isFuzzy: true)]);

    final exide = agg.results().single;
    expect(exide.isFuzzy, isTrue);
    expect(exide.count, 3); // 1 + 2
  });

  test('unions distinct brands across photos', () {
    final agg = ResultAggregator()
      ..add([const BrandResult(brandName: 'Pepsi', count: 1)])
      ..add([const BrandResult(brandName: 'Sprite', count: 1)]);

    expect(agg.results().map((r) => r.brandName), containsAll(['Pepsi', 'Sprite']));
    expect(agg.results().length, 2);
  });

  test('unions SKUs for a brand across photos', () {
    final agg = ResultAggregator()
      ..add([const BrandResult(brandName: 'Exide', count: 1, skus: ['Express'])])
      ..add([
        const BrandResult(brandName: 'Exide', count: 1, skus: ['Matrix', 'Express'])
      ]);

    final exide = agg.results().single;
    expect(exide.skus, containsAll(['Express', 'Matrix']));
    expect(exide.skus.length, 2); // deduped
    expect(exide.count, 2);
  });

  test('sorts confident first, then by count, then by name', () {
    final agg = ResultAggregator()
      ..add([
        const BrandResult(brandName: 'Fanta', count: 5, isFuzzy: true), // fuzzy
        const BrandResult(brandName: 'Bru', count: 1), // confident
        const BrandResult(brandName: 'Amul', count: 3), // confident
      ]);

    final order = agg.results().map((r) => r.brandName).toList();
    // Confident (Amul c3, Bru c1) before fuzzy (Fanta), confident sorted by count.
    expect(order, ['Amul', 'Bru', 'Fanta']);
  });
}
