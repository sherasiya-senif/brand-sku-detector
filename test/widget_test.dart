// Smoke test for the Detector screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:brand_sku_detector/main.dart';

void main() {
  testWidgets('Detector screen shows the upload and capture actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Detector'), findsOneWidget);
    expect(find.text('Upload Photo'), findsOneWidget);
    expect(find.text('Capture Photo'), findsOneWidget);
  });
}
