/// ==================== Info Wrapper Home ======================
/// Infowrapper ist das Informationsmenü, welches mit dem "Rufzeichen"-Knop in der rechten
/// oberen Ecke geöffnet werden kann.
/// Das Menü als auch der Button der Home-Seite sind in dieser Datei definiert!

/// Bibliotheken bzw. Packages importieren
/// Flutter Basics
import 'package:flutter/material.dart';

/// Ermöglicht adaptive Größeneinstellungen
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Import Google Fonts für Schriftarten
import 'package:google_fonts/google_fonts.dart';

/// Stateless Widget / Klasse definieren
class InfoWrapperHome extends StatelessWidget {
  /// Konstruktor mit Parametern (child ist umbedingt notwendig -> required)
  const InfoWrapperHome({super.key, required this.child, this.onInfoTap});

  /// Widget das umhüllt werden soll
  final Widget child;

  /// Callback funktion für den Infobutton
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    // Stack überlagert Widgets
    return Stack(
      children: [
        /// Das "Hintergrund"-Widget (Home-Seite)
        child,
        // 40 Pixel von der oberen Kante des Bildschirms entfernt positioniert
        Positioned(
          top: 40.h,
          right: 0.w,
          // Infobutton "Rufzeichen" erstellen (Farbe und Icon festlegen)
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(199, 203, 203, 255)),

            /// Wenn onInfoTap Information übergebn wurde dann diese nutzen,
            /// wenn nicht Standart-Dialog anzeigen
            onPressed:
                onInfoTap ??
                () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      // Titel des Dialog-Feldes, sowie Farbe und Font festlegen
                      title: Text(
                        'Legende',
                        style: GoogleFonts.openSans(color: const Color.fromARGB(199, 203, 203, 255)),
                      ),
                      content:
                          // ignore: sized_box_for_whitespace (Info ausblenden)
                          // Container für Dialog-Feld mit fester Höhe (aber je nach Bildschirmgröße anders) festlegen
                          // ignore: sized_box_for_whitespace
                          Container(
                            height: 385.h,
                            // Column ordnet Widgets (Legenden-Einträge) vertikal an
                            child: Column(
                              children: [
                                // Erste Zeile der Legende
                                Row(
                                  children: [
                                    // Bild aus Asset-Ordner, Größe definiert
                                    Image.asset('assets/img/mechatronikicon.png', height: 30.h, color: Colors.white),
                                    SizedBox(width: 10.w),
                                    // Text für jeweiliges Bild, Farbe und Font definiert
                                    Text(
                                      'Preset-Muster Mechatronik',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Zweite Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Image.asset('assets/img/flugtechnikicon.png', height: 30.h, color: Colors.white),
                                    SizedBox(width: 10.w),
                                    Text(
                                      'Preset-Muster Flugtechnik',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Dritte Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Image.asset(
                                      'assets/img/werkstofftechnikicon.png',
                                      height: 25.h,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 15.w),
                                    Text(
                                      'Preset-Muster Werkstofft.',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Vierte Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Image.asset('assets/img/maschinenbauicon.png', height: 25.h, color: Colors.white),
                                    SizedBox(width: 15.w),
                                    Text(
                                      'Preset-Muster Maschinenbau',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Fünfte Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'LEDs-Seite (links)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Sechste Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Icon(Icons.brush_outlined, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Zeichen-Seite (rechts)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Siebte Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Icon(Icons.bluetooth, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Verbindungsmenü',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Achte Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Icon(Icons.stop_circle_outlined, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Stopp-Button',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                // Neute Zeile der Legende (gleiches Schema wie 1)
                                Row(
                                  children: [
                                    Icon(Icons.home, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Homing-Button',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      // Hintergrundfarbe der Seite definiert
                      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                    ),
                  );
                },
          ),
        ),
      ],
    );
  }
}
