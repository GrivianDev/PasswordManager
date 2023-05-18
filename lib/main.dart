import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:provider/provider.dart';
import 'engine/account.dart';
import 'engine/manager.dart';
import 'engine/persistance.dart';
import 'pages/home_page.dart';
import 'package:passwordmanager/pages/themes.dart';
import 'package:passwordmanager/pages/account_display_page.dart';

void main() {
  Settings.init();
  runApp(Application());
}

class Application extends StatelessWidget {
  Application({super.key}) {
    Manager().testData();
  }

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
