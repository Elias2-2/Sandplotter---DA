/// ============================== LED1 - Seite ================================
/// In dieser Datei wurde die 1.LED-Seite definiert.
/// Auf dieser Seite kann die Farbe und die Animation der LED ausgewählt werden
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrapperled.dart';
import 'package:sandplotter_app/Costum/animationbutton.dart';
import 'package:sandplotter_app/Costum/colorpallete.dart';
import 'package:sandplotter_app/Costum/custombar_return.dart';

class Led1 extends StatelessWidget {
  const Led1({super.key});

  final int lednumber = 1; // Nummer der LED auf der Seite

  @override
  Widget build(BuildContext context) {
    // InfoWrapper - Zeigt bei Klick auf Info-Button die Legende der Seite an
    // Vordefiniert in InfoWrapperLed.dart
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: InfoWrapperLed(
        child: SafeArea(
          // Safearea - Beachtet System-UI (Statusbar, Uhrzeit, ...)
          child: Scaffold(
            // Grundgerüst für Materialdesign Seiten
            backgroundColor: const Color.fromARGB(255, 25, 25, 25),
            appBar: CustombarReturn('Led 1'), // CustombarReturn eingefügt (Definiert in costumbarreturn.dart)
            // Hauptinhalt der Seite
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.h),
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
                  // Farbauswahl eingefügt (definiert in colorpalette.dart)
                  child: const ColorPickerPage(number: 1),
                ),
                SizedBox(height: 20.h),
                // Animationsbuttons eingefügt und Lednummer übergeben
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimationButton(lednumber: lednumber, number: 1),
                    SizedBox(width: 43.w),
                    AnimationButton(lednumber: lednumber, number: 2),
                  ],
                ),
                SizedBox(height: 37.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimationButton(lednumber: lednumber, number: 3),
                    SizedBox(width: 43.w),
                    AnimationButton(lednumber: lednumber, number: 4),
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
