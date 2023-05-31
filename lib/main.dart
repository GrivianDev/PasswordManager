import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/widgets/splash.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/themes.dart';
import 'package:passwordmanager/engine/persistance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  runApp(const Application());
}

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocalDatabase(),
        ),
        ChangeNotifierProvider(
          create: (context) => Settings(),
        ),
      ],
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'passwordmanager',
          themeMode: context.watch<Settings>().isLightMode ? ThemeMode.light : ThemeMode.dark,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          home: const SplashScreen()
        );
      },
    );
  }
}
