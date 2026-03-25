import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:fluttertoast/fluttertoast.dart';

///==================== App Toast ======================
/// Toast Helper - Einheitliche Toast-Nachrichten für die App
///
/// In dieser Datei werden alle möglichen Pop-up (Toast) Nachrichten für die App definiert
/// So müssen sie dann nur an den entsprechenden Punkten in der App aufgerufen werden
///
/// Verwendung:
///   AppToast.success('Homing erfolgreich!');
///   AppToast.error('Verbindung fehlgeschlagen');
///   AppToast.warning('Bluetooth nicht verbunden!');
///   AppToast.info('Muster wird gezeichnet...');
class AppToast {
  // App Farben definiert
  static const Color _appColor = Color.fromARGB(199, 203, 203, 255);
  static const Color _backgroundColor = Color.fromARGB(255, 45, 45, 45);

  /// Erfolgs-Toast (grün)
  /// Hier sind alle postivien Pop-Up Meldungen definiert
  static void success(String message) {
    Fluttertoast.showToast(
      msg: message, // Darzustellende Message
      toastLength: Toast.LENGTH_SHORT, // Anzeigedauer der Nachricht (LENGHT_SHORT = ca. 2s)
      gravity: ToastGravity.BOTTOM, // Positionierung am unteren Bilschirmrand
      backgroundColor: const Color.fromARGB(230, 76, 175, 80), // Hintergrundfarbe der Nachricht (grün)
      textColor: Colors.white, // Farbe des Textes
      fontSize: 14.0, // Schriftgröße der Nachricht
    );
  }

  /// Fehler-Toast (rot)
  /// Hier sind alle negativen Pop-Up Meldungen definiert
  static void error(String message) {
    Fluttertoast.showToast(
      msg: message, // Darzustellende Nachricht
      toastLength: Toast.LENGTH_LONG, // Anzeigedauer der Nachricht (LENGTH_LONG = ca. 3,5s)
      gravity: ToastGravity.BOTTOM, // Positionierung am unteren Bildschirmrand
      backgroundColor: const Color.fromARGB(230, 244, 67, 54), // Hintergrundfarbe der Nachticht (rot)
      textColor: Colors.white, // Farbe des Textes
      fontSize: 14.0, // Schriftgröße der Nachricht
    );
  }

  /// Warnung-Toast (orange)
  /// Hier sind alle warnenden Pop-Up Meldungen definiert
  static void warning(String message) {
    Fluttertoast.showToast(
      msg: message, // Darzustellende Nachricht
      toastLength: Toast.LENGTH_SHORT, // Anzeigedauer
      gravity: ToastGravity.BOTTOM, // Ausrichtung / Positionierung
      backgroundColor: const Color.fromARGB(230, 255, 152, 0), // Hintergrundfarbe der Nachricht (orange)
      textColor: Colors.white, // Farbe des Textes
      fontSize: 14.0, // Schriftgröße des Textex
    );
  }

  /// Info-Toast (App-Farbe)
  /// Hier sind alle Info Pop-Up Nachrichten definiert
  /// Der Auffbau ist bei allen Pop-Ups gleich, deshalb wurde ab hier nicht mehr alles auskommentiert
  static void info(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _backgroundColor,
      textColor: _appColor,
      fontSize: 14.0,
    );
  }

  /// Benutzerdefinierter Toast
  /// Pop-Ups mit einstellbarer Farbe, Nachricht, etc.
  static void custom(
    String message, {
    Color backgroundColor = _backgroundColor,
    Color textColor = Colors.white,
    Toast length = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 14.0,
    );
  }

  /// Toast abbrechen
  /// Bricht die Pop-Up Nachricht ab
  /// Wird benötigt, sollte eine wichtigere Nachticht angezeigt werden müssen
  static void cancel() {
    Fluttertoast.cancel();
  }
}
