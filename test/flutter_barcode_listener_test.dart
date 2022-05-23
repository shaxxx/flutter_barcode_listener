import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test that onBarcodeScanned is working correctly',
      (tester) async {
    String? scannedBarcode;
    await tester.pumpWidget(BarcodeKeyboardListener(
      child: Container(),
      onBarcodeScanned: (barcode) {
        scannedBarcode = barcode;
      },
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(scannedBarcode, '1');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);

    expect(scannedBarcode, '23');

    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);

    // without enter
    expect(scannedBarcode, '23');
  });
}
