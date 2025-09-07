import 'xprinter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class XprinterPlatform extends PlatformInterface {
  /// Constructs a XprinterPlatform.
  XprinterPlatform() : super(token: _token);

  static final Object _token = Object();

  static XprinterPlatform _instance = MethodChannelXprinter();

  /// The default instance of [XprinterPlatform] to use.
  ///
  /// Defaults to [MethodChannelXprinter].
  static XprinterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [XprinterPlatform] when
  /// they register themselves.
  static set instance(XprinterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Initialize the printer SDK
  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Check if all required Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() {
    throw UnimplementedError(
      'hasBluetoothPermissions() has not been implemented.',
    );
  }

  /// Request Bluetooth permissions
  Future<bool> requestBluetoothPermissions() {
    throw UnimplementedError(
      'requestBluetoothPermissions() has not been implemented.',
    );
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothPrinterDevice>> getBluetoothDevices() {
    throw UnimplementedError('getBluetoothDevices() has not been implemented.');
  }

  /// Check if printer is currently connected
  Future<bool> isPrinterConnected() {
    throw UnimplementedError('isPrinterConnected() has not been implemented.');
  }

  /// Connect to a specific printer by MAC address
  Future<bool> connectToPrinter(String macAddress) {
    throw UnimplementedError('connectToPrinter() has not been implemented.');
  }

  /// Reconnect to last used printer
  Future<bool> reconnectLastPrinter() {
    throw UnimplementedError(
      'reconnectLastPrinter() has not been implemented.',
    );
  }

  /// Print a bitmap file
  Future<bool> printBitmap(String filePath) {
    throw UnimplementedError('printBitmap() has not been implemented.');
  }

  /// Print an image from a base64 encoded string
  Future<bool> printImage(String base64Encoded, {double width = 460}) {
    throw UnimplementedError('printImage() has not been implemented.');
  }

  /// Close printer connection
  Future<void> close() {
    throw UnimplementedError('close() has not been implemented.');
  }

  /// Exit SDK and release resources
  Future<void> exitSdk() {
    throw UnimplementedError('exitSdk() has not been implemented.');
  }
}

/// Data class representing a Bluetooth printer device
class BluetoothPrinterDevice {
  final String name;
  final String address;

  BluetoothPrinterDevice({required this.name, required this.address});
}

/// Enum representing different printer states
// ignore: constant_identifier_names
enum PrinterState { DISCONNECTED, CONNECTING, CONNECTED, PRINTING, ERROR }
