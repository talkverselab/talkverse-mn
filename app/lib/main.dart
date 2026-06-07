import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'data/db/app_database.dart';
import 'screens/main_screen.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  runApp(const MongolianUniverseApp());
}

class MongolianUniverseApp extends StatelessWidget {
  const MongolianUniverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '몽골어유니버스',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      home: const MainScreen(),
    );
  }
}
