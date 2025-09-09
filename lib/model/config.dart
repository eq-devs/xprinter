///

class PrinterConfig {
  final int density;
  final double speed;
  final double paperWidth;
  final double paperHeight;

  const PrinterConfig({
    this.density = 8,
    this.speed = 4.0,
    this.paperWidth = 2.0,
    this.paperHeight = 1.0,
  });

  Map<String, dynamic> toMap() => {
        'density': density,
        'speed': speed,
        'paperWidth': paperWidth,
        'paperHeight': paperHeight
      };
}
