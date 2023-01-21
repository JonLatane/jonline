import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jonline/models/storage.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:smooth/smooth.dart';

import 'app_state.dart';
import 'my_platform.dart';

// void main() => runApp(const MyApp());
main() async {
  // SmoothWidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await initStorage();
  if (MyPlatform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();

    // Use it only after calling `hiddenWindowAtLaunch`
    windowManager.waitUntilReadyToShow().then((_) async {
      // Hide window title bar
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      // await windowManager.setSize(Size(800, 600));
      // await windowManager.center();
      // await windowManager.show();
      // await windowManager.setSkipTaskbar(false);
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => AppState();
}
