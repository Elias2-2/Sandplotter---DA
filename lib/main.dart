/// =========================== Einleitung ======================================
/// In diesen Dateien wurde die App für den Sandplotter programmiert!
/// Jede Seite der App hat eine eigene .dart-Datei in der sie programmiert wurde.
/// Diese Dateien sind in dem Ordner "pages" zu finden.
/// Alle seitenübergreifenden Parameter wurden in Provider verlegt die ebenfalls
/// jeweils in einer eigenen .dart-Datei programmiert wurden. Diese Dateien sind
/// in dem Ordner "provider" zu finden.
/// Eigens für diese App programmierte Widgets oder größere Funktionen wurden
/// ebenfalls in eigene .dart-Dateien ausgelagert.
/// Diese sind in dem Ordner "Costum" zu finden.

/// ============================== Main - Einstiegspunkt ========================
/// In dieser Datei wurde der Einstiegspunkt der App definiert.
/// Hier werden alle Provider initialisiert und die Grundstruktur der App
/// mit PageView für Swipe-Navigation zwischen den Seiten erstellt.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/pages/home.dart';
import 'package:sandplotter_app/pages/led.dart';
import 'package:sandplotter_app/pages/zeichnen.dart';
import 'package:sandplotter_app/provider/animationprovider.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';
import 'package:sandplotter_app/provider/ledcolorprovider.dart';
import 'package:sandplotter_app/provider/musterprovider.dart';
import 'package:sandplotter_app/provider/presetprovider.dart';

// === GLOBALER ROUTE OBSERVER ===

// RouteObserver ermöglicht Widgets auf Seitenwechsel zu reagieren
// Wird von Home-Seite verwendet um zu wissen wann User zurückkehrt
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// === MAIN-FUNKTION ===

// main() ist der Einstiegspunkt jeder Dart-Anwendung
void main() {
  // Stellt sicher dass Flutter-Bindings initialisiert sind
  // Notwendig bevor SystemChrome oder andere Platform-Dienste verwendet werden
  WidgetsFlutterBinding.ensureInitialized();

  // Stellt die System-Daten oben am Bildschirmrand ein
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Sperrt die App auf Hochformat (Portrait)
  // DeviceOrientation.portraitUp = Gerät aufrecht, Home-Button unten
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    // runApp() startet die Flutter-Anwendung
    runApp(
      // === SCREENUTIL INITIALISIERUNG ===

      // ScreenUtilInit macht die App responsive
      // Alle .w, .h, .sp Werte werden relativ zur designSize skaliert
      ScreenUtilInit(
        // Design-Größe: Die Referenz-Auflösung für das UI-Design
        // 1080x2400 = Full HD+ (typisches modernes Smartphone)
        designSize: const Size(1080, 2400),
        // Passt Textgrößen automatisch an
        minTextAdapt: true,
        // Unterstützt Split-Screen-Modus
        splitScreenMode: true,
        builder: (context, child) => MultiProvider(
          // === PROVIDER REGISTRIERUNG ===

          // MultiProvider registriert alle Provider für die gesamte App
          // Alle Widgets unterhalb können auf diese Provider zugreifen
          providers: [
            // ChangeNotifierProvider erstellt und verwaltet Provider-Instanzen
            ChangeNotifierProvider(create: (context) => MusterProvider()),
            ChangeNotifierProvider(create: (context) => PresetProvider()),
            ChangeNotifierProvider(create: (context) => LedColorProvider()),
            ChangeNotifierProvider(create: (context) => AnimationProvider()),
            ChangeNotifierProvider(create: (context) => Bluetoothprovider()),
          ],
          // === MATERIALAPP ===

          // MaterialApp ist das Root-Widget für Material Design Apps
          child: MaterialApp(
            // RouteObserver für Navigation-Events registrieren
            navigatorObservers: [routeObserver],
            // Builder für ScreenUtil-Initialisierung
            builder: (context, widget) {
              ScreenUtil.init(context);
              return widget!;
            },
            // Startseite der App
            home: const Swipe(),
            // Debug-Banner ausblenden
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  });
}

// === SWIPE WIDGET ===

// Swipe ist das Haupt-Widget das die 3 Seiten enthält
// StatefulWidget weil PageController und swipeEnabled verwaltet werden müssen
class Swipe extends StatefulWidget {
  const Swipe({super.key});

  @override
  State<Swipe> createState() => _SwipeState();
}

class _SwipeState extends State<Swipe> {
  // PageController steuert den PageView
  late final PageController controller;

  // Steuert ob Swipe-Gesten erlaubt sind
  // Wird auf false gesetzt während auf der Zeichenfläche gezeichnet wird
  bool swipeEnabled = true;

  // Callback für Zeichnen-Seite um Swipe zu aktivieren/deaktivieren
  // enabled = true: Swipe erlaubt, enabled = false: Swipe gesperrt
  void setSwipeEnabled(bool enabled) {
    setState(() => swipeEnabled = enabled);
  }

  @override
  void initState() {
    super.initState();
    // PageController mit Startseite initialisieren
    // (3 / 2).floor() = 1 = Home-Seite (mittlere Seite)
    // Seiten: 0 = LED, 1 = Home, 2 = Zeichnen
    controller = PageController(initialPage: (3 / 2).floor());
  }

  @override
  void dispose() {
    // PageController muss disposed werden um Memory Leaks zu vermeiden
    controller.dispose();
    super.dispose();
  }

  // === BUILD-METHODE ===

  @override
  Widget build(BuildContext context) {
    // SafeArea - Beachtet System-UI (Statusbar, Uhrzeit, ...)
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: SafeArea(
        // PageView ermöglicht horizontales Swipen zwischen Seiten
        child: PageView(
          // Controller für Navigation
          controller: controller,
          // Physics bestimmt das Scroll-Verhalten
          // PageScrollPhysics = normales Seiten-Swipen
          // NeverScrollableScrollPhysics = Swipen deaktiviert
          physics: swipeEnabled ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
          // Die 3 Hauptseiten der App
          children: [
            Led(controller: controller), // Seite 0: LED-Einstellungen
            Home(controller: controller), // Seite 1: Hauptseite
            Zeichnen(controller: controller, onDrawing: setSwipeEnabled), // Seite 2: Zeichnen
          ],
        ),
      ),
    );
  }
}
