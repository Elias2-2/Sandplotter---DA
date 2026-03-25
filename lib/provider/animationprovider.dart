/// ============================== Animation Provider ===========================
/// In dieser Datei wurde der Provider für LED-Animationen definiert.
/// Der Provider verwaltet welche Animation auf welcher LED aktiv ist
/// und kommuniziert Änderungen an den Arduino.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';

/// AnimationProvider - State Management für LED-Animationen
///
/// Verwaltet die aktive Animation pro LED (4 LEDs, je 4 Animationen möglich).
///
/// === PROVIDER-PATTERN ===
/// - ChangeNotifier ist die Basisklasse für Provider
/// - notifyListeners() informiert alle zuhörenden Widgets
// ignore: unintended_html_in_doc_comment // Warnung der <> ausblenden
/// - Widgets mit context.watch<AnimationProvider>() werden automatisch neu gebaut
class AnimationProvider extends ChangeNotifier {
  // === ZUSTANDSVARIABLEN ===

  /// Map speichert aktive Animation pro LED
  Map<int, int> animations = {1: 0, 2: 0, 3: 0, 4: 0};

  /// Gibt die aktive Animation für eine LED zurück
  int getledAnimation(int lednumber) {
    return animations[lednumber] ?? 0;
  }

  /// Prüft ob eine bestimmte Animation auf einer LED aktiv ist
  /// Wird von AnimationButton für visuelles Feedback verwendet
  bool isAnimationActive(int led, int animation) {
    return animations[led] == animation;
  }

  /// Setzt oder toggled eine Animation auf einer LED
  ///
  /// Toggle-Logik: Wenn gleiche Animation erneut gedrückt wird -> ausschalten
  /// Bei Animation 2 (Lauflicht) oder 3 (Wellen): Sendet vorher die aktuelle
  /// LED-Farbe an Arduino, damit die Animation die richtige Farbe verwendet
  void setAnimation({required int led, required int animation, required BuildContext context}) {
    // Toggle: Wenn gleiche Animation gedrückt wird -> ausschalten (auf 0 setzen)
    if (animations[led] == animation) {
      animations[led] = 0;
    } else {
      animations[led] = animation;
    }

    // UI über Änderung informieren
    notifyListeners();

    // Bei Animation 2 (Lauflicht), 3 (Wellen) oder 4 (Pulsierend): Farbe vorher senden
    // damit der Arduino die richtige Farbe für die Animation hat
    if (animations[led] == 2 || animations[led] == 3 || animations[led] == 4) {
      final ledProvider = Provider.of<LedColorProvider>(context, listen: false);
      Color currentColor = ledProvider.ledcolor(led);
      Bluetoothsender.sendColor(context, led, currentColor);
      // Kurze Pause damit Arduino die Farbe verarbeiten kann
      Future.delayed(const Duration(milliseconds: 30), () {
        Bluetoothsender.sendAnimation(context, led, animations[led]!);
      });
    } else {
      // Animation an Arduino senden
      Bluetoothsender.sendAnimation(context, led, animations[led]!);
    }
  }

  /// Setzt Animation OHNE an Arduino zu senden
  /// Wird von PresetProvider verwendet um mehrere LEDs gleichzeitig zu setzen
  void setAnimationWithoutSend(int led, int anim) {
    animations[led] = anim;
    notifyListeners();
  }

  /// Setzt alle LEDs auf die gleiche Animation (ohne Senden)
  void setAllAnimationWithoutSend(int anim) {
    for (int i = 1; i <= 4; i++) {
      animations[i] = anim;
    }
    notifyListeners();
  }

  /// Setzt alle Animationen auf 0 (aus) ohne zu senden
  void clearAllAnimationWithoutSend() {
    for (int i = 1; i <= 4; i++) {
      animations[i] = 0;
    }
    notifyListeners();
  }
}
