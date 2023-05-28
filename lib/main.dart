import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/home_page.dart';

void main() {
  Settings.init();
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
          title: 'Flutter Demo',
          themeMode: context.watch<Settings>().isLightMode ? ThemeMode.light : ThemeMode.dark,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          home: const HomePage(
            title: 'Password Manager',
          ),
        );
      },
    );
  }
}
