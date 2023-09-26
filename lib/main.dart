import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/cloud_connector.dart';
import 'package:passwordmanager/pages/widgets/splash.dart';
import 'package:passwordmanager/engine/local_database.dart';
import 'package:passwordmanager/engine/themes.dart';
import 'package:passwordmanager/engine/persistance.dart';

/// The main function. It firstly ensures that Flutter Widgetbindings and the [Settings] class is initialized.
/// Only then the Application is executed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  await FirebaseConnector.init();
  runApp(const Application());
}

/// Application, that is the root of the widget tree. [MultiProvider] is used to provide
/// the [LocalDatabase], the [Settings] and the [FirebaseConnector] object through the widget tree.
class Application extends StatelessWidget {
  const Application({super.key});

  /// Here nearly all widgets will be rebuild after changing the theme because the [themeMode] property
  /// of the MaterialApp listens to Settings changes.
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
        Provider(
          create: (context) => FirebaseConnector(),
        ),
      ],
      builder: (context, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Ethercrypt',
            themeMode: context.watch<Settings>().isLightMode ? ThemeMode.light : ThemeMode.dark,
            theme: AppThemeData.lightTheme,
            darkTheme: AppThemeData.darkTheme,
            home: const SplashScreen());
      },
    );
  }
}
