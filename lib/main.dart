import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/preference_card_service.dart';
import 'services/progress_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProgressService.instance.init();
  await PreferenceCardService.instance.init();
  runApp(const InstrumentalApp());
}

class InstrumentalApp extends StatelessWidget {
  const InstrumentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instrumental Qx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
