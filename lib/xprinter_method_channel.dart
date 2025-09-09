import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:xprinter_android/model/config.dart';
import 'xprinter_platform_interface.dart';

class MethodChannelXprinter extends XprinterPlatform {
  @override
  Future<bool> configurePrinter(PrinterConfig config) async {
    final bool result =
        await methodChannel.invokeMethod('configurePrinter', config.toMap());
    return result;
  }

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.eq.xprinter');

  /// Stream controller for printer state changes
  final _stateStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of printer state changes
  Stream<Map<String, dynamic>> get stateStream => _stateStreamController.stream;

  MethodChannelXprinter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handles method calls from the native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPrinterStateChanged':
        _stateStreamController.add(Map<String, dynamic>.from(call.arguments));
        break;
      default:
        print('Unimplemented method ${call.method} called');
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> initialize() async {
    final bool result = await methodChannel.invokeMethod('initialize');
    return result;
  }

  @override
  Future<bool> hasBluetoothPermissions() async {
    final bool result = await methodChannel.invokeMethod(
      'hasBluetoothPermissions',
    );
    return result;
  }

  @override
  Future<bool> requestBluetoothPermissions() async {
    final bool result = await methodChannel.invokeMethod(
      'requestBluetoothPermissions',
    );
    return result;
  }

  @override
  Future<List<BluetoothPrinterDevice>> getBluetoothDevices() async {
    final List<dynamic> result = await methodChannel.invokeMethod(
      'getBluetoothDevices',
    );
    return result
        .map(
          (device) => BluetoothPrinterDevice(
            name: device['name'],
            address: device['address'],
          ),
        )
        .toList();
  }

  @override
  Future<bool> isPrinterConnected() async {
    final bool result = await methodChannel.invokeMethod('isPrinterConnected');
    return result;
  }

  @override
  Future<bool> connectToPrinter(String macAddress) async {
    final bool result = await methodChannel.invokeMethod('connectToPrinter', {
      'macAddress': macAddress,
    });
    return result;
  }

  @override
  Future<bool> reconnectLastPrinter() async {
    final bool result = await methodChannel.invokeMethod(
      'reconnectLastPrinter',
    );
    return result;
  }

  @override
  Future<bool> printBitmap(String filePath) async {
    final bool result = await methodChannel.invokeMethod('printBitmap', {
      'filePath': filePath,
    });
    return result;
  }

  @override
  Future<bool> printImage(String base64Encoded, {double width = 460}) async {
    final bool result = await methodChannel.invokeMethod('printImage', {
      'base64Encoded': base64Encoded,
      'width': width,
    });
    return result;
  }

  @override
  Future<void> close() async {
    await methodChannel.invokeMethod('close');
  }

  @override
  Future<void> exitSdk() async {
    await methodChannel.invokeMethod('exitSdk');
  }

  /// Dispose resources
  void dispose() {
    _stateStreamController.close();
  }
}
