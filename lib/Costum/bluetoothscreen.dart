/// ============================== Bluetooth Screen ==============================
/// In dieser Datei wurde das Bluetoothmenü programmiert.
/// Es soll nach verfügbaren Geräten gescannt werden können,
/// und das passende Gerät soll dann auch ausgewählt weden können.
/// Außerdem werden in dieser Datei alle möglichen Berechtigungen und Eistellungen für eine Bluetoothverbidnung abgefragt
/// bzw. gesetzt.

// Packages und Bibliotheken
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';
import 'package:sandplotter_app/Costum/apptoast.dart';

/// Klassen deklaration
/// Es wurde ein StafulWidget gewählt, da sich lokale Werte ändern (Scanergebisse, Scanstatus, Verbindugsstatus)
class Bluetoothscreen extends StatefulWidget {
  const Bluetoothscreen({super.key});

  @override
  State<Bluetoothscreen> createState() => _BluetoothscreenState();
}

class _BluetoothscreenState extends State<Bluetoothscreen> {
  List<ScanResult> scanResults = []; // Liste der gefundenen Bluetoothgeräte aus dem letzten Scan
  // Wird nach jedem Scan wieder gelehrt damit sie neu befüllt werden kann
  bool isScanning = false; // Zustandvariable des Scandvorganges
  bool isConnected = false; // Zustandvariable des Verbindungstatuses

  /// Wird beim erstellen des Widgets aufgerufen
  /// Dadurch werden alle Berechtigung gleich abgefragt, sobald eine Bleutoothverbindung
  /// aufgebaut werden möchte
  @override
  void initState() {
    super.initState();
    requestPermissions(); // Berechtigungen anfordern
  }

  /// Hier werden alle benötigten Berichtigungen für Andorid abgefragt
  /// Dadurch wird der Benutzer aufgefordert die Berechtigungen auf seinem Mobilgerät für diese App anzupassen
  Future<void> requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  /// =====================================================================
  /// Blutooth Scan Logik
  ///
  /// Startet einen Scan nach verfügbaren Bluetoothgeräten
  ///
  /// Der SCan läuft für 4 Sekunden und sammelt alle gefundenen Geräte
  /// Dies Geräte werden in der "scanResult"-Liste gespeichert. Der User sieht währenddessen einen Loading-Indikator
  ///
  /// Ablauf:
  /// - Alte Ergebnisse löschen, Scan-Status setzen
  /// - BLE-Scan starten
  /// - Ergebnisse empfangen und in Liste speichern
  /// - Nach 4 Sekunden, Scan stoppen, Stauts zurücksetzen
  /// ======================================================================

