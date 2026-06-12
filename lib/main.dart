import 'package:ethercrypt/app_config.dart';
import 'package:ethercrypt/engine/api/app_lifecycle.dart';
import 'package:ethercrypt/engine/api/dropbox/dropbox.dart';
import 'package:ethercrypt/engine/api/firebase/firestore.dart';
import 'package:ethercrypt/engine/api/googledrive/google_drive.dart';
import 'package:ethercrypt/engine/db/local_database.dart';
import 'package:ethercrypt/engine/other/themes.dart';
import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/engine/persistence/storage/controller/dropbox_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/controller/firestore_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/controller/google_drive_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/controller/local_file_controller.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_file.dart';
import 'package:ethercrypt/engine/persistence/storage/storage_provider.dart';
import 'package:ethercrypt/engine/updates/app_version.dart';
import 'package:ethercrypt/engine/updates/services/github_update_service.dart';
import 'package:ethercrypt/engine/updates/update_service.dart';
import 'package:ethercrypt/pages/vaults/vaults_master_view.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // Ensure Flutter Widget bindings are initialised before app setup
  WidgetsFlutterBinding.ensureInitialized();

  final info = await PackageInfo.fromPlatform();

  final AppState appState = AppState();
  await appState.init();
  await appState.load(); // Reload from disk / preferences

  runApp(Application(
    appState: appState,
    version: AppVersion(info.version),
  ));
}

class Application extends StatefulWidget {
  const Application({super.key, required this.appState, required this.version});

  final AppState appState;
  final AppVersion version;

  @override
  State<Application> createState() => _ApplicationState();
}

class _ApplicationState extends State<Application> with WidgetsBindingObserver {
  final AppLifecycle appLifecycle = AppLifecycle();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        appLifecycle.markReady();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        appLifecycle.markNotReady();
        break;
      default: break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => widget.version),
        ChangeNotifierProvider<AppState>(
          create: (context) => widget.appState,
        ),
        ChangeNotifierProvider<LocalDatabase>(
          create: (context) => LocalDatabase(),
        ),
        Provider<Dropbox>(
          create: (context) => Dropbox(
            clientId: AppConfig.dropboxAppKey,
            lifecycle: appLifecycle,
          ),
        ),
        ChangeNotifierProvider<DropboxController>(
          create: (context) => DropboxController(
            appState: context.read(),
            api: context.read(),
          ),
        ),
        Provider<GoogleDrive>(
          create: (context) => GoogleDrive(
            oAuthClientId: AppConfig.googleDriveClientId,
            oAuthClientSecret: AppConfig.googleDriveClientSecret,
            lifecycle: appLifecycle,
          ),
        ),
        ChangeNotifierProvider<GoogleDriveController>(
          create: (context) => GoogleDriveController(
            appState: context.read(),
            api: context.read(),
          ),
        ),
        Provider<Firestore>(create: (context) => Firestore()),
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
              StorageType.GoogleDrive: context.read<GoogleDriveController>(),
              StorageType.Dropbox: context.read<DropboxController>(),
              StorageType.CloudFirestore: context.read<FirestoreController>(),
            },
          );
          Future.microtask(provider.loadAll); // Initial load
          return provider;
        }),
        ChangeNotifierProvider<UpdateService>(create: (context) {
          final UpdateService service = GitHubUpdateService(
            appState: widget.appState,
            appVersion: context.read(),
            owner: 'GrivianDev',
            repo: 'PasswordManager',
          );
          Future.microtask(() => service.checkForUpdates().then((v) => service.scheduleNextCheck()));
          return service;
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
