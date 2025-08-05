import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/config/app_config.dart';
import 'package:passwordmanager/engine/other/themes.dart';
import 'package:passwordmanager/pages/widgets/splash.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/api/firebase/firebase.dart';

/// The main function. It ensures that Flutter Widget bindings are initialised before app setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppState appState = AppState();
  final LocalDatabase database = LocalDatabase();
  final Firestore firestore = Firestore(Config.firestoreProjectId, Config.firestoreApiKey, appState);

  // Init app state by restoring from disk
  await appState.init();

  runApp(Application(appState: appState, localDatabase: database, firestoreService: firestore));
}

/// Application, that is the root of the widget tree. [MultiProvider] is used to provide objects throughout the widget tree.
/// Those can be accessed via [context.read()].
class Application extends StatelessWidget {
  const Application({super.key, required this.appState, required this.localDatabase, required this.firestoreService});

  final AppState appState;
  final LocalDatabase localDatabase;
  final Firestore firestoreService;

  /// Here nearly all widgets will be rebuild after changing the theme because the [themeMode] property
  /// of the MaterialApp listens to Settings changes.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocalDatabase>(create: (context) => localDatabase),
        ChangeNotifierProvider<AppState>(create: (context) => appState),
        Provider<Firestore>(create: (context) => firestoreService),
      ],
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ethercrypt',
          themeMode: context.watch<AppState>().darkMode.value ? ThemeMode.dark : ThemeMode.light,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
