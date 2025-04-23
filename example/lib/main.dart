import 'package:flutter/material.dart';
import 'package:xprinter/xprinter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Xprinter _xprinterPlugin = Xprinter();
  List<BluetoothPrinterDevice> _devices = [];
  String _status = 'Disconnected';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializePrinterSDK();
  }

  Future<void> _initializePrinterSDK() async {
    try {
      final initialized = await _xprinterPlugin.initialize();
      setState(() {
        _status = initialized ? 'SDK initialized' : 'Failed to initialize SDK';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing SDK: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final hasPermissions = await _xprinterPlugin.hasBluetoothPermissions();
      if (!hasPermissions) {
        final granted = await _xprinterPlugin.requestBluetoothPermissions();
        setState(() {
          _status = granted ? 'Permissions granted' : 'Permissions denied';
        });
      } else {
        setState(() {
          _status = 'Permissions already granted';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error requesting permissions: $e';
      });
    }
  }

  Future<void> _getBluetoothDevices() async {
    try {
      final devices = await _xprinterPlugin.getBluetoothDevices();
      setState(() {
        _devices = devices;
        _status = 'Found ${devices.length} devices';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting devices: $e';
      });
    }
  }

  Future<void> _connectToPrinter(String macAddress) async {
    try {
      setState(() {
        _status = 'Connecting...';
      });
      final connected = await _xprinterPlugin.connectToPrinter(macAddress);
      setState(() {
        _isConnected = connected;
        _status = connected ? 'Connected' : 'Failed to connect';
      });
    } catch (e) {
      setState(() {
        _status = 'Error connecting: $e';
      });
    }
  }

  Future<void> _printTestImage() async {
    if (!_isConnected) {
      setState(() {
        _status = 'Printer not connected';
      });
      return;
    }

    try {
      setState(() {
        _status = 'Printing...';
      });
      // Note: Replace with actual path to a test image on device
      final success = await _xprinterPlugin.printBitmap(
        '/path/to/test/image.png',
      );
      setState(() {
        _status = success ? 'Print successful' : 'Print failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error printing: $e';
      });
    }
  }

  Future<void> _disconnectPrinter() async {
    try {
      await _xprinterPlugin.close();
      setState(() {
        _isConnected = false;
        _status = 'Disconnected';
      });
    } catch (e) {
      setState(() {
        _status = 'Error disconnecting: $e';
      });
    }
  }

  @override
  void dispose() {
    _xprinterPlugin.exitSdk();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('XPrinter Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Request Permissions'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _getBluetoothDevices,
                child: const Text('Get Bluetooth Devices'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      onTap: () => _connectToPrinter(device.address),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isConnected ? _printTestImage : null,
                    child: const Text('Print Test Image'),
                  ),
                  ElevatedButton(
                    onPressed: _isConnected ? _disconnectPrinter : null,
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
