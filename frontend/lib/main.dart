import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jonline/models/storage.dart';

import 'app_state.dart';

// void main() => runApp(const MyApp());
main() async {
  await GetStorage.init();
  await initStorage();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => AppState();
}
