# Changelog

## 0.0.1

* Initial release
* Support for connecting to XPrinter thermal printers via Bluetooth
* API for printing bitmap images
* Support for handling printer states and events
* Permission handling for Android

## 0.0.2

* Rename plugin class from XprinterPlugin to XPrinterFlutterPlugin in pubspec.yaml


## 0.0.3

* Add printer configuration model and UI for settings page

- Created PrinterConfig class to encapsulate printer settings.
- Implemented PrinterConfigPage with sliders for density and speed.
- Added input fields for paper width and height.
- Included save functionality with loading indicator and success message.
- Implemented reset to default settings feature.