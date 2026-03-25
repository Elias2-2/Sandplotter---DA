/// ============================== Muster1 - Seite ==============================
/// In dieser Datei wurde die Mechatronik-Muster-Seite definiert.
/// Auf dieser Seite kann das vordefinierte Mechatronik-Muster zum
/// Sandplotter hochgeladen oder der Sand gelöscht werden.
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrappermuster.dart';
import 'package:sandplotter_app/Costum/custombar_return.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/Costum/apptoast.dart';
import 'package:sandplotter_app/provider/musterprovider.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';

class Muster1 extends StatefulWidget {
  const Muster1({super.key});

  @override
  State<Muster1> createState() => _Muster1State();
}

class _Muster1State extends State<Muster1> with SingleTickerProviderStateMixin {
  // Animation Controller und Animationen
  late AnimationController _animationController;
  late Animation<Offset> _appBarAnimation;
  late Animation<Offset> _buttonAnimation1;
  late Animation<Offset> _buttonAnimation2;
  bool _startAnimations = false;

  // Muster-Konfiguration
  static const String musterCode = 'M';
  static const int musterNummer = 1;
  static const String musterName = 'Sandplotter - Mechatronik';
  static const String heroTag = 'mechatronikHero';
  static const String imagePath = 'assets/img/mechatronikicon.png';

