import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/storage/controller/local_file_controller.dart';
import 'package:passwordmanager/engine/persistence/storage/controller/firestore_controller.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';
import 'package:passwordmanager/engine/other/themes.dart';
import 'package:passwordmanager/pages/vaults/vaults_master_view.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:passwordmanager/engine/api/firebase/firestore.dart';

Future<void> main() async {
  // Ensure Flutter Widget bindings are initialised before app setup
  WidgetsFlutterBinding.ensureInitialized();

  final AppState appState = AppState();
  await appState.init();
  await appState.load(); // Reload from disk / preferences

  runApp(Application(appState: appState));
}

/// Application, that is the root of the widget tree.
class Application extends StatelessWidget {
  const Application({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (context) => appState,
        ),
        ChangeNotifierProvider<LocalDatabase>(
          create: (context) => LocalDatabase(),
        ),
        Provider<Firestore>(
          create: (context) => Firestore(),
        ),
        ChangeNotifierProvider<FirestoreController>(
          create: (context) => FirestoreController(
            appState: context.read(),
            api: context.read(),
          ),
        ),
        ChangeNotifierProvider<LocalFileController>(
          create: (context) => LocalFileController(
            appState: context.read(),
          ),
        ),
        ChangeNotifierProvider<StorageProvider>(create: (context) {
          final StorageProvider provider = StorageProvider(
            controllers: {
              StorageType.LocalFilesystem: context.read<LocalFileController>(),
              StorageType.CloudFirestore: context.read<FirestoreController>(),
            },
          );
          Future.microtask(provider.loadAll); // Initial load
          return provider;
        }),
      ],
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ethercrypt',
          themeMode: context.watch<AppState>().darkMode.value ? ThemeMode.dark : ThemeMode.light,
          theme: AppThemeData.lightTheme,
          darkTheme: AppThemeData.darkTheme,
          home: const VaultsMasterView(),
        );
      },
    );
  }
}
