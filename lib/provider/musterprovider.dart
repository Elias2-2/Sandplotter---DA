/// ============================== Muster Provider ==============================
///
/// Der Provider verwaltet den Status von ALLEN Operationen:
/// - Hochladen von Mustern
/// - Zeichnung übertragen
/// - Sand löschen (glätten)
/// - Homing (Referenzfahrt)
/// - Stop-Befehl
///
/// Die UI-Widgets lesen NUR aus dem Provider
import 'package:flutter/material.dart';
import 'dart:async';

enum MusterStatus {
  idle, // Nichts aktiv - bereit für neue Aktion
  uploading, // Muster/Zeichnung wird hochgeladen
  clearing, // Sand wird gelöscht (Spiralmuster)
  homing, // Homing (Referenzfahrt) läuft
  stopping, // Stop-Befehl wird ausgeführt
}

class MusterProvider extends ChangeNotifier {
  // ===========================================================================
  // STATUS VARIABLEN (GLOBAL - ÜBERLEBEN SEITENWECHSEL)
  // ===========================================================================

  // Aktueller Status der Operation
  MusterStatus _status = MusterStatus.idle;
  MusterStatus get status => _status;

  // Welches Muster wird gerade ausgeführt
  // 0 = keins, 1-4 = vorgefertigte Muster, 5 = selbst gezeichnet
  int _activeMuster = 0;
  int get activeMuster => _activeMuster;

  // Status-Text für UI-Anzeige (z.B. "Übertrage Daten...", "Plotter zeichnet...")
  String _statusText = '';
  String get statusText => _statusText;

  // Completer für asynchrones Warten auf Arduino-Antwort
  Completer<void>? _actionCompleter;

  // Callback der aufgerufen wird wenn Aktion abgebrochen wird
  Function()? onCancelled;

  // ===========================================================================
  // GETTER FÜR UI
  // ===========================================================================

  /// Prüft ob System bereit für neue Aktion ist
  bool get isIdle => _status == MusterStatus.idle;

  /// Prüft ob irgendeine Operation läuft
  bool get isBusy => _status != MusterStatus.idle;

  /// Prüft ob Homing läuft
  bool get isHoming => _status == MusterStatus.homing;

  /// Prüft ob Upload läuft (Muster oder Zeichnung)
  bool get isUploading => _status == MusterStatus.uploading;

  /// Prüft ob Sand-Löschen läuft
  bool get isClearing => _status == MusterStatus.clearing;

  /// Prüft ob Stop-Befehl ausgeführt wird
  bool get isStopping => _status == MusterStatus.stopping;

  /// Für Buttons: Kann Hochladen gestartet werden?
  bool get canUpload => _status == MusterStatus.idle;

  /// Für Buttons: Kann Löschen gestartet werden?
  bool get canClear => _status == MusterStatus.idle || _status == MusterStatus.uploading;

  // ===========================================================================
  // ZEICHNUNG VERWALTEN
  // ===========================================================================

  // Liste der gezeichneten Punkte (null = Stift abgehoben = Linienende)
  final List<Offset?> _drawnPoints = [];
  List<Offset?> get drawnPoints => _drawnPoints;

  void addPoint(Offset point) {
    _drawnPoints.add(point);
    notifyListeners();
  }

  void endLine() {
    _drawnPoints.add(null);
    notifyListeners();
  }

  void clearDrawing() {
    _drawnPoints.clear();
    notifyListeners();
  }

  List<Map<String, int>?> getCoordinates(int maxSteps) {
    return _drawnPoints.map((point) {
      if (point == null) return null;
      return {'x': (point.dx * maxSteps).round(), 'y': (point.dy * maxSteps).round()};
    }).toList();
  }

  // ===========================================================================
  // STATUS SETZEN (INTERN)
  // ===========================================================================

  void _setStatus(MusterStatus newStatus, {String text = ''}) {
    _status = newStatus;
    _statusText = text;
    notifyListeners();
  }

  void setStatusText(String text) {
    _statusText = text;
    notifyListeners();
  }

  // ===========================================================================
  // AKTIONEN STARTEN
  // ===========================================================================

  /// Prüft ob eine neue Aktion den aktuellen Vorgang unterbrechen kann
  bool canInterruptWith(MusterStatus newStatus) {
    if (_status == MusterStatus.idle) return true;
    if (_status == MusterStatus.stopping) return false; // Stop nicht unterbrechen

    // Homing kann alles abbrechen (Sicherheitsfeature)
    if (newStatus == MusterStatus.homing) return true;

    // Hochladen und Löschen können sich gegenseitig abbrechen
    if (newStatus == MusterStatus.uploading && _status == MusterStatus.clearing) return true;
    if (newStatus == MusterStatus.clearing && _status == MusterStatus.uploading) return true;

    return false;
  }

  /// Bricht den aktuellen Vorgang ab (intern)
  void cancelCurrent() {
    if (_status == MusterStatus.idle) return;

    if (onCancelled != null) {
      onCancelled!();
    }

    if (_actionCompleter != null && !_actionCompleter!.isCompleted) {
      _actionCompleter!.complete();
    }
    _actionCompleter = null;

    _setStatus(MusterStatus.idle);
    _activeMuster = 0;
  }

