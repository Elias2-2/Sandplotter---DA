/// ============================== Muster Button ================================
/// In dieser Datei wurde der Muster-Button der App vordefiniert,
/// damit er mehrmals verwendet werden kann ohne ihn jedes mal neu programmieren zu müssen.
/// Durch dieses Button werden die einzelnen Muster-Seiten geöffnet,
/// in denen man die vorgefertigten Muster zum Sandplotter hochladen kann
/// Es wurde außerdem eine anschauliche Animation von der Home-Seite auf die jeweilige Muster-Seite programmiert
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Musterbutton extends StatefulWidget {
  const Musterbutton({
    required this.icons,
    required this.page,
    required this.heroTag,
    this.backgroundColor = const Color.fromARGB(255, 54, 54, 54),
    this.onFadeOutStart,
    super.key,
  });

  final Widget icons; // Widget (Icon) welches im Button angezeigt wird
  final Widget page; // Zielseite die bei Klick geöffnet wird
  final String heroTag; // "Tag" der Hero-Animation (muss eindeutig sein)
  final Color backgroundColor; // Hintergundfarbe des Buttons
  final VoidCallback? onFadeOutStart; // Callback der aufgerufefen wird wenn Animation startet

  @override
  State<Musterbutton> createState() => _MusterbuttonState();
}

/// Klasse mit TickerProviderStatMixin
/// Ticker ist ein Taktgeber und ruft jeden Frame einzeln auf
class _MusterbuttonState extends State<Musterbutton> with TickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  late AnimationController _controller; // Steuert Animationsablauf
  late Animation<double> _animation; // Animation mit Kurve
  OverlayEntry? _overlayEntry; // Referenz auf das Overlay-Element

  @override
  void initState() {
    super.initState();

    // AnimationsController erstellen
    // duration: Wie lange die Animation dauert
    // vsync: this = diese Klasse ist der TicketProvider
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    /// CurvedAnimation - Fügt Beschleunigungskurve hinzu
    /// Startet schnell, wird langsamer am Ende
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  // dispose() - gibt Resourcen wieder frei
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Wird bei Klick auf den Button aufgerufen
  /// Ablauf:
  /// 1. Button-Position und Größe ermitteln
  /// 2. Overlay erstellen und einfügen
  /// 3. Expand-Animation starten
  /// 4. Zur Zielseite navigieren
  /// 5. Overlay erntfernen
  void _onTap() {
    // Verhindere mehrfaches Auslösen während Animation läuft
    if (_overlayEntry != null) return;
    // Ermöglicht Zugriff auf Position und Größe
    final RenderBox renderBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    // Position des Widgets relativ zum Bildschirm
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    // gibt Breite und Höhe des Widgets zurück
    final Size size = renderBox.size;

    // Overlay erstellen und in Stack einfügen
    _overlayEntry = _buildOverlay(offset, size);
    Overlay.of(context).insert(_overlayEntry!);

    // Starte die Rechteck-Animation
    _controller.forward();

    // Callback aufrufen (nur wenn nicht 0)
    widget.onFadeOutStart?.call();

    // Zur Zielseite navigieren
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => widget.page,
        transitionsBuilder: (_, anim, _, child) {
          final fadeAnimation = CurvedAnimation(
            parent: anim,
            curve: const Interval(
              0.1,
              1.0, // <-- schneller sichtbar
              curve: Curves.easeIn,
            ),
          );
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );

    // Overlay entfernen und COntroller zurücksetzen
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.reset();
  }

  // Erstellte expandierendes Overlay-Rechteck
  OverlayEntry _buildOverlay(Offset offset, Size size) {
    final screenSize = MediaQuery.of(context).size;

    return OverlayEntry(
      builder: (_) {
        // Animation-Builder - Rebuilt bei jeder Animationsänderung
        return AnimatedBuilder(
          animation: _animation,
          builder: (_, _) {
            final double width = lerpDouble(size.width, screenSize.width, _animation.value)!;
            final double height = lerpDouble(size.height, screenSize.height, _animation.value)!;
            final double left = lerpDouble(offset.dx, 0, _animation.value)!;
            final double top = lerpDouble(offset.dy, 0, _animation.value)!;
            final double borderRadius = lerpDouble(30, 0, _animation.value)!;

            return Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Material(
                color: const Color.fromARGB(120, 47, 47, 47),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(120, 47, 47, 47),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: _buttonKey, // GlobalKey für Position/Größe-Zugriff
      onPressed: _onTap,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: widget.backgroundColor,
        minimumSize: Size(110.w, 90.h),
      ),

      /// Hero-Animation
      /// Animiert ein Widget automatisch zwischen zwei Seiten
      child: Hero(
        tag: widget.heroTag, // eindeutiger Tag
        child: Material(color: Colors.transparent, child: widget.icons),
      ),
    );
  }
}
