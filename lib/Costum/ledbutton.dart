/// ============================== LED Button ================================
/// In dieser Datei wurde der LED-Button der App vordefiniert, damit er mehrmals verwendet werden kann ohne ihn jedes mal neu programmieren zu müssen.
/// Durch dieses Button werden die einzelnen LED-Seiten geöffnet, in denen man die Farbe und die Animation der einzelnen LEDs einstellen kann.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';

class LedButton extends StatelessWidget {
  const LedButton(this.name, {required this.number, required this.page, super.key});

  final String name; // Text des Buttons (Led1, Led2, ...)
  final Widget page; // Zielseite bei Klick des Buttons
  final int number; // LED-Nummer für Farbabfarge aus dem Provider

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Wenn man auf den Button drückt wird die übergebene Seite aufgerufen
        // und mit einer definierten Animation dann auch angezeigt
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, _, _) => page,
            transitionsBuilder: (_, anim, _, child) {
              final fadeAnimation = CurvedAnimation(
                parent: anim,
                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
              );

              return FadeTransition(opacity: fadeAnimation, child: child);
            },
          ),
        );
      },
      // Design des Buttons
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 54, 54, 54),
        minimumSize: Size(145.w, 48.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        name,
        // Farbe des Texts des Buttons wird aus dem LEDColorProvider übernommen
        // So ist die Farbe der Schrift die Farbe die die LED hat
        style: TextStyle(fontSize: 14.h, color: context.watch<LedColorProvider>().ledcolor(number)),
      ),
    );
  }
}