  // KEINE lokalen _isUploading, _isClearing mehr!
  // Stattdessen aus Provider lesen

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _appBarAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _buttonAnimation1 = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _buttonAnimation2 = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _startAnimations = true;
        });
        _animationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================================
  // MUSTER HOCHLADEN - Nutzt Provider statt lokaler State
  // ============================================================================
  Future<void> _uploadMuster() async {
    final bluetoothProvider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = context.read<MusterProvider>();

    // Validierung: Bluetooth verbunden?
    if (!bluetoothProvider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    // Validierung: Homing durchgeführt?
    if (!bluetoothProvider.isHomed) {
      AppToast.warning('Bitte zuerst Homing durchführen!');
      return;
    }

    // Falls Löschen läuft, erst stoppen
    if (musterProvider.isClearing) {
      AppToast.warning('Löschen wird abgebrochen...');
      await Bluetoothsender.stop(context);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Muster im Provider starten (GLOBAL!)
    bool started = await musterProvider.startMuster(musterNummer);
    if (!started) {
      return;
    }

    musterProvider.setStatusText('Muster wird gestartet...');

    // Callback für Arduino-Nachrichten
    bluetoothProvider.onMessageReceived = (message) {
      musterProvider.onArduinoMessage(message);

      if (message == 'OK:MUSTER_DONE') {
        if (mounted) {
          AppToast.success('Muster fertig!');
        }
      } else if (message == 'OK:STOPPED') {
        if (mounted) {
          AppToast.warning('Abgebrochen');
        }
      }
    };

    // Muster-Code an Arduino senden
    bool success = await Bluetoothsender.sendPresetMuster(context, musterCode);

    if (mounted && !success) {
      AppToast.error('Senden fehlgeschlagen');
      musterProvider.musterFinished();
    } else {
      musterProvider.setStatusText('Plotter zeichnet...');
    }

    // Fallback-Timeout nach 5 Minuten
    musterProvider.musterFinishedDelayed(const Duration(minutes: 5));
  }

  // ============================================================================
  // SAND LÖSCHEN - Nutzt Provider statt lokaler State
  // ============================================================================
  Future<void> _clearSand() async {
    final bluetoothProvider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = context.read<MusterProvider>();

    // Validierung: Bluetooth verbunden?
    if (!bluetoothProvider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    // Validierung: Homing durchgeführt?
    if (!bluetoothProvider.isHomed) {
      AppToast.warning('Bitte zuerst Homing durchführen!');
      return;
    }

    // Falls Hochladen läuft, erst stoppen
    if (musterProvider.isUploading) {
      AppToast.warning('Muster wird abgebrochen...');
      await Bluetoothsender.stop(context);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Clearing im Provider starten (GLOBAL!)
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
      AppToast.error('Senden fehlgeschlagen');
      musterProvider.musterFinished();
    }

    // Fallback-Timeout nach 10 Minuten
    musterProvider.musterFinishedDelayed(const Duration(minutes: 10));
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================================
    // Consumer liest Status aus Provider (GLOBAL - überlebt Seitenwechsel!)
    // ============================================================================
    return Consumer2<Bluetoothprovider, MusterProvider>(
      builder: (context, bluetoothProvider, musterProvider, child) {
        // Status aus Provider lesen
        final bool isUploading = musterProvider.isMusterActive(musterNummer);
        final bool isClearing = musterProvider.isClearing;

        // Button-Enable-Logik
        final bool uploadEnabled =
            bluetoothProvider.isConnected &&
            bluetoothProvider.isHomed &&
            !isUploading &&
            !isClearing &&
            !musterProvider.isHoming;

        final bool clearEnabled =
            bluetoothProvider.isConnected && bluetoothProvider.isHomed && !isClearing && !musterProvider.isHoming;

        return Container(
          color: const Color.fromARGB(255, 25, 25, 25),
          child: InfoWrapperMuster(
            child: SafeArea(
              child: Scaffold(
                backgroundColor: const Color.fromARGB(255, 25, 25, 25),
                body: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 45.h,
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false,
                      elevation: 0,
                      flexibleSpace: _startAnimations
                          ? SlideTransition(
                              position: _appBarAnimation,
                              child: Align(alignment: Alignment.center, child: CustombarReturn(musterName)),
                            )
                          : const SizedBox(),
                      pinned: true,
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(padding: EdgeInsets.only(top: 50.h)),

                            // Muster-Vorschau mit Hero-Animation
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 270.h,
                                  height: 270.h,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                Column(
                                  children: [
                                    SizedBox(height: 20.h),
                                    Hero(
                                      tag: heroTag,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(25),
                                          child: Image.asset(imagePath, height: 270.h, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // ============================================================================
                                // LOADING OVERLAY (liest aus Provider!)
                                // ============================================================================
                                if (isUploading || isClearing)
                                  Container(
                                    width: 270.h,
                                    height: 270.h,
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(color: Color(0xC7CBCBFF)),
                                          SizedBox(height: 16.h),
                                          Text(
                                            isClearing
                                                ? 'Sand wird geglättet...'
                                                : (musterProvider.statusText.isNotEmpty
                                                      ? musterProvider.statusText
                                                      : 'Muster wird ausgeführt...'),
                                            style: TextStyle(color: Colors.white, fontSize: 14.sp),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            SizedBox(height: 70.h),

                            // Hochladen Button
                            SlideTransition(
                              position: _buttonAnimation1,
                              child: FilledButton(
                                onPressed: uploadEnabled ? _uploadMuster : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(215.w, 50.h),
                                  maximumSize: Size(215.w, 50.h),
                                  backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                                  disabledBackgroundColor: const Color.fromARGB(255, 54, 54, 54),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 25.w),
                                        child: Text(
                                          'Hochladen',
                                          style: GoogleFonts.openSans(
                                            fontSize: 13.h,
                                            color: uploadEnabled
                                                ? const Color.fromARGB(199, 203, 203, 255)
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: isUploading
                                          ? SizedBox(
                                              width: 30.h,
                                              height: 30.h,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Color.fromARGB(199, 203, 203, 255),
                                              ),
                                            )
                                          : Icon(
                                              Icons.upload,
                                              size: 34.h,
                                              color: uploadEnabled
                                                  ? const Color.fromARGB(199, 203, 203, 255)
                                                  : Colors.black,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 30.h),

                            // Löschen Button
                            SlideTransition(
                              position: _buttonAnimation2,
                              child: FilledButton(
                                onPressed: clearEnabled ? _clearSand : null,
                                style: FilledButton.styleFrom(
                                  maximumSize: Size(215.w, 50.h),
                                  minimumSize: Size(215.w, 50.h),
                                  backgroundColor: const Color.fromARGB(255, 54, 54, 54),
                                  disabledBackgroundColor: const Color.fromARGB(255, 54, 54, 54),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 25.w),
                                        child: Text(
                                          'Löschen',
                                          style: GoogleFonts.openSans(
                                            fontSize: 13.h,
                                            color: clearEnabled
                                                ? const Color.fromARGB(199, 203, 203, 255)
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: isClearing
                                          ? SizedBox(
                                              width: 30.h,
                                              height: 30.h,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 3,
                                                color: Color.fromARGB(199, 203, 203, 255),
                                              ),
                                            )
                                          : Icon(
                                              Icons.delete,
                                              size: 35.h,
                                              color: clearEnabled
                                                  ? const Color.fromARGB(199, 203, 203, 255)
                                                  : Colors.black,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