  // UI-Status aktualisieren
  void startScan() async {
    setState(() {
      scanResults.clear(); // Alte Egebisse verwerfen
      isScanning = true; // Loading-Indikator aktivieren
    });

    try {
      // try: Code der einen Fehler haben könnte
      // Scan startet mit 4 Sekunden timeout
      // Timeout verhindert ein endlossen scannen bei Fehler
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listener für SCan-Ergebnisse registrieren
      // Wird bei jedem neuem Ergebniss aufgerufen
      FlutterBluePlus.scanResults.listen((results) {
        // mounted-Check: Verhindert setState() bei disposed Widgets (sonst Error)
        // sollte also ein Widget bereits gelöscht oder geschlossen worden sein wird dieser Code nicht ausgeführt
        // Wichtig da der Scan asychrone Daten liefert
        if (mounted) {
          setState(() {
            scanResults = results;
          });
        }
      });

      /// Future.delayed() - wartet eine bestimmt Zeit
      /// Der Rest des Codes läuft weiter (nicht blockierend)
      await Future.delayed(const Duration(seconds: 4));

      /// Stoppt den BLE-Scan
      await FlutterBluePlus.stopScan();
      if (mounted) {
        // Mounted checkt ob Dialog noch offen ist
        setState(() {
          isScanning = false;
        });
      }
    } catch (e) {
      // catch: Code der im Fall eines Fehlers ausgeführt wird
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  /// ======================Verbindungs-Management=====================
  /// Bluetooth-Device - Platzhalter für ein gefundenes BLE-Gerät
  /// Properties: platformName: Anzeigename des Geräts
  ///             remoteId: MAC-Adresse / Identifier
  ///
  /// Methoden:   connect(): Verbindung herstellen
  ///             disconnect(): Verdindung trennen
  ///             disoverSerives(): Services und Charakteristicen finden
  void connectToDevice(BluetoothDevice device) async {
    // Holt eine Provider Insranz aus dem Widget-Tree (listen: false - ohne Rebuild bei Änderung)
    final provider = Provider.of<Bluetoothprovider>(context, listen: false);
    setState(() {
      isConnected = true; // Connection-Status auf 1 setzen
    });

    try {
      /// Verbindung herstellen
      /// timeout: Maximale Wartezeit für eine Verbindung
      /// autoConnect: Bei true automatische Verbindung wenn ein Gerät in Rechweite ist
      await device.connect(timeout: const Duration(seconds: 10));

      // Warten auf stabile verbindung (BLE braucht etwas Zeit zum Stabiliseren einer Verbindung)
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Gerät im Provider speichern
        provider.setConnectedDevice(device);

        // Services und Characteristicen entdecken
        await provider.discoverSetCharacteristics();

        /// Null-Check mit != null
        /// In Dart ist "null" ein Wert für "kein Wert"
        /// Characteristics können null sein wenn keine gefunden wurden
        if (provider.txCharacteristic != null && mounted) {
          // LEDs auf hellblau initialisieren und LED-Provier holen
          final ledProvider = Provider.of<LedColorProvider>(context, listen: false);
          await ledProvider.initializeLeds(context);

          // Zeigt erfolgreiche Toest nachricht an
          AppToast.success('Verbunden mit ${device.platformName} - Bereit!');

          // Schließt das Dialog-Fester (Bluetooth-Menü)
          Navigator.of(context).pop();
        } else {
          // Wenn Characteristicen nicht gefunden
          AppToast.warning('Verbunden, aber nicht mit Sandplotter');
        }

        setState(() {
          isConnected = false; // Wenn nicht mit Sandplotter verbunden - Connected auf false
        });
      }
    } catch (e) {
      try {
        // Bei Fehler: Verbindung trennen sollte sie nur teilweise hergestellt worden sein
        await device.disconnect();
      } catch (_) {} // Fängt exeptions

      // Provider zurücksetzen
      provider.setConnectedDevice(null);
      provider.setTxCharacteristic(null);

      if (mounted) {
        setState(() {
          isConnected = false; // Connected auf false, wenn Verbdinung nicht funktioniert
        });

        // Toast- Nachricht wenn Verbingung fehlgeschlagen
        AppToast.error('Verbindung fehlgeschlagen: $e');
      }
    }
  }

  /// Trennt die Bleutooth-Verbindung
  void disconnectDevice() async {
    final provider = Provider.of<Bluetoothprovider>(context, listen: false);

    try {
      provider.disconnect();

      if (mounted) {
        // Toast-Nachricht
        AppToast.warning('Verbindung getrennt');
      }
    } catch (e) {
      // BEUG: print('Disconnect-Fehler: $e'); // nur Debug-Nachricht
    }
  }

  @override
  void dispose() {
    // Wird aufgerufen wenn das Widget zerstört wird (geschlossen)
    FlutterBluePlus.stopScan(); // Stoppt Scan um resourcen freizugeben
    super.dispose(); // Immer am ENde aufrufen
  }

  /// Build-Methode erstellt das Widget (den Widget-Tree)
  /// Wird beim ersten Rendern, nach jedem setState und bei Änderungen in inherited Widgets aufgerufen
  @override
  Widget build(BuildContext context) {
    // Consumer für UI-Updates die sich ändern sollen / können
    // Hier wird nur dieser Teil neu gebaut anstannt alles wie bei Provider.of()
    return Consumer<Bluetoothprovider>(
      builder: (context, bluetoothprovider, child) {
        return PopScope(
          // Kontrolliert verhalten des Back-Buttons
          canPop: true, // Dialog kann geschlossen werden
          child: Dialog(
            // Erstellt ein Dialog-Fenster (Bluetooth-Menü)
            backgroundColor: const Color.fromARGB(255, 35, 35, 35), // Farbe im HEx-Format
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Radius an den Ecken
            child: Container(
              width: 350.w, // Responsive Größeneinstellungen durh Screenutil
              height: 500.h,
              padding: EdgeInsets.all(20.w), // Abstand von Rand auf allen Seiten
              child: Column(
                // Ordnet Widgets vertikal an
                children: [
                  /// Titel-Zeile mit Text
                  /// Farbe, Größe und Font definiert
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bluetooth Geräte',
                        style: TextStyle(
                          color: const Color.fromARGB(199, 203, 203, 255),
                          fontSize: 22.h,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Abstandhalter nach unten
                  SizedBox(height: 10.h),

                  // Verbindungstatus - nur angezeigt wenn verbunden
                  if (bluetoothprovider.connectedDevice != null) ...[
                    /// == Verbunden-Anzeige ==
                    /// Größe, Farbe, Eckradius definiert
                    /// Angezeigt:  Verbunden mit:
                    ///                   Geräte Name
                    ///                   "Characteristics Fehlt" oder "nichts"
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Text: Verbunden mit:
                                // Farbe, Größe definiert
                                Text(
                                  'Verbunden mit:',
                                  style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Geräte-Name anzeigen wenn bekannt sont "Unbekanntes Gerät"
                                    // Farbe, Größe, Font definiert
                                    Text(
                                      bluetoothprovider.connectedDevice!.platformName.isEmpty
                                          ? 'Unbekanntes Gerät'
                                          : bluetoothprovider.connectedDevice!.platformName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Zeige TX Characteristic Status
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      bluetoothprovider.txCharacteristic != null ? Icons.check_circle : Icons.warning,
                                      color: bluetoothprovider.txCharacteristic != null
                                          ? Colors.green
                                          : Colors.redAccent,
                                      size: 14.sp,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      bluetoothprovider.txCharacteristic != null
                                          ? 'TX Characteristic bereit'
                                          : 'TX Characteristic fehlt',
                                      style: TextStyle(
                                        color: bluetoothprovider.txCharacteristic != null
                                            ? Colors.green
                                            : Colors.redAccent,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h), // Abstandhalter
                  ] else ...[
                    /// == Scan Status ==
                    /// Wenn nicht verbunden wird angezeigt wie viele Geräte gefunden wurden
                    /// Wenn gescannt wird wird "Suche nac Geräten" mit einem Progress-Indicator angezeigt
                    /// Aussehen definiert
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 45, 45, 45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (isScanning) // Wenn gescannt wird, wird ein progressindicator angezeigt
                            SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(199, 203, 203, 255)),
                              ),
                            )
                          else
                            // Wenn nicht gescannt wird - Bluetooth-Symbol
                            Icon(
                              Icons.bluetooth_searching,
                              color: const Color.fromARGB(199, 203, 203, 255),
                              size: 20.sp,
                            ),
                          SizedBox(width: 12.w),
                          // Wenn gescannt wird - "Suche nach Geräten"
                          // Wenn nicht gescannt wird - "... Geräte gefunden"
                          Text(
                            isScanning ? 'Suche nach Geräten...' : '${scanResults.length} Geräte gefunden',
                            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h), // Abstandhalter
                  ],

                  /// == Geräte Liste ==
                  /// Expanded passt ListView auf gegeben Platz an
                  Expanded(
                    /// Wenn Gerät verbunden - Erfolgreich Verbunden anzeigen
                    child: bluetoothprovider.connectedDevice != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
                                SizedBox(height: 16.h),
                                Text(
                                  'Erfolgreich Verbunden!',
                                  style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8.h),
                                // Wenn Charactseristics bekannt - Sandplotter verbunden
                                // Wenn Characteristics unbekannt - Warte auf Charactersitics
                                Text(
                                  bluetoothprovider.txCharacteristic != null
                                      ? 'Sandplotter verbunden!'
                                      : 'Warte auf Characteristic',
                                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                                ),
                              ],
                            ),
                          )
                        // Wenn keine Geräte gefunden - das auch anzeigen
                        : scanResults.isEmpty && !isScanning
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bluetooth_disabled, size: 64.sp, color: Colors.white30),
                                SizedBox(height: 16.h),
                                Text(
                                  'Keine Geräte gefunden',
                                  style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                                ),
                              ],
                            ),
                          )
                        // Wenn Geräte gefunden - Geräte in Liste anzeigen
                        : ListView.builder(
                            itemCount: scanResults
                                .length, // Länge der Liste anhand der Anzahl der gefundenen Geräte definieren
                            itemBuilder: (context, index) {
                              // Postioen der Elemente übernehmen
                              final result = scanResults[index];
                              // Name des Geräts übernehmen - wenn nicht bekannt "Unbekanntes Gerät"
                              final deviceName = result.device.platformName.isEmpty
                                  ? 'Unbekanntes Gerät'
                                  : result.device.platformName;

                              // Design definiert
                              return Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 45, 45, 45),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color.fromARGB(50, 203, 203, 255), width: 1),
                                ),
                                // Listen-Element vordefiniert
                                child: ListTile(
                                  // Aussehen definiert
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  leading: Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(30, 203, 203, 255),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.bluetooth,
                                      color: const Color.fromARGB(199, 203, 203, 255),
                                      size: 24.sp,
                                    ),
                                  ),
                                  // Name des Gerätes als Titel des Listen-Elements
                                  title: Text(
                                    deviceName,
                                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
                                  ),
                                  // MAC-Adresse als Subtitel des Listen-Elements
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4.h),
                                      Text(
                                        result.device.remoteId.toString(),
                                        style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                                      ),
                                    ],
                                  ),

                                  // Wenn auf ein Element gedrückt wird und keine Verbindung besteht - Verbindung aufbauen
                                  onTap: isConnected ? null : () => connectToDevice(result.device),
                                ),
                              );
                            },
                          ),
                  ),

                  // == Button für Scannen und Trennen ==
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: bluetoothprovider.connectedDevice != null
                        ?
                          // Disconnect Button wenn verbunden
                          // Design definiert
                          ElevatedButton.icon(
                            onPressed: disconnectDevice,
                            icon: Icon(Icons.link_off, size: 20.sp),
                            // TExt des Buttons wenn verbunden
                            label: Text(
                              'Verbindung trennen',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                              elevation: 0,
                            ),
                          )
                        // Scannen Button wenn nicht verbunden
                        // Wenn gerade gescannt wird - Button deaktiviert
                        : ElevatedButton.icon(
                            onPressed: isScanning || isConnected ? null : startScan,
                            icon: Icon(
                              isScanning ? Icons.refresh : Icons.search,
                              size: 20.sp,
                              color: isScanning ? Colors.white : const Color.fromARGB(255, 45, 45, 45),
                            ),
                            // Wenn gescannt wird "Suche läuft" - sonst "Scannen"
                            label: Text(
                              isScanning ? 'Suche läuft...' : 'Scannen',
                              style: TextStyle(
                                color: isScanning ? Colors.white : const Color.fromARGB(255, 45, 45, 45),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: const Color.fromARGB(255, 45, 45, 45),
                              backgroundColor: const Color.fromARGB(199, 203, 203, 255),
                              foregroundColor: const Color.fromARGB(255, 45, 45, 45),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
                              elevation: 0,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Hilfsfunktion zum Aufrufen
// Öffnet den Bluetoothdialog
Future<void> showBluetoothDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const Bluetoothscreen();
    },
  );
}
