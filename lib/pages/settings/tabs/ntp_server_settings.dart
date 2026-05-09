import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/persistence/appstate.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/flows/user_input_dialog.dart';
import 'package:passwordmanager/pages/other/notifications.dart';

class NtpServerSettings extends StatefulWidget {
  const NtpServerSettings({super.key});

  @override
  State<NtpServerSettings> createState() => _NtpServerSettingsState();
}

class _NtpServerSettingsState extends State<NtpServerSettings> {
  Future<void> _setNtpServer() async {
    final AppState appState = context.read();
    String? input = await getUserInputDialog(
      context: context,
      title: 'Enter new NTP-Server',
      labelText: 'NTP-Server',
      hintText: 'time.example.com',
      allowEmptyInput: true,
    );
    if (input == null || !mounted) return;

    await runAppFlow(context, () async {
      appState.ntpTimeSyncServer.value = input;
      await appState.save();
    });
  }

  Future<void> _testNtpServerConnection() async {
    final AppState appState = context.read();
    final NavigatorState navigator = Navigator.of(context);
    final String server = appState.ntpTimeSyncServer.value;
    if (server.isEmpty) return;

    await runAppFlow(context, () async {
      DateTime? queriedTime;
      try {
        Notify.showLoading(context: context);
        queriedTime = await NTP.now(
          lookUpAddress: server,
          timeout: const Duration(seconds: 5),
        );
      } finally {
        navigator.pop();
      }
      if (!mounted) return;
      await Notify.dialog(
        context: context,
        type: NotificationType.notification,
        title: 'Test success!',
        content: Text('Server: $server\nTime (UTC) received: ${queriedTime.toUtc()}'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Row(
          spacing: 10,
          children: [
            Text(
              'NTP-Server',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const Tooltip(
              message: 'Used to synchronize time for more accurate 2FA code generation.',
              child: Icon(Icons.help_outline, size: 18),
            ),
          ],
        ),
        Row(
          spacing: 10,
          children: [
            Flexible(
              child: Text(
                appState.ntpTimeSyncServer.value.isNotEmpty ? appState.ntpTimeSyncServer.value : 'Not configured',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: _setNtpServer,
              icon: const Icon(Icons.edit),
            ),
          ],
        ),
        if (appState.ntpTimeSyncServer.value.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: TextButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Test connection'),
              onPressed: _testNtpServerConnection,
            ),
          ),
      ],
    );
  }
}
