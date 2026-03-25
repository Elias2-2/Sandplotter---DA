/// ============================== Bluetooth Provider ===========================
/// In dieser Datei wurde der Provider für die Bluetooth-Kommunikation definiert.
/// Der Provider verwaltet die BLE-Verbindung zum HM-10 Modul des Sandplotters
/// und ermöglicht das Senden und Empfangen von Daten.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class Bluetoothprovider extends ChangeNotifier {
  // Das aktuell verbundene Bluetooth-Gerät (null wenn nicht verbunden)
  BluetoothDevice? _connectedDevice;

  // Die TX Characteristic zum Senden von Daten
  // Characteristics sind BLE-Endpunkte für Datenaustausch
  BluetoothCharacteristic? _txCharacteristics;

  // Status ob gerade Daten gesendet werden (verhindert paralleles Senden)
  bool _isSending = false;

  // StreamSubscription für eingehende Nachrichten
  StreamSubscription? _notifySubscription;

  // Buffer für mehrzeilige Nachrichten (können aufgeteilt ankommen)
  String _receivedBuffer = "";

  // Callback-Funktion die bei empfangenen Nachrichten aufgerufen wird
  Function(String)? onMessageReceived;

  // Gibt an ob der Sandplotter gehomed wurde (Referenzfahrt abgeschlossen)
  bool _isHomed = false;
  bool get isHomed => _isHomed;

  // Service UUID des HM-10 Moduls (FFE0 ist Standard)
  static const String SERVICE_UUID = "0000FFE0-0000-1000-8000-00805F9B34FB";

  // Characteristic UUID für Datenübertragung (FFE1 ist Standard)
  static const String CHARACTERISTIC_UUID = "0000FFE1-0000-1000-8000-00805F9B34FB";

  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothCharacteristic? get txCharacteristic => _txCharacteristics;
  bool get isConnected => _connectedDevice != null;
  bool get isReady => _connectedDevice != null && _txCharacteristics != null;
  bool get isSending => _isSending;

  // Setzt das verbundene Gerät und resettet Homing-Status
  void setConnectedDevice(BluetoothDevice? device) {
    _connectedDevice = device;
    _isHomed = false; // Reset bei neuer Verbindung
    notifyListeners();
  }

  void setTxCharacteristic(BluetoothCharacteristic? characteristic) {
    _txCharacteristics = characteristic;
    notifyListeners();
  }

  void setHomed(bool homed) {
    _isHomed = homed;
    notifyListeners();
  }

  // Sucht nach dem HM-10 Service und aktiviert Notifications
  Future<void> discoverSetCharacteristics() async {
    if (_connectedDevice == null) {
      // DEBUG: print('Kein Gerät verbunden');
      return;
    }

    try {
      // DEBUG: print('Starte Service Discovery');

      // Alle Services des Geräts entdecken
      List<BluetoothService> services = await _connectedDevice!.discoverServices();

      // Alle Services durchschauen
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toUpperCase();
        // DEBUG: print('Service gefunden: ${service.uuid}');

        // Suche nach HM-10 Service (enthält "FFE0")
        if (serviceUuid.contains('FFE0')) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase();
            /* DEBUG: print('Characteristic gefunden: $charUuid');
            print(
              '    Properties: read=${characteristic.properties.read}, '
              'write=${characteristic.properties.write}, '
              'writeNoResp=${characteristic.properties.writeWithoutResponse}, '
              'notify=${characteristic.properties.notify}',
            );*/

            // Suche nach TX Characteristic (enthält "FFE1")
            if (charUuid.contains('FFE1')) {
              _txCharacteristics = characteristic;
              // DEBUG: print('TX Characteristic gesetzt!');

              // Notifications aktivieren um Nachrichten zu empfangen
              await _enableNotifications(characteristic);

              notifyListeners();
              return;
            }
          }
        }
      }

      // DEBUG: print('HM-10 Characteristic nicht gefunden!');
      // DEBUG: print(' Verfügbare Services:');
      /* DEBUG:for (var service in services) {
        print(' -${{service.uuid}}');
      }*/
    } catch (e) {
      // DEBUG: print('Fehler beim Discover: $e');
    }
  }

  // === NOTIFICATIONS ===

  // Aktiviert Notifications für eine Characteristic (zum Empfangen)
  Future<void> _enableNotifications(BluetoothCharacteristic characteristic) async {
    try {
      // Alte Subscription beenden falls vorhanden
      await _notifySubscription?.cancel();

      // Notifications auf der Characteristic aktivieren
      await characteristic.setNotifyValue(true);
      // DEBUG: print('Notifications aktiviert');

      // Listener für eingehende Daten registrieren
      _notifySubscription = characteristic.onValueReceived.listen((value) {
        // Bytes in String umwandeln
        String received = String.fromCharCodes(value);
        // DEBUG: print('Empfangen: $received');

        // Buffer für mehrzeilige Nachrichten
        _receivedBuffer += received;

        // Prüfe auf komplette Nachricht (endet mit \n)
        while (_receivedBuffer.contains('\n')) {
          int index = _receivedBuffer.indexOf('\n');
          String message = _receivedBuffer.substring(0, index).trim();
          _receivedBuffer = _receivedBuffer.substring(index + 1);

          if (message.isNotEmpty) {
            _processMessage(message);
          }
        }
      });
    } catch (e) {
      // DEBUG: print('Fehler beim Aktivieren der Notifications: $e');
    }
  }

  // Verarbeitet eine empfangene Nachricht
  void _processMessage(String message) {
    // DEBUG: print('Nachricht verarbeitet: $message');

    // Status-Updates direkt im Provider verarbeiten
    if (message == 'OK:HOMED') {
      _isHomed = true;
      notifyListeners();
    }

    // Callback aufrufen falls gesetzt
    if (onMessageReceived != null) {
      onMessageReceived!(message);
    }
  }

  // === VERBINDUNG TRENNEN ===

  // Trennt die Bluetooth-Verbindung und räumt auf
  void disconnect() {
    _notifySubscription?.cancel();
    _notifySubscription = null;

    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }

    _connectedDevice = null;
    _txCharacteristics = null;
    _isHomed = false;
    _receivedBuffer = "";
    notifyListeners();
  }

  // === DATEN SENDEN ===

  // Sendet Daten über Bluetooth an den Arduino
  // BLE hat ein Limit von ~20 Bytes pro Paket, längere Daten werden aufgeteilt
  Future<bool> sendData(String data) async {
    if (_txCharacteristics == null) {
      // DEBUG: print('Keine Verbindung um Daten zu senden');
      return false;
    }

    if (_connectedDevice == null) {
      // DEBUG: print('Kein Gerät verbunden');
      return false;
    }

    // Verhindere paralleles Senden
    if (_isSending) {
      // DEBUG: print('Sende bereits Daten, warte');
      return false;
    }

    _isSending = true;

    try {
      // String in Bytes umwandeln
      List<int> bytes = data.codeUnits;
      // DEBUG: print('Senden: $data');
      // DEBUG: print('Länge: ${bytes.length} Bytes');

      // BLE Paket-Limit
      const int maxChunkSize = 20;

      // Daten in Pakete aufteilen
      for (int i = 0; i < bytes.length; i += maxChunkSize) {
        int end = (i + maxChunkSize < bytes.length) ? i + maxChunkSize : bytes.length;
        List<int> chunk = bytes.sublist(i, end);

        // Versuche mit Response zu senden (zuverlässiger)
        try {
          await _txCharacteristics!.write(chunk, withoutResponse: false);
        } catch (e) {
          // Fallback: Ohne Response senden
          await _txCharacteristics!.write(chunk, withoutResponse: true);
        }

        // Kleine Verzögerung zwischen Paketen
        if (i + maxChunkSize < bytes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // DEBUG: print('✓ Alle Daten erfolgreich gesendet');
      _isSending = false;
      return true;
    } catch (e) {
      // DEBUG: print('✗ Fehler beim Senden: $e');
      _isSending = false;

      // Prüfe ob Verbindung noch besteht
      try {
        var state = await _connectedDevice!.connectionState.first;
        if (state != BluetoothConnectionState.connected) {
          // DEBUG: print('Verbindung verloren - zurücksetzen');
          _connectedDevice = null;
          _txCharacteristics = null;
          _isHomed = false;
          notifyListeners();
        }
      } catch (_) {}

      return false;
    }
  }

  // Testet die Bluetooth-Verbindung
  Future<bool> testConnection() async {
    if (!isReady) return false;

    try {
      return await sendData("TEST\n");
    } catch (e) {
      // DEBUG: print('✗ Verbindungstest fehlgeschlagen: $e');
      return false;
    }
  }
}
