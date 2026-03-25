/// ======================== Drawing Area ============================
/// ÜBERARBEITET: Nutzt Provider-States statt lokaler States
/// Loading-Overlays bleiben auch bei Seitenwechsel erhalten!
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/provider/musterprovider.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/Costum/apptoast.dart';

const double drawingAreaSize = 300;
const double aspectRatioValue = 1.0;

class DrawPoint {
  final Offset offset;
  final double strokeWidth;
  DrawPoint(this.offset, this.strokeWidth);
}

class DrawingArea extends StatefulWidget {
  const DrawingArea({super.key, required this.onDrawing});
  final Function(bool) onDrawing;

  @override
  State<DrawingArea> createState() => _DrawingAreaState();
}

class _DrawingAreaState extends State<DrawingArea> {
  final List<DrawPoint?> _points = [];
  final GlobalKey _paintKey = GlobalKey();

  // ════════════════════════════════════════════════════════════════════════════
  // ZEICHENLOGIK (lokal - nur visuelle Punkte)
  // ════════════════════════════════════════════════════════════════════════════

  void _addPoint(Offset offset, Size canvasSize) {
    final clampedOffset = Offset(offset.dx.clamp(0.0, canvasSize.width), offset.dy.clamp(0.0, canvasSize.height));

    setState(() {
      _points.add(DrawPoint(clampedOffset, 3.0));
    });

    double normalizedX = (clampedOffset.dx / canvasSize.width).clamp(0.0, 1.0);
    double normalizedY = (clampedOffset.dy / canvasSize.height).clamp(0.0, 1.0);

    context.read<MusterProvider>().addPoint(Offset(normalizedX, normalizedY));
  }

  void _endLine() {
    setState(() {
      _points.add(null);
    });
    context.read<MusterProvider>().endLine();
    widget.onDrawing(true);
  }

