import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import 'screens/home_screen.dart';
import 'src/reminders.dart';
import 'src/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final reminders = LocalReminders();
  await reminders.init();
  runApp(UdhaarApp(store: LedgerStore(reminders: reminders)));
}

class UdhaarApp extends StatelessWidget {
  const UdhaarApp({super.key, required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return UiApp(
      title: 'Udhaar',
      home: HomeScreen(store: store),
    );
  }
}
