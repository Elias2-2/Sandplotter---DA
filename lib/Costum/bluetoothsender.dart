/// ============================== Bluetooth Sender ==============================
/// In dieser Datei wurde die Bluetooth-Kommunikation mit dem Arduino definiert.
/// Der Sender verwaltet alle Befehle die an den Sandplotter gesendet werden:
/// - LED Farben und Animationen
/// - Motor-Steuerung (Homing, Stop, Joystick)
/// - Muster und Zeichnungen übertragen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';

/// PROTOKOLL:
/// -----------------------------------------
/// Farbe:          C(segment),(RRGGBB)\n    z.B. "C1,FF0000\n"
/// Animation:      A(segment),(anim)\n       z.B. "A2,3\n"
/// Home:           H\n                       → OK:HOMED
/// Joystick:       J(speedX),(speedY)\n
/// Stop:           S\n                       → OK:STOPPED
/// Pfad Start:     P(n)\n                    → OK:READY
/// Pfad Punkt:     (x),(y)\n                 → OK:ACK (alle 10 Punkte)
/// Pfad Ende:      END\n                     → OK:PATH_RECEIVED
/// -----------------------------------------
/// Segmente: 1-4
/// Animationen: 0=aus, 1=Regenbogen, 2=Lauflicht, 3=Wellen, 4=Pulsierend

class Bluetoothsender {
  // ============================ KONFIGURATION ============================

  static const int maxRetries = 3;
  static const int responseTimeoutMs = 2000;
  static const int pointsPerAck = 10;

  // ============================ CANCEL MECHANISMUS ============================

  static bool _cancelRequested = false;

  /// Fordert Abbruch des laufenden Uploads an
  static void requestCancel() {
    _cancelRequested = true;
  }

  /// Setzt Abbruch-Flag zurück (vor neuem Upload aufrufen)
  static void resetCancel() {
    _cancelRequested = false;
  }

  static bool get isCancelRequested => _cancelRequested;

  // ============================ LED FUNKTIONEN ============================

  /// Sendet Farbe für ein LED-Segment (1-4)
  static Future<bool> sendColor(BuildContext context, int segment, Color color) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    String hexColor = _colorToHex(color);
    String dataString = "C$segment,$hexColor\n";

