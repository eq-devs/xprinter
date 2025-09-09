import 'package:flutter/material.dart';
import '../xprinter.dart';

@immutable
class PrinterConfigPage extends StatefulWidget {
  const PrinterConfigPage({Key? key}) : super(key: key);

  @override
  State<PrinterConfigPage> createState() => _PrinterConfigPageState();
}

class _PrinterConfigPageState extends State<PrinterConfigPage> {
  final Xprinter _xprinterPlugin = const Xprinter();

  // Default configuration
  double _density = 5;
  double _speed = 3.0;
  double _paperWidth = 2.7;
  double _paperHeight = 3.8;

  bool _isSaving = false;
  bool _showSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Printer Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     color: Colors.white,
            //     borderRadius: BorderRadius.circular(16),
            //     boxShadow: [
            //       BoxShadow(
            //         color: Colors.black.withOpacity(0.05),
            //         blurRadius: 10,
            //         offset: const Offset(0, 2),
            //       ),
            //     ],
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Row(
            //         children: [
            //           Container(
            //             padding: const EdgeInsets.all(12),
            //             decoration: BoxDecoration(
            //               color: Colors.green.withOpacity(0.1),
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //             child: const Icon(
            //               Icons.settings,
            //               color: Colors.green,
            //               size: 24,
            //             ),
            //           ),
            //           const SizedBox(width: 12),
            //           const Expanded(
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 Text(
            //                   'Configuration',
            //                   style: TextStyle(
            //                     fontSize: 18,
            //                     fontWeight: FontWeight.w600,
            //                     color: Colors.black87,
            //                   ),
            //                 ),
            //                 SizedBox(height: 4),
            //                 Text(
            //                   'Optimize settings for your thermal printer',
            //                   style: TextStyle(
            //                     fontSize: 14,
            //                     color: Colors.black54,
            //                   ),
            //                 ),
            //               ],
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 20),
            // Print Quality Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.print, color: Colors.orange[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Print Quality',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Density Slider
                  _buildSliderSection(
                    'Density',
                    _density,
                    1,
                    15,
                    'Light',
                    'Dark',
                    _density.round().toString(),
                    (value) => setState(() => _density = value),
                  ),

                  const SizedBox(height: 24),

                  // Speed Slider
                  _buildSliderSection(
                    'Speed',
                    _speed,
                    1.0,
                    6.0,
                    'Slow',
                    'Fast',
                    _speed.toStringAsFixed(1),
                    (value) => setState(() => _speed = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Paper Size Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.crop_portrait,
                          color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Paper Size (inches)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Width
                      Expanded(
                        child: _buildNumberInput(
                          'Width',
                          _paperWidth,
                          (value) => setState(() => _paperWidth = value),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Height
                      Expanded(
                        child: _buildNumberInput(
                          'Height',
                          _paperHeight,
                          (value) => setState(() => _paperHeight = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _showSaved
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Saved!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save Configuration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    String title,
    double value,
    double min,
    double max,
    String minLabel,
    String maxLabel,
    String currentValue,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                currentValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.green[600],
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Colors.green[600],
            overlayColor: Colors.green.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            Text(
              maxLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberInput(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            initialValue: value.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (val) {
              final parsedValue = double.tryParse(val);
              if (parsedValue != null) {
                onChanged(parsedValue);
              }
            },
          ),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    setState(() {
      _density = 6;
      _speed = 3.0;
      _paperWidth = 3;
      _paperHeight = 3.8;
    });
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);

    try {
      // Your printer configuration logic here
      await _xprinterPlugin.configurePrinter(PrinterConfig(
        density: _density.round(),
        speed: _speed,
        paperWidth: _paperWidth,
        paperHeight: _paperHeight,
      ));

      await Future.delayed(
          const Duration(milliseconds: 800)); // Simulate API call

      setState(() {
        _isSaving = false;
        _showSaved = true;
      });

      // Hide success message after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSaved = false);
        }
      });
    } catch (e) {
      setState(() => _isSaving = false);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving configuration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
