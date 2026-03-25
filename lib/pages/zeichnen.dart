/// ============================== Zeichnen - Seite =============================
/// In dieser Datei wurde die Zeichnen-Seite definiert.
/// Auf dieser Seite kann man:
/// - Freihand auf der Zeichenfläche zeichnen
/// - Zeichnung an den Sandplotter hochladen
/// - Sand löschen (glätten)
/// - Mit dem Joystick den Plotter manuell steuern
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrapperzeichnen.dart';
import 'package:sandplotter_app/Costum/custombar.dart';
import 'package:sandplotter_app/Costum/drawingarea.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';
import 'package:provider/provider.dart';

class Zeichnen extends StatefulWidget {
  const Zeichnen({required this.controller, required this.onDrawing, super.key});

  // PageController - Steuert die Navigation zwischen LED/Home/Zeichnen-Seiten
  final PageController controller;

  // Callback um PageView-Swipe zu deaktivieren während gezeichnet wird
  // onDrawing(false) = Swipe deaktivieren
  // onDrawing(true) = Swipe aktivieren
  final Function(bool) onDrawing;

  @override
  State<Zeichnen> createState() => _ZeichnenState();
}

class _ZeichnenState extends State<Zeichnen> {
  // === JOYSTICK-VARIABLEN ===

  // Aktuelle Joystick-Position (-1.0 bis 1.0)
  double _joystickX = 0;
  double _joystickY = 0;

  // Zuletzt gesendete Werte (um unnötiges Senden zu vermeiden)
  int _lastSentX = 0;
  int _lastSentY = 0;

  // Timer? - Nullable Timer für periodisches Senden
  Timer? _sendTimer;

  // === KONFIGURATION ===

  // Maximale Geschwindigkeit in Steps pro Sekunde
  final int _maxSpeed = 800;

  // Sende-Intervall in Millisekunden
  // Alle 150ms werden Joystick-Daten gesendet
  final int _sendInterval = 150;

  // === LIFECYCLE-METHODEN ===

  @override
  void initState() {
    super.initState();

    // Timer.periodic - Führt Funktion regelmäßig aus
    // Alle _sendInterval Millisekunden wird _sendJoystickData() aufgerufen
    _sendTimer = Timer.periodic(Duration(milliseconds: _sendInterval), (_) => _sendJoystickData());
  }

  @override
  void dispose() {
    // Timer stoppen um Memory Leak zu vermeiden
    // ?. = Nur aufrufen wenn nicht null (null-safe)
    _sendTimer?.cancel();

    // Motoren stoppen beim Verlassen der Seite
    _stopMotors();

    super.dispose();
  }

  // === JOYSTICK-LOGIK ===

  // Sendet aktuelle Joystick-Position an Arduino
  // Wird periodisch vom Timer aufgerufen (alle 150ms)
  void _sendJoystickData() {
    // Joystick-Position (-1.0 bis 1.0) in Geschwindigkeit umrechnen
    // .round() rundet auf ganze Zahl
    int speedX = (_joystickX * _maxSpeed).round();
    int speedY = (-_joystickY * _maxSpeed).round(); // Y invertiert

    // Optimierung: Nicht senden wenn Joystick in Ruhe UND vorher auch in Ruhe
    // Verhindert unnötige Bluetooth-Nachrichten
    if (speedX == 0 && speedY == 0) {
      if (_lastSentX == 0 && _lastSentY == 0) {
        return; // Nichts senden
      }
    }

    // Letzte Werte speichern für nächsten Vergleich
    _lastSentX = speedX;
    _lastSentY = speedY;

    // Joystick-Daten über Bluetooth senden
    Bluetoothsender.sendJoystick(context, speedX, speedY);
  }

  // Stoppt die Motoren wenn Joystick losgelassen wird
  // Sendet zweimal Stop (0,0) mit kurzem Delay für Sicherheit
  void _stopMotors() {
    Bluetoothsender.sendJoystick(context, 0, 0);

    // Future.delayed - Führt Code nach Verzögerung aus
    // Doppeltes Senden für zuverlässiges Stoppen
    Future.delayed(const Duration(milliseconds: 50), () {
      Bluetoothsender.sendJoystick(context, 0, 0);
    });
  }

