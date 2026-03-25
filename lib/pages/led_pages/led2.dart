/// ============================== LED2 - Seite ================================
/// In dieser Datei wurde die 2.LED-Seite definiert.
/// Auf dieser Seite kann die Farbe und die Animation der LED ausgewählt werden
/// Da alle LED-Seiten gleich aufgebaut sind wurde nur LED1 auskommentiert.
/// Der einzige Unterschied auf den LED-Seitem ist die LED-Nummer
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sandplotter_app/Costum/InfoWrappers/infowrapperled.dart';
import 'package:sandplotter_app/Costum/animationbutton.dart';
import 'package:sandplotter_app/Costum/colorpallete.dart';
import 'package:sandplotter_app/Costum/custombar_return.dart';

class Led2 extends StatelessWidget {
  const Led2({super.key});

  final int lednumber = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 25, 25, 25),
      child: InfoWrapperLed(
        child: SafeArea(
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 25, 25, 25),
            appBar: CustombarReturn('Led 2'),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30.h),
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
                  child: const ColorPickerPage(number: 2),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimationButton(lednumber: lednumber, number: 1),
                    SizedBox(width: 43.w),
                    AnimationButton(lednumber: lednumber, number: 2),
                  ],
                ),
                SizedBox(height: 37.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimationButton(lednumber: lednumber, number: 3),
                    SizedBox(width: 43.w),
                    AnimationButton(lednumber: lednumber, number: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