  /// Startet Stop-Befehl
  Future<bool> startStopping() async {
    _setStatus(MusterStatus.stopping, text: 'Stoppe...');
    return true;
  }

  /// Beendet Stop-Befehl
  void stoppingFinished() {
    if (_status == MusterStatus.stopping) {
      _setStatus(MusterStatus.idle);
      _activeMuster = 0;
    }
  }

  /// Startet Homing (kann jeden anderen Vorgang unterbrechen)
  Future<bool> startHoming() async {
    if (_status != MusterStatus.idle && _status != MusterStatus.stopping) {
      cancelCurrent();
    }

    _setStatus(MusterStatus.homing, text: 'Homing läuft...');
    _actionCompleter = Completer<void>();
    return true;
  }

  /// Startet vorgefertigtes Muster
  Future<bool> startMuster(int musterNummer) async {
    if (!canInterruptWith(MusterStatus.uploading)) {
      return false;
    }

    if (_status != MusterStatus.idle) {
      cancelCurrent();
    }

    _setStatus(MusterStatus.uploading, text: 'Muster wird gestartet...');
    _activeMuster = musterNummer;
    _actionCompleter = Completer<void>();
    return true;
  }

  /// Startet selbst gezeichnetes Muster
  Future<bool> startCustomMuster() async {
    if (!canInterruptWith(MusterStatus.uploading)) {
      return false;
    }
    if (_drawnPoints.isEmpty) return false;

    if (_status != MusterStatus.idle) {
      cancelCurrent();
    }

    _setStatus(MusterStatus.uploading, text: 'Verbinde...');
    _activeMuster = 5; // 5 = custom
    _actionCompleter = Completer<void>();
    return true;
  }

  /// Startet Sand löschen (Spiralmuster)
  Future<bool> startClearing() async {
    if (!canInterruptWith(MusterStatus.clearing)) {
      return false;
    }

    if (_status != MusterStatus.idle) {
      cancelCurrent();
    }

    _setStatus(MusterStatus.clearing, text: 'Sand wird geglättet...');
    _activeMuster = 0;
    _actionCompleter = Completer<void>();
    return true;
  }

  // ===========================================================================
  // ARDUINO-KOMMUNIKATION
  // ===========================================================================

  /// Verarbeitet Nachrichten vom Arduino
  void onArduinoMessage(String message) {
    // DEBUG: print('MusterProvider empfangen: $message');

    if (message == 'OK:HOMED') {
      if (_status == MusterStatus.homing) {
        musterFinished();
      }
    } else if (message == 'OK:MUSTER_DONE' || message == 'OK:PATH_DONE') {
      if (_status == MusterStatus.uploading) {
        musterFinished();
      }
    } else if (message == 'OK:CLEAR_DONE') {
      if (_status == MusterStatus.clearing) {
        musterFinished();
      }
    } else if (message == 'OK:STOPPED') {
      musterFinished();
    } else if (message == 'OK:ACK') {
      // Fortschritt beim Upload
      if (_status == MusterStatus.uploading) {
        setStatusText('Übertrage Daten...');
      }
    } else if (message == 'OK:PATH_RECEIVED') {
      // Alle Daten empfangen - Plotter startet
      if (_status == MusterStatus.uploading) {
        setStatusText('Plotter zeichnet...');
      }
    } else if (message == 'OK:READY') {
      // Arduino bereit für Daten
      if (_status == MusterStatus.uploading) {
        setStatusText('Übertrage Daten...');
      }
    }
  }

  /// Markiert aktuellen Vorgang als beendet
  void musterFinished() {
    _setStatus(MusterStatus.idle);
    _activeMuster = 0;

    if (_actionCompleter != null && !_actionCompleter!.isCompleted) {
      _actionCompleter!.complete();
    }
    _actionCompleter = null;
  }

  /// Beendet Vorgang nach Verzögerung (Fallback falls Arduino nicht antwortet)
  void musterFinishedDelayed(Duration delay) {
    Future.delayed(delay, () {
      if (_status != MusterStatus.idle) {
        musterFinished();
      }
    });
  }

  /// Wartet auf Arduino-Antwort (mit optionalem Timeout)
  Future<void> waitForCompletion({Duration? timeout}) async {
    if (_actionCompleter == null) return;

    if (timeout != null) {
      await _actionCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          musterFinished();
        },
      );
    } else {
      await _actionCompleter!.future;
    }
  }

  // Legacy Methoden für Kompatibilität
  bool get hochladenaktiv => _status == MusterStatus.idle;
  bool get loeschenaktiv => _status == MusterStatus.idle;
  bool get isDrawing => false;

  void setStatus(MusterStatus newStatus) {
    _setStatus(newStatus);
  }

  bool isMusterActive(int musterNummer) {
    return _activeMuster == musterNummer && _status == MusterStatus.uploading;
  }
}
