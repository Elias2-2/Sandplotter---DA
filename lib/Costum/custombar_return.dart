///==================== Costumbar-Return ======================
/// Hier ist die Appbar mit Return funktion definiert.
/// Sie wird in allenmöglichen Seiten angewandt
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustombarReturn extends StatelessWidget implements PreferredSizeWidget {
  CustombarReturn(this.name, {super.key});

  // Name der Seite (Titel der Appbar)
  final String name;
  // Höhe der Appbar
  final double hoehe = 45.h;

  @override
  Size get preferredSize => Size.fromHeight(hoehe);

  @override
  Widget build(BuildContext context) {
    // Appbar definiert
    return AppBar(
      // Titel der Appbar definiert, Design definiert
      title: Text(
        name,
        style: GoogleFonts.openSans(
          color: const Color.fromARGB(199, 203, 203, 255),
          fontWeight: FontWeight.bold,
          fontSize: 16.h,
        ),
      ),
      // "Zurück"-Button definiert
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: const Color.fromARGB(199, 203, 203, 255), size: 20.h),
        // Wenn gedrückt - Seite schließen
        onPressed: () => Navigator.of(context).pop(),
      ),
      toolbarHeight: 40.h,
      backgroundColor: const Color.fromARGB(255, 54, 54, 54),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
      ),
    );
  }
}
