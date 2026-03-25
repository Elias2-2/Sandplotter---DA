/// ============================== LED - Seite ==================================
/// In dieser Datei wurde die LED-Übersichtsseite definiert.
/// Auf dieser Seite kann man:
/// - Einzelne LEDs auswählen (LED 1-4) um Farbe/Animation zu ändern
/// - Vordefinierte Presets aktivieren (4 verschiedene Farbkombinationen)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrapperleds.dart';
import 'package:sandplotter_app/Costum/custombar.dart';
import 'package:sandplotter_app/Costum/ledbutton.dart';
import 'package:sandplotter_app/Costum/presetbutton.dart';
import 'package:sandplotter_app/pages/led_pages/led1.dart';
import 'package:sandplotter_app/pages/led_pages/led2.dart';
import 'package:sandplotter_app/pages/led_pages/led3.dart';
import 'package:sandplotter_app/pages/led_pages/led4.dart';

class Led extends StatelessWidget {
  const Led({required this.controller, super.key});

  // PageController - Steuert die Navigation zwischen LED/Home/Zeichnen-Seiten
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    // SafeArea - Beachtet System-UI (Statusbar, Uhrzeit, ...)
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: SafeArea(
        // InfoWrapperLeds - Zeigt bei Klick auf Info-Button die Legende dieser Seite an
        child: InfoWrapperLeds(
          // Scaffold - Grundgerüst für Material Design Seiten
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 25, 25, 25),
            // Custombar - Eigene AppBar mit Seitennavigation
            appBar: Custombar(
              controller: controller,
              iconL: Icons.brush_outlined, // Links: Zeichnen-Seite
              iconR: Icons.home, // Rechts: Home-Seite
              pageL: 2, // Seite 2 = Zeichnen
              pageR: 1, // Seite 1 = Home
              name: 'LEDs',
            ),
            // Stack erlaubt übereinander liegende Widgets
            // (hier für eventuelle Hintergrund-Animation vorbereitet)
            body: Stack(
              children: [
                // Hauptinhalt
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // === LED-BUTTONS ===
                    Row(
                      children: [
                        SizedBox(width: 33.w), // Linker Rand
                        Column(
                          children: [
                            // LedButton - Navigiert zur LED-Einstellungsseite
                            // number: LED-Index für Farbabfrage
                            // page: Zielseite
                            // 'LED 1': Buttontext
                            const LedButton(number: 1, page: Led1(), 'LED 1'),
                            SizedBox(height: 28.h),
                            const LedButton(number: 2, page: Led2(), 'LED 2'),
                            SizedBox(height: 28.h),
                            const LedButton(number: 3, page: Led3(), 'LED 3'),
                            SizedBox(height: 28.h),
                            const LedButton(number: 4, page: Led4(), 'LED 4'),
                            SizedBox(height: 28.h),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 15.h),

                    // === PRESET-BUTTONS REIHE 1 ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // PresetButton - Aktiviert vordefinierte Farbkombination
                        // Parameter: (preset-nummer, gradient-farbe1, gradient-farbe2)
                        const PresetButton(1, Colors.orange, Colors.red),
                        SizedBox(width: 43.w),
                        const PresetButton(2, Colors.teal, Colors.blue),
                      ],
                    ),

                    SizedBox(height: 37.h),

                    // === PRESET-BUTTONS REIHE 2 ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const PresetButton(3, Colors.purple, Colors.lime),
                        SizedBox(width: 43.w),
                        const PresetButton(4, Colors.white, Colors.black),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