  // Callback wenn Joystick bewegt wird
  // details enthält x und y Position (-1.0 bis 1.0)
  void _onJoystickMove(StickDragDetails details) {
    setState(() {
      _joystickX = details.x;
      _joystickY = details.y;
    });
  }

  // Callback wenn Joystick losgelassen wird
  // Setzt Position auf 0 und stoppt Motoren
  void _onJoystickEnd() {
    setState(() {
      _joystickX = 0;
      _joystickY = 0;
    });
    _stopMotors();
  }

  // === BUILD-METHODE ===

  @override
  Widget build(BuildContext context) {
    // Größe für die Balken (gleiche Breite wie DrawingArea)
    final double areaWidth = 300.w;

    // InfoWrapperZeichnen - Zeigt bei Klick auf Info-Button die Legende dieser Seite an
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: InfoWrapperZeichnen(
        // SafeArea - Beachtet System-UI (Statusbar, Uhrzeit, ...)
        child: SafeArea(
          // Scaffold - Grundgerüst für Material Design Seiten
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 25, 25, 25),
            // Custombar - Eigene AppBar mit Seitennavigation
            appBar: Custombar(
              controller: widget.controller,
              iconL: Icons.home, // Links: Home-Seite
              iconR: Icons.lightbulb_outlined, // Rechts: LED-Seite
              pageL: 1, // Seite 1 = Home
              pageR: 0, // Seite 0 = LED
              name: 'Zeichnen',
            ),
            // Hauptinhalt zentriert
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 30.h),
                    // === VERBINDUNGSSTATUS-BALKEN ===
                    Container(
                      height: 40.h,
                      width: areaWidth,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 54, 54, 54),
                        // Nur oben abgerundet
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
                      ),
                      // Consumer - Reagiert auf Bluetooth-Status-Änderungen
                      child: Consumer<Bluetoothprovider>(
                        builder: (context, bt, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon ändert sich je nach Verbindungsstatus
                              Icon(
                                bt.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                                color: bt.isConnected ? Colors.green : Colors.red,
                                size: 20.sp,
                              ),
                              SizedBox(width: 6.w),
                              // Text ändert sich je nach Verbindungsstatus
                              Text(
                                bt.isConnected ? 'Verbunden' : 'Nicht verbunden',
                                style: TextStyle(color: bt.isConnected ? Colors.green : Colors.red, fontSize: 16.sp),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // === ZEICHENFLÄCHE ===
                    // DrawingArea - Freihand-Zeichenfläche (definiert in drawingarea.dart)
                    // onDrawing Callback deaktiviert PageView-Swipe während Zeichnen
                    DrawingArea(onDrawing: widget.onDrawing),

                    SizedBox(height: 50.h),

                    // === JOYSTICK ===
                    // GestureDetector fängt das Loslassen ab
                    GestureDetector(
                      onPanEnd: (_) => _onJoystickEnd(),
                      // Joystick Widget aus flutter_joystick Package
                      child: Joystick(
                        // Stick - Der bewegliche Teil in der Mitte
                        stick: JoystickStick(
                          size: 40.w,
                          decoration: JoystickStickDecoration(
                            shadowColor: const Color.fromARGB(199, 203, 203, 255),
                            color: const Color.fromARGB(199, 203, 203, 255),
                          ),
                        ),
                        // Base - Die Grundfläche des Joysticks
                        base: JoystickBase(
                          size: 150.w,
                          decoration: JoystickBaseDecoration(
                            color: const Color.fromARGB(255, 54, 54, 54),
                            drawArrows: false, // Keine Pfeile anzeigen
                            drawMiddleCircle: false, // Kein Mittelkreis
                            drawOuterCircle: false, // Kein Außenkreis
                          ),
                        ),
                        // JoystickMode.all - Bewegung in alle Richtungen
                        mode: JoystickMode.all,
                        // Callback bei Bewegung
                        listener: _onJoystickMove,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
