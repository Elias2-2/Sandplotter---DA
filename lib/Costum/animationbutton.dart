///==================== Animation Button ======================
/// In dieser Datei wurde ein Widget für alle "Animatuion"-Buttons in der App definiert!
/// Dies Buttons findet man auf den LEDs-Seiten und sind für die Auswahl der Animationen des jeweiligen Led-Segments
/// zuständig.
///
/// Es wurden alle benötigten Bibliotheken bzw. Packages importiert.
/// Basics für Flutter
import 'package:flutter/material.dart';
// Package für adaptive Größeneinstellungen
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Management der Provider
import 'package:provider/provider.dart';
// Importieren der Datei in der die Led-Animations-Logik programmiert ist
import 'package:sandplotter_app/provider/animationprovider.dart';

/// Klasse als StatelessWidget definiert, da sich der Zustand hier nicht ändert.
/// Alle veränderbaren Parameter werden extern im "Animationprovider" verwaltet.
class AnimationButton extends StatelessWidget {
  // Konstruktor mit erforderlichen Parametern
  const AnimationButton({
    required this.number, // Animation-Nummer
    required this.lednumber, // Led-Nummer
    super.key,
  });

  final int number; // Index für Animation-Nummer
  final int lednumber; // Index für Led-Nummer, Led der eine Animation zugeordnet wird

  @override
  Widget build(BuildContext context) {
    // Prüft ob die ausgewählte Aniamtion bereits bei dieser LED aktiv ist (passiert im Provider)
    // watch() bewirkt einen Rebuild (neu laden) bei Änderung im Provider
    bool isAktiv = context.watch<AnimationProvider>().isAnimationActive(lednumber, number);

    return ElevatedButton(
      // Bei einem Klick wird die Animation aktiviert (passiert im Provider / wird an Provider übergeben)
      onPressed: () {
        // read() triggerd keinen Rebuild - liest also nur aus
        context.read<AnimationProvider>().setAnimation(led: lednumber, animation: number, context: context);
      },
      // Button Style definiert, Button ist farblich hervorgehoben wenn Aniamtion aktiv ist
      // Größe, Radizs und Farbe des Buttons definiert
      style: ElevatedButton.styleFrom(
        backgroundColor: isAktiv ? const Color.fromARGB(199, 203, 203, 255) : const Color.fromARGB(255, 54, 54, 54),
        minimumSize: Size(125.w, 90.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      // Icon auf dem Button definiert.
      // Farbe wird, sollte die Animation aktiv sein, geändert
      // Größe definiert
      child: Icon(
        Icons.animation, // Animations Icon
        size: 65.h, // adaptive Größe
        color: isAktiv
            ? const Color.fromARGB(255, 54, 54, 54)
            : const Color.fromARGB(199, 203, 203, 255), // Farbeinstellungen
      ),
    );
  }
}
