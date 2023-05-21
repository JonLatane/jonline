import 'package:flutter/material.dart';
import 'package:jonline/models/storage.dart';
import 'package:logging/logging.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state.dart';
import 'my_platform.dart';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();
  await initStorage();
  if (MyPlatform.isMacOS) {
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
