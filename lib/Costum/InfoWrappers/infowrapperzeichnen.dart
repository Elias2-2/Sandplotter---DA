///==================== Info Wrapper Zeichnen ======================
/// Infowrapper ist das Informationsmenü, welches mit dem "Rufzeichen"-Knop in der rechten
/// oberen Ecke geöffnet werden kann.
/// Das Menü als auch der Button der Zeichnen-Seite sind in dieser Datei definiert!
/// Da das Schema bei allen Info-Wrapper gleich ist, wurde nur die "infowrapperhome.dart"-Datei auskommentiert.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoWrapperZeichnen extends StatelessWidget {
  const InfoWrapperZeichnen({super.key, required this.child, this.onInfoTap});

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
                            height: 240.h,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.home, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Home-Seite (links)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline_rounded, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'LEDs-Seite (rechts)',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.upload, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Muster-Upload, \nPlotter zeichnet das Muster',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 1.h,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Icon(Icons.delete, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Cleared die \nZeichenfläche des Plotters',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 1.h,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Icon(Icons.stop_circle_outlined, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Stopp-Button',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 1.h,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Icon(Icons.cancel, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Cleared die \nZeichenfläche der App',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 1.h,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
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
