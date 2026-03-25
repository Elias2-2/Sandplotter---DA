/// ============================== Home - Seite =================================
/// Loading-Overlays bleiben auch bei Seitenwechsel erhalten!
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sandplotter_app/Costum/bluetoothscreen.dart';
import 'package:sandplotter_app/Costum/bluetoothsender.dart';
import 'package:sandplotter_app/Costum/custombar.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrapperhome.dart';
import 'package:sandplotter_app/Costum/musterbutton.dart';
import 'package:sandplotter_app/Costum/apptoast.dart';
import 'package:sandplotter_app/pages/muster_pages/muster1.dart';
import 'package:sandplotter_app/pages/muster_pages/muster2.dart';
import 'package:sandplotter_app/pages/muster_pages/muster3.dart';
import 'package:sandplotter_app/pages/muster_pages/muster4.dart';
import 'package:sandplotter_app/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sandplotter_app/provider/bluetoothprovider.dart';
import 'package:sandplotter_app/provider/musterprovider.dart';

class Home extends StatefulWidget {
  const Home({required this.controller, super.key});
  final PageController controller;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin, RouteAware {
  // NUR lokaler State für Fade-Animation (nicht für Loading!)
  bool _isFadingOut = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {
      _isFadingOut = false;
    });
  }

  void _handleFadeOut() {
    setState(() {
      _isFadingOut = true;
    });
  }

  void openBluetoothScreen() async {
    await showBluetoothDialog(context);
  }

  // ===========================================================================
  // STOP
  // ===========================================================================
  void stopAll() async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = Provider.of<MusterProvider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

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

  // ===========================================================================
  // HOMING
  // ===========================================================================
  void homing() async {
    final bluetoothprovider = Provider.of<Bluetoothprovider>(context, listen: false);
    final musterProvider = Provider.of<MusterProvider>(context, listen: false);

    if (!bluetoothprovider.isReady) {
      AppToast.warning('Bluetooth nicht verbunden!');
      return;
    }

    // Falls etwas läuft -> stoppen
    if (musterProvider.isBusy) {
      AppToast.warning('Vorgang wird abgebrochen...');
      await Bluetoothsender.stop(context);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Status im Provider setzen (GLOBAL!)
    await musterProvider.startHoming();

    // Callback für Arduino-Nachrichten
    bluetoothprovider.onMessageReceived = (message) {
      // Provider verarbeitet die Nachricht
      musterProvider.onArduinoMessage(message);

      if (message == 'OK:HOMED') {
        bluetoothprovider.setHomed(true);
        if (mounted) {
          AppToast.success('Homing erfolgreich!');
        }
      } else if (message == 'OK:STOPPED') {
        if (mounted) {
          AppToast.warning('Abgebrochen');
        }
      }
    };

    // Homing-Befehl an Arduino senden
    bool success = await Bluetoothsender.homeAll(context);

    if (mounted) {
      if (!success) {
        AppToast.error('Homing fehlgeschlagen');
        musterProvider.musterFinished();
      }

      // Fallback-Timeout nach 60 Sekunden
      musterProvider.musterFinishedDelayed(const Duration(seconds: 60));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: SafeArea(
        child: InfoWrapperHome(
          child: Center(
            child: Scaffold(
              backgroundColor: const Color.fromARGB(255, 25, 25, 25),
              appBar: Custombar(
                controller: widget.controller,
                iconL: Icons.lightbulb_outline,
                iconR: Icons.brush_outlined,
                pageL: 0,
                pageR: 2,
                name: 'Home',
              ),
              body: AnimatedOpacity(
                opacity: _isFadingOut ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App-Logo
                    ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(25),
                      child: Image.asset('assets/img/Sandplotter_Logo2.png', fit: BoxFit.cover, height: 170.h),
                    ),
                    Container(height: 20.h),

                    // ===================================================
                    // BUTTONS - Consumer liest aus Provider
                    // ===================================================
                    Consumer2<Bluetoothprovider, MusterProvider>(
                      builder: (context, bluetoothprovider, musterProvider, child) {
                        // Status aus Provider lesen (NICHT lokal!)
                        final bool isHoming = musterProvider.isHoming;
                        final bool isStopping = musterProvider.isStopping;

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Bluetooth Button
                                IconButton(
                                  onPressed: openBluetoothScreen,
                                  icon: Icon(
                                    bluetoothprovider.isConnected ? Icons.bluetooth : Icons.bluetooth_disabled,
                                  ),
                                  color: const Color.fromARGB(199, 203, 203, 255),
                                  iconSize: 50.h,
                                ),

                                SizedBox(width: 30.w),

                                // Stop Button mit Loading aus Provider
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: (isStopping || !bluetoothprovider.isConnected) ? null : stopAll,
                                      icon: Icon(
                                        Icons.stop_circle_outlined,
                                        color: isStopping
                                            ? const Color.fromARGB(255, 54, 54, 54)
                                            : bluetoothprovider.isConnected
                                            ? Colors.red
                                            : const Color.fromARGB(255, 54, 54, 54),
                                      ),
                                      iconSize: 50.h,
                                    ),
                                    if (isStopping)
                                      SizedBox(
                                        width: 60.w,
                                        height: 60.h,
                                        child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.red),
                                      ),
                                  ],
                                ),

                                SizedBox(width: 30.w),

                                // Homing Button mit Loading aus Provider
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: (isHoming || !bluetoothprovider.isConnected) ? null : homing,
                                      icon: Icon(
                                        Icons.home,
                                        color: isHoming
                                            ? const Color.fromARGB(255, 54, 54, 54)
                                            : bluetoothprovider.isConnected
                                            ? const Color.fromARGB(199, 203, 203, 255)
                                            : const Color.fromARGB(255, 54, 54, 54),
                                      ),
                                      iconSize: 50.h,
                                    ),
                                    if (isHoming)
                                      SizedBox(
                                        width: 60.w,
                                        height: 60.h,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: Color.fromARGB(199, 203, 203, 255),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),

                            // Homing Status Anzeige
                          ],
                        );
                      },
                    ),

                    Container(height: 20.h),

                    // Muster-Buttons Reihe 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Musterbutton(
                          onFadeOutStart: _handleFadeOut,
                          heroTag: 'mechatronikHero',
                          icons: Image.asset(
                            'assets/img/mechatronikicon.png',
                            height: 80.h,
                            color: const Color.fromARGB(199, 203, 203, 255),
                            fit: BoxFit.cover,
                          ),
                          page: const Muster1(),
                        ),
                        SizedBox(width: 37.w),
                        Musterbutton(
                          onFadeOutStart: _handleFadeOut,
                          heroTag: 'flugtechnikHero',
                          icons: Image.asset(
                            'assets/img/flugtechnikicon.png',
                            height: 80.h,
                            color: const Color.fromARGB(199, 203, 203, 255),
                            fit: BoxFit.cover,
                          ),
                          page: const Muster2(),
                        ),
                      ],
                    ),

                    Container(height: 35.h),

                    // Muster-Buttons Reihe 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Musterbutton(
                          onFadeOutStart: _handleFadeOut,
                          heroTag: 'werkstofftechnikHero',
                          icons: Image.asset(
                            'assets/img/werkstofftechnikicon.png',
                            height: 80.h,
                            color: const Color.fromARGB(199, 203, 203, 255),
                            fit: BoxFit.cover,
                          ),
                          page: const Muster3(),
                        ),
                        SizedBox(width: 37.w),
                        Musterbutton(
                          onFadeOutStart: _handleFadeOut,
                          heroTag: 'maschinenbauHero',
                          icons: Image.asset(
                            'assets/img/maschinenbauicon.png',
                            height: 80.h,
                            color: const Color.fromARGB(199, 203, 203, 255),
                            fit: BoxFit.cover,
                          ),
                          page: const Muster4(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