  void _clear() {
    setState(() {
      _points.clear();
    });
    context.read<MusterProvider>().clearDrawing();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BLUETOOTH-KOMMUNIKATION
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _stopAll() async {
    final bluetoothProvider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = context.read<MusterProvider>();

    if (!bluetoothProvider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    // Abbruch für laufende Uploads signalisieren
    Bluetoothsender.requestCancel();

    // Status im Provider setzen (NICHT lokal!)
    await musterProvider.startStopping();

    bool success = await Bluetoothsender.stop(context);

    if (mounted) {
      musterProvider.stoppingFinished();

      if (success) {
        musterProvider.musterFinished();
        AppToast.success('Gestoppt!');
      } else {
        AppToast.error('Stop fehlgeschlagen');
      }
    }
  }

  Future<void> _uploadDrawing() async {
    final bluetoothProvider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = context.read<MusterProvider>();

    // Validierung
    if (!bluetoothProvider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    if (!bluetoothProvider.isHomed) {
      AppToast.warning('Bitte zuerst Homing durchführen!');
      return;
    }

    if (_points.isEmpty) {
      AppToast.warning('Bitte zuerst etwas zeichnen!');
      return;
    }

    // Falls Löschen läuft, erst stoppen
    if (musterProvider.isClearing) {
      AppToast.warning('Löschen wird abgebrochen...');
      await Bluetoothsender.stop(context);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Abbruch-Flag zurücksetzen
    Bluetoothsender.resetCancel();

    // Status im Provider setzen (GLOBAL!)
    bool started = await musterProvider.startCustomMuster();
    if (!started) {
      return;
    }

    // Callback für Arduino-Nachrichten
    bluetoothProvider.onMessageReceived = (message) {
      // Provider verarbeitet die Nachricht
      musterProvider.onArduinoMessage(message);

      // Zusätzliche UI-Feedback
      if (message == 'OK:PATH_DONE') {
        if (mounted) {
          AppToast.success('Zeichnung fertig!');
        }
      } else if (message == 'OK:STOPPED') {
        if (mounted) {
          AppToast.warning('Abgebrochen');
        }
      } else if (message == 'OK:PATH_RECEIVED') {
        if (mounted) {
          AppToast.info('Daten übertragen - Plotter startet');
        }
      }
    };

    musterProvider.setStatusText('Übertrage Daten...');

    // Koordinaten an Arduino senden
    bool success = await Bluetoothsender.sendDrawing(context, musterProvider.getCoordinates(10000));

    if (mounted) {
      if (!success) {
        if (!bluetoothProvider.isReady) {
          AppToast.error('Bluetooth-Verbindung verloren!');
          musterProvider.musterFinished();
        }
        // Sonst: wurde abgebrochen - keine Fehlermeldung
      } else {
        musterProvider.setStatusText('Plotter zeichnet...');
        AppToast.info('Daten übertragen - Plotter startet');
      }
    }

    // Fallback-Timeout
    musterProvider.musterFinishedDelayed(const Duration(minutes: 30));
  }

  Future<void> _clearSand() async {
    final bluetoothProvider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = context.read<MusterProvider>();

    if (!bluetoothProvider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    if (!bluetoothProvider.isHomed) {
      AppToast.warning('Bitte zuerst Homing durchführen!');
      return;
    }

    // Falls Hochladen läuft, erst stoppen
    if (musterProvider.isUploading) {
      AppToast.warning('Zeichnung wird abgebrochen...');
      Bluetoothsender.requestCancel();
      await Bluetoothsender.stop(context);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Status im Provider setzen (GLOBAL!)
    bool started = await musterProvider.startClearing();
    if (!started) {
      return;
    }

    // Callback für Arduino-Nachrichten
    bluetoothProvider.onMessageReceived = (message) {
      musterProvider.onArduinoMessage(message);

      if (message == 'OK:CLEAR_DONE') {
        if (mounted) {
          AppToast.success('Sand geglättet!');
        }
      } else if (message == 'OK:STOPPED') {
        if (mounted) {
          AppToast.warning('Abgebrochen');
        }
      }
    };

    // Lösch-Befehl an Arduino senden
    bool success = await Bluetoothsender.sendClear(context);

    if (mounted && !success) {
      if (!bluetoothProvider.isReady) {
        AppToast.error('Bluetooth-Verbindung verloren!');
      }
      musterProvider.musterFinished();
    }

    // Fallback-Timeout
    musterProvider.musterFinishedDelayed(const Duration(minutes: 10));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // WICHTIG: Consumer statt lokaler State!
    // So wird UI aktualisiert auch wenn Seite gewechselt wurde
    return Consumer2<MusterProvider, Bluetoothprovider>(
      builder: (context, musterProvider, bluetoothProvider, child) {
        // Status aus Provider lesen (NICHT lokal!)
        final bool isUploading = musterProvider.isUploading && musterProvider.activeMuster == 5;
        final bool isClearing = musterProvider.isClearing;
        final bool isBusy = isUploading || isClearing;
        final String statusText = musterProvider.statusText;

        // Button-Enable-Logik
        final bool uploadEnabled =
            bluetoothProvider.isConnected &&
            bluetoothProvider.isHomed &&
            !isUploading &&
            !isClearing &&
            !musterProvider.isHoming;

        final bool clearEnabled =
            bluetoothProvider.isConnected && bluetoothProvider.isHomed && !isClearing && !musterProvider.isHoming;

        final double areaWidth = drawingAreaSize.w;
        final double areaHeight = areaWidth / aspectRatioValue;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ZEICHENFLÄCHE
            SizedBox(
              width: areaWidth,
              height: areaHeight,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: Container(
                      key: _paintKey,
                      width: areaWidth,
                      height: areaHeight,
                      color: const Color(0xFF363636),
                      child: Listener(
                        onPointerDown: (_) => widget.onDrawing(false),
                        onPointerUp: (_) => widget.onDrawing(true),
                        onPointerCancel: (_) => widget.onDrawing(true),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) {
                            final box = _paintKey.currentContext!.findRenderObject() as RenderBox;
                            final localPos = box.globalToLocal(details.globalPosition);
                            _addPoint(localPos, box.size);
                          },
                          onPanEnd: (_) => _endLine(),
                          child: CustomPaint(painter: MyPainter(_points)),
                        ),
                      ),
                    ),
                  ),

                  // LOADING-OVERLAY (liest aus Provider!)
                  if (isBusy)
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        width: areaWidth,
                        height: areaHeight,
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Color(0xC7CBCBFF)),
                              SizedBox(height: 16.h),
                              Text(
                                isClearing
                                    ? 'Sand wird geglättet...'
                                    : (statusText.isNotEmpty ? statusText : 'Zeichnung wird übertragen...'),
                                style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                textAlign: TextAlign.center,
                              ),
                              if (isUploading) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  'Stop-Button zum Abbrechen',
                                  style: TextStyle(color: Colors.white70, fontSize: 11.sp),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 3.h),

            // BUTTON-LEISTE
            Container(
              height: 50.h,
              width: areaWidth,
              decoration: const BoxDecoration(
                color: Color(0xFF363636),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // UPLOAD-BUTTON
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: uploadEnabled ? _uploadDrawing : null,
                        icon: isUploading
                            ? SizedBox(
                                width: 24.h,
                                height: 24.h,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xC7CBCBFF)),
                              )
                            : Icon(
                                Icons.upload,
                                size: 30.h,
                                color: uploadEnabled ? const Color(0xC7CBCBFF) : const Color(0xFF2F2F2F),
                              ),
                      ),
                    ],
                  ),

                  // SAND-GLÄTTEN-BUTTON
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: clearEnabled ? _clearSand : null,
                        icon: isClearing
                            ? SizedBox(
                                width: 24.h,
                                height: 24.h,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xC7CBCBFF)),
                              )
                            : Icon(
                                Icons.delete,
                                size: 30.h,
                                color: clearEnabled ? const Color(0xC7CBCBFF) : const Color(0xFF2F2F2F),
                              ),
                      ),
                    ],
                  ),

                  SizedBox(width: 10.w),

                  // STOP-BUTTON
                  IconButton(
                    onPressed: bluetoothProvider.isConnected ? _stopAll : null,
                    icon: Icon(
                      Icons.stop_circle_outlined,
                      size: 30.h,
                      color: bluetoothProvider.isConnected ? Colors.red : const Color(0xFF2F2F2F),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  // ZEICHNUNG-LÖSCHEN-BUTTON
                  IconButton(
                    onPressed: _clear,
                    icon: Icon(Icons.cancel, size: 30.h, color: const Color(0xC7CBCBFF)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// CUSTOM PAINTER
class MyPainter extends CustomPainter {
  final List<DrawPoint?> points;
  MyPainter(this.points) : super();

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      if (p1 != null && p2 != null) {
        final paint = Paint()
          ..color = const Color(0xFFCBCBFF)
          ..strokeWidth = p1.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(p1.offset, p2.offset, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
