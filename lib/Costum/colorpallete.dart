/// ==================== Color Palette ======================
/// Farbauswahl für die LEDs
/// Quadratische HSV-Palette: X-Achse = Farbton, Y-Achse = Sättigung
/// Darunter ein Helligkeits-Slider
/// Die Ausgabe an den Provider bleibt als RGB Color identisch
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';

class ColorPickerPage extends StatefulWidget {
  const ColorPickerPage({required this.number, super.key});

  // LED-Nummer für die Farbauswahl
  final int number;

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  final double paletteSize = 270.h;

  // === HSV-Werte ===
  double _hue = 240.0; // Farbton (0-360), Start: Blau
  double _saturation = 0.96; // Sättigung (0-1)
  double _brightness = 1.0; // Helligkeit (0-1)

  // Position des Auswahlpunkts auf der Palette
  Offset _selectorPosition = Offset.zero;

  // Aktuelle Farbe
  Color _selectedColor = const Color.fromARGB(255, 10, 10, 255);

  @override
  void initState() {
    super.initState();
    // Initiale Position aus HSV berechnen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSelectorFromHSV();
    });
  }

  // === Gleichmäßige Farbverteilung ===
  // Stützpunkte: position (0-1) -> hue (0-360)
  // Gibt Rot, Orange, Gelb, Grün, Cyan, Blau, Magenta jeweils gleich viel Platz
  static const List<List<double>> _hueStops = [
    [0.0, 0.0], // Rot
    [0.12, 30.0], // Orange
    [0.22, 60.0], // Gelb
    [0.38, 120.0], // Grün
    [0.50, 180.0], // Cyan
    [0.68, 240.0], // Blau
    [0.82, 300.0], // Magenta
    [1.0, 360.0], // Rot (wrap)
  ];

  /// Position (0-1) -> Hue (0-360) mit gleichmäßiger Verteilung
  static double _remapHue(double t) {
    t = t.clamp(0.0, 1.0);
    for (int i = 0; i < _hueStops.length - 1; i++) {
      double t0 = _hueStops[i][0], h0 = _hueStops[i][1];
      double t1 = _hueStops[i + 1][0], h1 = _hueStops[i + 1][1];
      if (t <= t1) {
        double frac = (t - t0) / (t1 - t0);
        return (h0 + frac * (h1 - h0)) % 360.0;
      }
    }
    return 0.0;
  }

  /// Hue (0-360) -> Position (0-1) - Umkehrfunktion
  static double _inverseRemapHue(double hue) {
    hue = hue % 360.0;
    for (int i = 0; i < _hueStops.length - 1; i++) {
      double t0 = _hueStops[i][0], h0 = _hueStops[i][1];
      double t1 = _hueStops[i + 1][0], h1 = _hueStops[i + 1][1];
      if (hue <= h1) {
        double frac = (hue - h0) / (h1 - h0);
        return t0 + frac * (t1 - t0);
      }
    }
    return 1.0;
  }

  /// Berechnet Selector-Position aus aktuellen HSV-Werten
  void _updateSelectorFromHSV() {
    final x = _inverseRemapHue(_hue) * paletteSize;
    final y = (1.0 - _saturation) * paletteSize;
    setState(() {
      _selectorPosition = Offset(x.clamp(0, paletteSize), y.clamp(0, paletteSize));
    });
  }

  /// Touch auf der Farbpalette verarbeiten
  void _handlePaletteTouch(Offset localPosition) {
    final double padding = 2;
    double dx = localPosition.dx.clamp(padding, paletteSize - padding);
    double dy = localPosition.dy.clamp(padding, paletteSize - padding);

    // Hue aus X-Position mit gleichmäßigerer Verteilung
    double t = dx / paletteSize;
    _hue = _remapHue(t);
    // Sättigung aus Y-Position (oben = voll gesättigt, unten = weiß)
    _saturation = (1.0 - dy / paletteSize).clamp(0.0, 1.0);

    setState(() {
      _selectorPosition = Offset(dx, dy);
      _updateColor();
    });
  }

  /// Touch auf dem Helligkeits-Slider verarbeiten
  void _handleBrightnessTouch(Offset localPosition) {
    final sliderWidth = paletteSize;
    final newBrightness = (localPosition.dx / sliderWidth).clamp(0.0, 1.0);

    setState(() {
      _brightness = newBrightness;
      _updateColor();
    });
  }

  /// Farbe berechnen und an Provider senden
  void _updateColor() {
    _selectedColor = HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();

    context.read<LedColorProvider>().changeledcolor(
      lednumber: widget.number,
      ledcolor: _selectedColor,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // === FARBPALETTE ===
        GestureDetector(
          onPanDown: (details) => _handlePaletteTouch(details.localPosition),
          onPanUpdate: (details) => _handlePaletteTouch(details.localPosition),
          child: CustomPaint(
            size: Size(paletteSize, paletteSize),
            painter: _HSVPalettePainter(
              selectorPosition: _selectorPosition,
              selectedColor: _selectedColor,
              brightness: _brightness,
            ),
          ),
        ),

        SizedBox(height: 18.h),

        // === HELLIGKEITS-SLIDER ===
        _buildBrightnessSlider(),
      ],
    );
  }

  Widget _buildBrightnessSlider() {
    final fullBrightColor = HSVColor.fromAHSV(1.0, _hue, _saturation, 1.0).toColor();

    return GestureDetector(
      onPanDown: (details) => _handleBrightnessTouch(details.localPosition),
      onPanUpdate: (details) => _handleBrightnessTouch(details.localPosition),
      child: CustomPaint(
        size: Size(paletteSize, 32.h),
        painter: _BrightnessSliderPainter(brightness: _brightness, fullBrightColor: fullBrightColor),
      ),
    );
  }
}

