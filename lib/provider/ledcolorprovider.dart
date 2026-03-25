/// ============================== LED Color Provider ===========================
/// In dieser Datei wurde der Provider für LED-Farben definiert.
/// Der Provider verwaltet die aktuelle Farbe jeder LED
/// und kommuniziert Änderungen an den Arduino.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/provider/animationprovider.dart';

class LedColorProvider extends ChangeNotifier {
  // === ZUSTANDSVARIABLEN ===

  // Map speichert aktuelle Farbe pro LED
  // Key: LED-Nummer (1-4), Value: Color-Objekt
  // Standardfarbe: Blau (10, 10, 255)
  Map<int, Color> leds = {
    1: const Color.fromARGB(255, 10, 10, 255),
    2: const Color.fromARGB(255, 10, 10, 255),
    3: const Color.fromARGB(255, 10, 10, 255),
    4: const Color.fromARGB(255, 10, 10, 255),
  };

  // Gibt die Farbe einer LED zurück
  // ?? = Falls Key nicht existiert, Standardfarbe zurückgeben
  Color ledcolor(int lednumber) {
    return leds[lednumber] ?? const Color.fromARGB(255, 203, 203, 255);
  }

  // Ändert die Farbe einer LED und sendet an Arduino
  // Bei Animation 2 (Lauflicht), 3 (Wellen) oder 4 (Pulsierend): Animation bleibt aktiv,
  // die neue Farbe wird übernommen (Arduino verwendet segments[].color)
  // Bei Animation 1 (Regenbogen): Arduino setzt Animation automatisch auf 0
  void changeledcolor({required int lednumber, required Color ledcolor, required BuildContext context}) {
    // Farbe lokal speichern
    leds[lednumber] = ledcolor;
    notifyListeners();

    final animProvider = Provider.of<AnimationProvider>(context, listen: false);
    int currentAnim = animProvider.getledAnimation(lednumber);

    // Bei Regenbogen (1): Animation in der App auf 0 setzen
    // (Arduino macht das auch automatisch beim Farbe empfangen)
    if (currentAnim == 1) {
      animProvider.setAnimationWithoutSend(lednumber, 0);
    }

    // Farbe an Arduino senden
    // Bei Animation 2/3/4: Arduino speichert die Farbe und die Animation
    // verwendet automatisch die neue Farbe
    Bluetoothsender.sendColor(context, lednumber, ledcolor);
  }

  // Setzt LED-Farbe OHNE an Arduino zu senden
  // Wird von PresetProvider verwendet
  void setLedColorWithoutSend(int lednumber, Color color) {
    leds[lednumber] = color;
    notifyListeners();
  }

  // Setzt alle LEDs auf die gleiche Farbe (ohne Senden)
  void setAllLedsWithoutSend(Color color) {
    for (int i = 1; i <= 4; i++) {
      leds[i] = color;
    }
    notifyListeners();
  }

  // === INITIALISIERUNG ===

  // Initialisiert alle LEDs auf Blau beim App-Start
  // Wird nach erfolgreicher Bluetooth-Verbindung aufgerufen
  Future<void> initializeLeds(BuildContext context) async {
    for (int i = 1; i <= 4; i++) {
      await Bluetoothsender.sendColor(context, i, const Color.fromARGB(255, 10, 10, 255));
      // Kurze Pause zwischen den Sends (30ms)
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }
}
