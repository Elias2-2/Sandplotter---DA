///==================== Info Wrapper LED ======================
/// Infowrapper ist das Informationsmenü, welches mit dem "Rufzeichen"-Knop in der rechten
/// oberen Ecke geöffnet werden kann.
/// Das Menü als auch der Button der Led-Seite sind in dieser Datei definiert!
/// Da das Schema bei allen Info-Wrapper gleich ist, wurde nur die "infowrapperhome.dart"-Datei auskommentiert.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoWrapperLed extends StatelessWidget {
  const InfoWrapperLed({super.key, required this.child, this.onInfoTap});

  final Widget child;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 65.h,
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
                            height: 85.h,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_back_ios, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'Zurück',
                                      style: GoogleFonts.openSans(
                                        color: const Color.fromARGB(199, 203, 203, 255),
                                        height: 3.h,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.animation, size: 25.h, color: Colors.white),
                                    SizedBox(width: 16.w),
                                    Text(
                                      'LED-Animationen',
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
