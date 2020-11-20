library flutter_barcode_listener;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

// This widget will listen for raw PHYSICAL keyboard events
// even when other controls have primary focus.
// It will buffer all characters coming in specifed `bufferDuration` time frame
// that end with line feed character and call callback function with result.
// Keep in mind this widget will listen for events even when not visible.
class BarcodeListenerWidget extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback _onBarcodeScanned;
  final Duration _bufferDuration;
  BarcodeListenerWidget(
      {Key key,
      this.child,
      // Callback to be called when barcode is scanned
      @required Function(String) onBarcodeScanned,
      // Time frame to listen for keyboard events as one barcode scan
      // If you're reading only last part of barcode you'll need to increase this
      Duration bufferDuration = const Duration(milliseconds: 500)})
      : _onBarcodeScanned = onBarcodeScanned,
        _bufferDuration = bufferDuration,
        assert(child != null),
        super(key: key);
  @override
  _BarcodeListenerWidgetState createState() =>
      _BarcodeListenerWidgetState(_onBarcodeScanned, _bufferDuration);
}

class _BarcodeListenerWidgetState extends State<BarcodeListenerWidget> {
  StreamSubscription<String> _subscription;
  final BarcodeScannedCallback _onBarcodeScannedCallback;
  final Duration _bufferDuration;

  var _controller = StreamController<int>();
  _BarcodeListenerWidgetState(
      this._onBarcodeScannedCallback, this._bufferDuration) {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _subscription = _controller.stream
        .where((event) => event != null)
        .buffer(Stream.periodic(_bufferDuration, (i) => i))
        .where((event) => event.length > 1)
        .where((event) => event.last == 10)
        .map((event) => event.toList()..removeLast())
        .map((event) => String.fromCharCodes(event))
        .listen((event) {
      _onBarcodeScannedCallback?.call(event);
    });
  }

  _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255 &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.enter) return;
    if (keyEvent is RawKeyUpEvent) {
      if (keyEvent.data != null) {
        if (keyEvent.data is RawKeyEventDataAndroid) {
          _controller.sink
              .add(((keyEvent.data) as RawKeyEventDataAndroid).codePoint);
        } else if (keyEvent.data is RawKeyEventDataFuchsia) {
          _controller.sink
              .add(((keyEvent.data) as RawKeyEventDataFuchsia).codePoint);
        } else if (keyEvent.data.logicalKey == LogicalKeyboardKey.enter) {
          _controller.sink.add(10);
        }
      } else {
        _controller.sink.add(keyEvent.logicalKey.keyId);
      }
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