// =============================================================================
// HSV-PALETTE PAINTER (Quadratisch)
// X-Achse = Hue (Farbton), Y-Achse = Sättigung (oben = voll, unten = weiß)
// =============================================================================

class _HSVPalettePainter extends CustomPainter {
  final Offset selectorPosition;
  final Color selectedColor;
  final double brightness;

  _HSVPalettePainter({required this.selectorPosition, required this.selectedColor, required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final resolution = 2; // Feine Auflösung (keine sichtbaren Kästchen)

    // Abgerundetes Rechteck clippen
    final rRect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    canvas.clipRRect(rRect);

    // === Farbpalette zeichnen ===
    for (double x = 0; x < size.width; x += resolution) {
      for (double y = 0; y < size.height; y += resolution) {
        // Hue aus X-Position mit gleichmäßiger Verteilung
        double t = x / size.width;
        double hue = _ColorPickerPageState._remapHue(t);
        // Sättigung aus Y-Position (oben = 1, unten = 0)
        double saturation = 1.0 - (y / size.height);

        final color = HSVColor.fromAHSV(1.0, hue, saturation, brightness).toColor();
        paint.color = color;

        canvas.drawRect(Rect.fromLTWH(x, y, resolution.toDouble(), resolution.toDouble()), paint);
      }
    }

    // === Auswahlpunkt zeichnen ===
    if (selectorPosition != Offset.zero) {
      // Glow-Effekt in der gewählten Farbe
      final glowPaint = Paint()
        ..color = selectedColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(selectorPosition, 13, glowPaint);

      // Äußerer weißer Ring
      final outerRingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white;
      canvas.drawCircle(selectorPosition, 10, outerRingPaint);

      // Innerer Farbpunkt
      final innerPaint = Paint()..color = selectedColor;
      canvas.drawCircle(selectorPosition, 7, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HSVPalettePainter oldDelegate) {
    return oldDelegate.selectorPosition != selectorPosition ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.brightness != brightness;
  }
}

// =============================================================================
// HELLIGKEITS-SLIDER PAINTER
// =============================================================================

class _BrightnessSliderPainter extends CustomPainter {
  final double brightness;
  final Color fullBrightColor;

  _BrightnessSliderPainter({required this.brightness, required this.fullBrightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height;
    final barHeight = 14.0;
    final barY = (height - barHeight) / 2;
    final barRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, barY, size.width, barHeight), const Radius.circular(7));

    // Gradient: Schwarz -> aktuelle Farbe
    final gradient = LinearGradient(colors: [Colors.black, fullBrightColor]);
    final gradientPaint = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, barY, size.width, barHeight));
    canvas.drawRRect(barRect, gradientPaint);

    // Subtiler Rand
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.1);
    canvas.drawRRect(barRect, borderPaint);

    // === Thumb ===
    final thumbX = brightness * size.width;
    final thumbCenter = Offset(thumbX.clamp(8.0, size.width - 8.0), height / 2);

    // Glow
    final glowPaint = Paint()
      ..color = fullBrightColor.withValues(alpha: 0.3 * brightness)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(thumbCenter, 10, glowPaint);

    // Weißer Ring
    final thumbBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;
    canvas.drawCircle(thumbCenter, 8, thumbBorderPaint);

    // Farbfüllung
    final currentColor = Color.lerp(Colors.black, fullBrightColor, brightness)!;
    final thumbFillPaint = Paint()..color = currentColor;
    canvas.drawCircle(thumbCenter, 6, thumbFillPaint);
  }

  @override
  bool shouldRepaint(covariant _BrightnessSliderPainter oldDelegate) {
    return oldDelegate.brightness != brightness || oldDelegate.fullBrightColor != fullBrightColor;
  }
}
