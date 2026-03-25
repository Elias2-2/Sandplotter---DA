/// ============================== Preset Provider ==============================
/// In dieser Datei wurde der Provider für LED-Presets definiert.
/// Der Provider verwaltet vordefinierte Farbkombinationen und Animationen
/// die mit einem Knopfdruck aktiviert werden können.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';
import 'package:sandplotter_app/provider/animationprovider.dart';

// Speichert Farben und Animationen für alle 4 LEDs
class PresetData {
  final Map<int, Color> ledColors;
  final Map<int, int> ledAnimations;

  // const Constructor für unveränderliche Presets
  const PresetData({required this.ledColors, required this.ledAnimations});
}

class PresetProvider extends ChangeNotifier {
  // Aktuell aktives Preset (0 = keins, 1-4 = Preset)
  int activePreset = 0;

  static const Map<int, PresetData> presets = {
    // === PRESET 1: Regenbogen ===
    1: PresetData(
      ledColors: {
        1: Color.fromARGB(255, 255, 0, 0), // Rot
        2: Color.fromARGB(255, 5, 156, 5), // Grün
        3: Color.fromARGB(255, 0, 0, 255), // Blau
        4: Color.fromARGB(255, 204, 255, 0), // Gelb-Grün
      },
      ledAnimations: {1: 1, 2: 1, 3: 1, 4: 1}, // Animation 1
    ),

    // === PRESET 2: Lauflicht ===
    2: PresetData(
      ledColors: {
        1: Color.fromARGB(255, 203, 203, 255),
        2: Color.fromARGB(255, 203, 203, 255),
        3: Color.fromARGB(255, 203, 203, 255),
        4: Color.fromARGB(255, 203, 203, 255),
      },
      ledAnimations: {1: 2, 2: 2, 3: 2, 4: 2}, // Animation 2
    ),

    // === PRESET 3: Wellen-Dimmung ===
    3: PresetData(
      ledColors: {
        1: Color.fromARGB(255, 203, 203, 255),
        2: Color.fromARGB(255, 203, 203, 255),
        3: Color.fromARGB(255, 203, 203, 255),
        4: Color.fromARGB(255, 203, 203, 255),
      },
      ledAnimations: {1: 3, 2: 3, 3: 3, 4: 3}, // Animation 3
    ),

    // === PRESET 4: LEDs Aus ===
    4: PresetData(
      ledColors: {
        1: Color.fromARGB(255, 0, 0, 0), // Schwarz
        2: Color.fromARGB(255, 0, 0, 0),
        3: Color.fromARGB(255, 0, 0, 0),
        4: Color.fromARGB(255, 0, 0, 0),
      },
      ledAnimations: {1: 0, 2: 0, 3: 0, 4: 0}, // Keine Animation
    ),
  };

  // === METHODEN ===

  // Prüft ob ein bestimmtes Preset aktiv ist
  bool isPresetActive(int preset) {
    return activePreset == preset;
  }

  // Aktiviert ein Preset oder deaktiviert es (Toggle)
  Future<void> activatePreset(int preset, BuildContext context) async {
    final ledProvider = Provider.of<LedColorProvider>(context, listen: false);
    final animProvider = Provider.of<AnimationProvider>(context, listen: false);

    // === TOGGLE-LOGIK ===
    // Wenn gleiches Preset nochmal gedrückt -> deaktivieren
    if (activePreset == preset) {
      activePreset = 0;
      notifyListeners();

      // Alle LEDs auf Standard zurücksetzen
      for (int led = 1; led <= 4; led++) {
        ledProvider.setLedColorWithoutSend(led, const Color.fromARGB(255, 10, 10, 255));
        animProvider.setAnimationWithoutSend(led, 0);

        await Bluetoothsender.sendAnimation(context, led, 0);
        await Bluetoothsender.sendColor(context, led, const Color.fromARGB(255, 0, 0, 0));
      }
      return;
    }

    // === PRESET AKTIVIEREN ===
    activePreset = preset;
    notifyListeners();

    PresetData? data = presets[preset];
    if (data == null) return;

    // Für alle 4 LEDs: Farbe und Animation setzen
    for (int led = 1; led <= 4; led++) {
      Color ledColor = data.ledColors[led] ?? const Color.fromARGB(255, 203, 203, 255);
      int ledAnim = data.ledAnimations[led] ?? 0;

      // Lokal setzen
      ledProvider.setLedColorWithoutSend(led, ledColor);
      animProvider.setAnimationWithoutSend(led, ledAnim);

      // An Arduino senden
      await Bluetoothsender.sendColor(context, led, ledColor);
      await Bluetoothsender.sendAnimation(context, led, ledAnim);
    }
  }
}
