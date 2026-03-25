/// ============================== Preset Button ================================
/// In dieser Datei wurde der Preset-Button der App vordefiniert,
/// damit er mehrmals verwendet werden kann ohne ihn jedes mal neu programmieren zu müssen.
/// Durch dieses Button werden die Presets der LEDs gewählt
/// Es wurde das Icon des Button mit einem anschaulichen Farb-Gradienten versehen
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/presetprovider.dart';

class PresetButton extends StatelessWidget {
  // Konstruktor mit Parametern
  const PresetButton(this.number, this.color1, this.color2, {super.key});

  final Color color1; // Erste Farbe des Gradienten des Icons am Button
  final Color color2; // Zweite Farbe des Gradienten des Icons am Button
  final int number; // Preset-Index für Provider

  @override
  Widget build(BuildContext context) {
    // Aktivitätsstatus von Provider abfragen
    bool isAktiv = context.watch<PresetProvider>().isPresetActive(number);

    return ElevatedButton(
      onPressed: () {
        // Preset aktiviert über Provider
        context.read<PresetProvider>().activatePreset(number, context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isAktiv ? const Color.fromARGB(199, 203, 203, 255) : const Color.fromARGB(255, 54, 54, 54),
        minimumSize: Size(125.w, 90.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      // Wendet einen Shader (Effekt) auf ein Widget an
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: isAktiv
              ? [const Color.fromARGB(255, 54, 54, 54), const Color.fromARGB(255, 54, 54, 54)]
              : [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: Icon(Icons.flare, size: 65.h, color: Colors.white),
      ),
    );
  }
}
