# XPrinter Flutter Plugin

A Flutter plugin for controlling XPrinter thermal printers on Android. This plugin provides a simple interface to communicate with XPrinter thermal printers over Bluetooth.

## Features

- Scan for paired Bluetooth printers
- Connect to a printer by MAC address
- Print bitmap images
- Handle printer state changes
- Request necessary permissions

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  xprinter: ^0.0.1
```

### Android Setup

1. Ensure you have set up the extracted printer-lib AAR correctly:

   - The extracted AAR should be placed in `android/libs/printer-lib-extracted/` directory
   - The `classes.jar` file should be located in the `android/libs/printer-lib-extracted/` directory
   - Native libraries (`.so` files) should be in the appropriate architecture directories

2. Ensure your Android app has the required permissions in the `AndroidManifest.xml`:

```xml
<!-- USB permissions -->
<uses-feature android:name="android.hardware.usb.host" android:required="true" />
<uses-permission android:name="android.permission.USB_PERMISSION" />
<uses-permission android:name="android.hardware.usb.UsbAccessory" />

<!-- Bluetooth permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- Location permissions (required for Bluetooth scanning) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Network permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
```

3. Set your minSdkVersion to at least 21 in your `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
        // ...
    }
}
```

## Usage

```dart
import 'package:xprinter/xprinter.dart';

// Create an instance of the printer
final printer = Xprinter();

// Initialize the SDK
await printer.initialize();

// Request necessary Bluetooth permissions
if (!(await printer.hasBluetoothPermissions())) {
  await printer.requestBluetoothPermissions();
}

// Get paired Bluetooth devices
final devices = await printer.getBluetoothDevices();

// Connect to a printer
final connected = await printer.connectToPrinter('00:11:22:33:44:55');

// Print a bitmap image
if (connected) {
  await printer.printBitmap('/path/to/image.png');
}

// Disconnect when done
await printer.close();

// Exit SDK when no longer needed (e.g., in dispose)
await printer.exitSdk();
```

## Example

Refer to the `example` directory for a complete example application.

## Handling Runtime Permissions

For Android 6.0 (API level 23) and higher, you need to request runtime permissions:

```dart
// Request permissions
await printer.requestBluetoothPermissions();
```

## Troubleshooting

1. **Printer not found**: Ensure the printer is turned on and paired with the device.
2. **Cannot connect to printer**: Check if the MAC address is correct and the printer is in range.
3. **Permission denied**: Make sure you have requested all the necessary permissions.
4. **Printing fails**: Verify that the image file exists and is a valid bitmap.

## License

This project is licensed under the MIT License - see the LICENSE file for details.