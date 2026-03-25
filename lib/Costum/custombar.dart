///==================== Custombar======================
/// Hier ist eine Appbar definiert die Links und Rechts Icons, um die Seite zu wechseln, hat
/// Arbeitet mit dem PageView zusammen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Custombar extends StatefulWidget implements PreferredSizeWidget {
  Custombar({
    required this.controller, // PageVIew controller
    required this.iconL, // Icon für die Linke-Seite
    required this.iconR, // Icon für die rechte-Seite
    required this.pageL, // Page die auf der linken Seite aufgerufen
    required this.pageR, // Page die auf der rechten Seite aufgerufen
    required this.name, // Titel der Appbar (Seite)
    super.key,
  });

  final String name;
  final int pageL;
  final int pageR;
  final PageController controller;
  final IconData iconL;
  final IconData iconR;
  // Höhe der Appbar
  final double hoehe = 45.h;

  @override
  Size get preferredSize => Size.fromHeight(hoehe);

  @override
  State<Custombar> createState() => _CustombarState();
}

class _CustombarState extends State<Custombar> {
  @override
  Widget build(BuildContext context) {
    // Appbar erstellt
    return AppBar(
      // Titel der Seite anzeigen
      title: Text(
        widget.name,
        style: GoogleFonts.openSans(
          color: const Color.fromARGB(199, 203, 203, 255),
          fontWeight: FontWeight.bold,
          fontSize: 16.h,
        ),
      ),
      // Button für Seitenwechsel auf der linken Seite
      // mit definierter Animation
      leading: IconButton(
        icon: Icon(widget.iconL, color: const Color.fromARGB(199, 203, 203, 255), size: 20.h),
        onPressed: () {
          widget.controller.animateToPage(
            widget.pageL,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        },
      ),
      actions: [
        // Button für Seitenwechsel auf der rechten Seite
        IconButton(
          icon: Icon(widget.iconR, color: const Color.fromARGB(199, 203, 203, 255), size: 20.h),
          onPressed: () {
            widget.controller.animateToPage(
              widget.pageR,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          },
        ),
      ],
      // Höhe der Appbar und Design definiert
      toolbarHeight: 40.h,
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
      ),
    );
  }
}
