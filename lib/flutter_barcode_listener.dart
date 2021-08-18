library flutter_barcode_listener;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef BarcodeScannedCallback = void Function(String barcode);

/// This widget will listen for raw PHYSICAL keyboard events
/// even when other controls have primary focus.
/// It will buffer all characters coming in specifed `bufferDuration` time frame
/// that end with line feed character and call callback function with result.
/// Keep in mind this widget will listen for events even when not visible.
class BarcodeKeyboardListener extends StatefulWidget {
  final Widget child;
  final BarcodeScannedCallback _onBarcodeScanned;
  final Duration _bufferDuration;

  /// This widget will listen for raw PHYSICAL keyboard events
  /// even when other controls have primary focus.
  /// It will buffer all characters coming in specifed `bufferDuration` time frame
  /// that end with line feed character and call callback function with result.
  /// Keep in mind this widget will listen for events even when not visible.
  BarcodeKeyboardListener(
      {Key? key,

      /// Child widget to be displayed
      required this.child,

      /// Callback to be called when barcode is scanned
      required Function(String) onBarcodeScanned,

      /// Maximum time between two key events.
      /// If time between two key events is longer than this value
      /// previous keys will be ignored.
      Duration bufferDuration = hundredMs})
      : _onBarcodeScanned = onBarcodeScanned,
        _bufferDuration = bufferDuration,
        super(key: key);
  @override
  _BarcodeKeyboardListenerState createState() =>
      _BarcodeKeyboardListenerState(_onBarcodeScanned, _bufferDuration);
}

const Duration aSecond = Duration(seconds: 1);
const Duration hundredMs = Duration(milliseconds: 100);
const int lineFeed = 10;

class _BarcodeKeyboardListenerState extends State<BarcodeKeyboardListener> {
  List<int> _scannedCharCodes = [];
  DateTime? _lastScannedCharCodeTime;
  late StreamSubscription<int?> _keyboardSubscription;

  final BarcodeScannedCallback _onBarcodeScannedCallback;
  final Duration _bufferDuration;

  final _controller = StreamController<int?>();
  _BarcodeKeyboardListenerState(
      this._onBarcodeScannedCallback, this._bufferDuration) {
    RawKeyboard.instance.addListener(_keyBoardCallback);
    _keyboardSubscription = _controller.stream
        .where((charCode) => charCode != null)
        .listen(onKeyEvent);
  }

  void onKeyEvent(int? charCode) {
    //remove any pending characters older than bufferDuration value
    checkPendingCharCodesToClear();
    _lastScannedCharCodeTime = DateTime.now();
    if (charCode == lineFeed) {
      _onBarcodeScannedCallback.call(String.fromCharCodes(_scannedCharCodes));

      resetScannedCharCodes();
    } else {
      //add character to list of scanned characters;
      _scannedCharCodes.add(charCode!);
    }
  }

  void checkPendingCharCodesToClear() {
    if (_lastScannedCharCodeTime != null) {
      if (_lastScannedCharCodeTime!
          .isBefore(DateTime.now().subtract(_bufferDuration))) {
        resetScannedCharCodes();
      }
    }
  }

  void resetScannedCharCodes() {
    _lastScannedCharCodeTime = null;
    _scannedCharCodes = [];
  }

  void addScannedCharCode(int charCode) {
    _scannedCharCodes.add(charCode);
  }

  void _keyBoardCallback(RawKeyEvent keyEvent) {
    if (keyEvent.logicalKey.keyId > 255 &&
        keyEvent.data.logicalKey != LogicalKeyboardKey.enter) return;
    if (keyEvent is RawKeyUpEvent) {
      if (keyEvent.data is RawKeyEventDataAndroid) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataAndroid).codePoint);
      } else if (keyEvent.data is RawKeyEventDataFuchsia) {
        _controller.sink
            .add(((keyEvent.data) as RawKeyEventDataFuchsia).codePoint);
      } else if (keyEvent.data.logicalKey == LogicalKeyboardKey.enter) {
        _controller.sink.add(lineFeed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _keyboardSubscription.cancel();
    _controller.close();
    RawKeyboard.instance.removeListener(_keyBoardCallback);
    super.dispose();
  }
}
