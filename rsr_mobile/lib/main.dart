import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rsr_mobile/src/ui_kit/ui_colors.dart';

import 'src/screens/detector_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RSRApp());
}

class RSRApp extends StatefulWidget {
  const RSRApp({super.key});

  @override
  State<RSRApp> createState() => _RSRAppState();
}

class _RSRAppState extends State<RSRApp> {
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();

    initializeApp();
  }

  Future<void> initializeApp() async {
    // NOTE: Need because of bug with image orientation in 'camera_avfoundation' package

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    setState(() {
      isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isInitialized
        ? Container(color: UIColors.background)
        : MaterialApp(
            theme: ThemeData(
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            color: UIColors.background,
            debugShowCheckedModeBanner: false,
            supportedLocales: const <Locale>[
              Locale('en', 'EN'),
            ],
            locale: const Locale('en', 'EN'),
            title: 'RSR',
            home: MediaQuery(
              data: MediaQueryData.fromView(View.of(context)),
              child: const DetectorScreen(),
            ),
            builder: (context, child) {
              return BotToastInit()(
                context,
                child,
              );
            },
          );
  }
}
