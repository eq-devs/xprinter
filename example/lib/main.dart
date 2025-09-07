import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:xprinter/xprinter.dart';
import 'package:image_picker/image_picker.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

  List<BluetoothPrinterDevice> _devices = [];
  String _status = 'Disconnected';
  bool _isConnected = false;
  XFile? _selectedImage;
  double _imageWidth = 460.0;

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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _status = 'Image selected: ${image.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error picking image: $e';
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _status = 'Image captured: ${image.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error capturing image: $e';
      });
    }
  }

  Future<String> _convertImageToBase64(XFile imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  Future<void> _printSelectedImage() async {
    if (!_isConnected) {
      setState(() {
        _status = 'Printer not connected';
      });
      return;
    }

    if (_selectedImage == null) {
      setState(() {
        _status = 'No image selected';
      });
      return;
    }

    try {
      setState(() {
        _status = 'Converting image...';
      });

      // Convert image to base64
      final String base64Image = await _convertImageToBase64(_selectedImage!);

      setState(() {
        _status = 'Printing image...';
      });

      // Print the base64 image
      final success = await _xprinterPlugin.printImage(
        base64Image,
        width: _imageWidth,
      );

      setState(() {
        _status = success ? 'Print successful!' : 'Print failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error printing image: $e';
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
        _status = 'Printing test image...';
      });

      // Create a simple test image (1x1 pixel PNG in base64)
      final String testImageBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

      final success = await _xprinterPlugin.printImage(
        testImageBase64,
        width: _imageWidth,
      );

      setState(() {
        _status = success ? 'Test print successful!' : 'Test print failed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error printing test image: $e';
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
        appBar: AppBar(
          title: const Text('XPrinter Image Example'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $_status',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connected: ${_isConnected ? "Yes" : "No"}',
                        style: TextStyle(
                          color: _isConnected ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Image Selection Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image Selection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImage != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selected: ${_selectedImage!.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Print Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Print Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Image Width: ${_imageWidth.toInt()}px'),
                      Slider(
                        value: _imageWidth,
                        min: 200,
                        max: 600,
                        divisions: 20,
                        label: '${_imageWidth.toInt()}px',
                        onChanged: (value) {
                          setState(() {
                            _imageWidth = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Printer Setup Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Printer Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _requestPermissions,
                        child: const Text('Request Permissions'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _getBluetoothDevices,
                        child: const Text('Get Bluetooth Devices'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Device List
              if (_devices.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Printers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.print),
                                  title: Text(device.name),
                                  subtitle: Text(device.address),
                                  trailing: ElevatedButton(
                                    onPressed: () =>
                                        _connectToPrinter(device.address),
                                    child: const Text('Connect'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Print Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Print Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isConnected ? _printSelectedImage : null,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Selected'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isConnected ? _printTestImage : null,
                              icon: const Icon(Icons.bug_report),
                              label: const Text('Test Print'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isConnected ? _disconnectPrinter : null,
                          icon: const Icon(Icons.close),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