    return await bluetoothprovider.sendData(dataString);
  }

  /// Sendet Animation für ein LED-Segment (1-4)
  static Future<bool> sendAnimation(BuildContext context, int segment, int animation) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    String dataString = "A$segment,$animation\n";

    return await bluetoothprovider.sendData(dataString);
  }

  /// Sendet Farbe und Animation zusammen (für Presets)
  static Future<bool> sendColorAndAnimation(BuildContext context, int segment, Color color, int animation) async {
    bool colorSent = await sendColor(context, segment, color);
    await Future.delayed(const Duration(milliseconds: 50));
    bool animSent = await sendAnimation(context, segment, animation);
    return colorSent && animSent;
  }

  // ============================ MOTOR FUNKTIONEN ============================

  /// Notfall-Stop - sendet mehrfach für Zuverlässigkeit
  /// Gibt immer true zurück da Arduino trotzdem stoppt
  static Future<bool> stop(BuildContext context) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    // Laufende Uploads abbrechen
    requestCancel();

    bool received = false;
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    // Listener für OK:STOPPED
    void Function(String)? originalCallback = bluetoothprovider.onMessageReceived;

    void stopListener(String message) {
      originalCallback?.call(message);

      if (message.contains('OK:STOPPED')) {
        received = true;
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    }

    bluetoothprovider.onMessageReceived = stopListener;

    // Stop-Befehl 3x senden
    for (int i = 0; i < 3; i++) {
      if (received) break;
      await bluetoothprovider.sendData("S\n");
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Timeout
    timeoutTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!completer.isCompleted) {
        completer.complete(received);
      }
    });

    await completer.future;

    // Callback zurücksetzen
    bluetoothprovider.onMessageReceived = originalCallback;

    // Immer true - Arduino stoppt auch ohne Bestätigung
    return true;
  }

  /// Startet Homing beider Achsen
  static Future<bool> homeAll(BuildContext context) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    // Cancel-Flag zurücksetzen für neue Aktion
    resetCancel();

    return await bluetoothprovider.sendData("H\n");
  }

  /// Sendet Joystick-Geschwindigkeiten (ohne Bestätigung)
  static Future<bool> sendJoystick(BuildContext context, int speedX, int speedY) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    String dataString = "J$speedX,$speedY\n";
    return await bluetoothprovider.sendData(dataString);
  }

  // ============================ MUSTER FUNKTIONEN ============================

  /// Sendet vorgefertigtes Muster (M, F, W, B)
  static Future<bool> sendPresetMuster(BuildContext context, String musterCode) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    // Cancel-Flag zurücksetzen für neue Aktion
    resetCancel();

    String data = "$musterCode\n";
    return await bluetoothprovider.sendData(data);
  }

  /// Sendet Lösch-Befehl (Spirale zum Sand glätten)
  static Future<bool> sendClear(BuildContext context) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    // Cancel-Flag zurücksetzen für neue Aktion
    resetCancel();

    return await bluetoothprovider.sendData("X\n");
  }

  /// Sendet selbst gezeichnetes Muster als Pfad
  static Future<bool> sendDrawing(BuildContext context, List<Map<String, int>?> coordinates) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    resetCancel();

    // Null-Werte filtern
    List<Map<String, int>> validPoints = coordinates.where((p) => p != null).cast<Map<String, int>>().toList();

    if (validPoints.isEmpty) {
      return false;
    }

    int totalPoints = validPoints.length;

    // 1. Punktanzahl senden, auf OK:READY warten
    bool ready = await _sendWithRetry(bluetoothprovider, "P$totalPoints\n", "OK:READY", maxRetries: 3, timeoutMs: 5000);

    if (!ready || _cancelRequested) {
      return false;
    }

    // 2. Alle Punkte senden
    for (int i = 0; i < validPoints.length; i++) {
      if (_cancelRequested || !bluetoothprovider.isReady) {
        return false;
      }

      int x = validPoints[i]['x']!;
      int y = validPoints[i]['y']!;

      String pointData = "$x,$y\n";
      bool sent = await bluetoothprovider.sendData(pointData);

      if (!sent) {
        await Future.delayed(const Duration(milliseconds: 50));
        sent = await bluetoothprovider.sendData(pointData);
        if (!sent) {
          return false;
        }
      }

      // Pause für Bluetooth-Stabilität
      await Future.delayed(const Duration(milliseconds: 15));

      // Längere Pause alle X Punkte
      if ((i + 1) % pointsPerAck == 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // 3. END-Marker senden
    await bluetoothprovider.sendData("END\n");
    await Future.delayed(const Duration(milliseconds: 200));

    return true;
  }

  /// Fährt zu absoluter Position
  static Future<bool> sendMove(BuildContext context, int x, int y) async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      return false;
    }

    String data = "G$x,$y\n";
    return await bluetoothprovider.sendData(data);
  }

  // ============================ HILFSFUNKTIONEN ============================

  /// Sendet Befehl mit Retry bis Antwort kommt
  static Future<bool> _sendWithRetry(
    Bluetoothprovider provider,
    String command,
    String expectedResponse, {
    int maxRetries = 3,
    int timeoutMs = 2000,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      if (_cancelRequested) {
        return false;
      }

      await provider.sendData(command);

      bool success = await _waitForResponse(provider, expectedResponse, timeoutMs: timeoutMs);

      if (success) {
        return true;
      }

      await Future.delayed(const Duration(milliseconds: 200));
    }

    return false;
  }

  /// Wartet auf bestimmte Antwort vom Arduino
  static Future<bool> _waitForResponse(
    Bluetoothprovider provider,
    String expectedResponse, {
    int timeoutMs = 2000,
  }) async {
    final completer = Completer<bool>();
    Timer? timeoutTimer;

    void Function(String)? previousCallback = provider.onMessageReceived;

    provider.onMessageReceived = (message) {
      previousCallback?.call(message);

      if (message.contains(expectedResponse)) {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    };

    timeoutTimer = Timer(Duration(milliseconds: timeoutMs), () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    bool result = await completer.future;

    provider.onMessageReceived = previousCallback;

    return result;
  }

  /// Konvertiert Color zu HEX-String (RRGGBB)
  static String _colorToHex(Color color) {
    int r = (color.r * 255).round();
    int g = (color.g * 255).round();
    int b = (color.b * 255).round();
    return '${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }
}
