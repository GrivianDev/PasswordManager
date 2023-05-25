import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/engine/persistance.dart';
import 'package:passwordmanager/pages/home_page.dart';

void main() {
  Settings.init();
  runApp(Application());
}

class Application extends StatelessWidget {
  Application({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        builder: (context, _) {
          final ThemeProvider themeProvider =
              Provider.of<ThemeProvider>(context);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            themeMode: themeProvider.themeMode,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            home: const HomePage(
              title: 'Password Manager',
            ),
          );
        },
      );
}
