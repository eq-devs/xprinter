import 'dart:async';
import 'package:flutter/foundation.dart';
import 'xprinter_platform_interface.dart';

export 'xprinter_platform_interface.dart'
    show BluetoothPrinterDevice, PrinterState;

@immutable
class Xprinter {
  const Xprinter();

  /// Get platform version
  Future<String?> getPlatformVersion() {
    return XprinterPlatform.instance.getPlatformVersion();
  }

  /// Initialize the printer SDK
  Future<bool> initialize() {
    return XprinterPlatform.instance.initialize();
  }

  /// Check if all required Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() {
    return XprinterPlatform.instance.hasBluetoothPermissions();
  }

  /// Request Bluetooth permissions
  Future<bool> requestBluetoothPermissions() {
    return XprinterPlatform.instance.requestBluetoothPermissions();
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothPrinterDevice>> getBluetoothDevices() {
    return XprinterPlatform.instance.getBluetoothDevices();
  }

  /// Check if printer is currently connected
  Future<bool> isPrinterConnected() {
    return XprinterPlatform.instance.isPrinterConnected();
  }

  /// Connect to a specific printer by MAC address
  Future<bool> connectToPrinter(String macAddress) {
    return XprinterPlatform.instance.connectToPrinter(macAddress);
  }

  /// Reconnect to last used printer
  Future<bool> reconnectLastPrinter() {
    return XprinterPlatform.instance.reconnectLastPrinter();
  }

  /// Print a bitmap file
  Future<bool> printBitmap(String filePath) {
    return XprinterPlatform.instance.printBitmap(filePath);
  }

  /// Close printer connection
  Future<void> close() {
    return XprinterPlatform.instance.close();
  }

  /// Exit SDK and release resources
  Future<void> exitSdk() {
    return XprinterPlatform.instance.exitSdk();
  }
}

// Re-export types from platform interface
