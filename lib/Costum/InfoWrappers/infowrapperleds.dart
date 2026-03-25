///==================== Info Wrapper LEDs ======================
/// Infowrapper ist das Informationsmenü, welches mit dem "Rufzeichen"-Knop in der rechten
/// oberen Ecke geöffnet werden kann.
/// Das Menü als auch der Button der Leds-Seiten sind in dieser Datei definiert!
/// Da das Schema bei allen Info-Wrapper gleich ist, wurde nur die "infowrapperhome.dart"-Datei auskommentiert.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoWrapperLeds extends StatelessWidget {
  const InfoWrapperLeds({super.key, required this.child, this.onInfoTap});

  final Widget child;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 40.h,
          right: 0.w,
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Color.fromARGB(199, 203, 203, 255)),
            onPressed:
                onInfoTap ??
                () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                        'Legende',
                        style: GoogleFonts.openSans(color: const Color.fromARGB(199, 203, 203, 255)),
                      ),
                      content:
                          // ignore: sized_box_for_whitespace
                          Container(
                            height: 130.h,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.brush_outlined, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Zeichen-Seite (links)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.home, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Home-Seite (rechts)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.flare, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'LED-Presets',
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
