library flutter_barcode_listener;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

class BarcodeListenerWidget extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback _onBarcodeScanned;
  final Duration _bufferDuration;
  final int _barcodeEndCharCode;
  BarcodeListenerWidget({
    Key key,
    this.child,
    // Callback to be called when barcode is scanned
    @required Function(String) onBarcodeScanned,
    // Time frame to listen for keyboard events as one barcode scan
    Duration bufferDuration = const Duration(milliseconds: 500),
    // Code of the barcode termination character,
    // defaults to standard line feed character(10)
    int barcodeEndCharCode = 10,
  })  : _onBarcodeScanned = onBarcodeScanned,
        _bufferDuration = bufferDuration,
        _barcodeEndCharCode = barcodeEndCharCode,
        assert(child != null),
        super(key: key);
  @override
  _BarcodeListenerWidgetState createState() => _BarcodeListenerWidgetState(
        _onBarcodeScanned,
        _bufferDuration,
        _barcodeEndCharCode,
      );
}

class _BarcodeListenerWidgetState extends State<BarcodeListenerWidget> {
  StreamSubscription<String> _subscription;
  final BarcodeScannedCallback _onBarcodeScannedCallback;
  final Duration _bufferDuration;
  final int _barcodeEndCharCode;

  StreamController<RawKeyDownEvent> _controller =
      StreamController<RawKeyDownEvent>();
  _BarcodeListenerWidgetState(this._onBarcodeScannedCallback,
      this._bufferDuration, this._barcodeEndCharCode) {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _subscription = _controller.stream
        .where((event) => event.character != null)
        .buffer(Stream.periodic(_bufferDuration, (i) => i))
        .where((event) => event.length > 1)
        .where((event) =>
            listEquals(event.last.character.codeUnits, [_barcodeEndCharCode]))
        .map((event) => event.toList()..removeLast())
        .map((event) =>
            event.map((e) => e.character.codeUnits).expand((i) => i).toList())
        .map((event) => String.fromCharCodes(event))
        .listen((event) {
      _onBarcodeScannedCallback?.call(event);
    });
  }

  _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent is RawKeyDownEvent) {
      _controller.sink.add(keyEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.close();
    RawKeyboard.instance.removeListener(_keyBoardCallback);
    super.dispose();
  }
}
