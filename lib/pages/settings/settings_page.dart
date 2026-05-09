import 'package:flutter/material.dart';
import 'package:passwordmanager/pages/settings/settings_tab_page.dart';
import 'package:passwordmanager/pages/settings/tabs/general_settings.dart';
import 'package:passwordmanager/pages/settings/tabs/ntp_server_settings.dart';
import 'package:passwordmanager/pages/settings/tabs/password_generation_settings.dart';
import 'package:passwordmanager/pages/settings/tabs/storage_options_settings.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';

enum SettingsTab {
  general,
  storageOptions,
  passwordGeneration,
  ntpServer,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const double layoutBreakpoint = 600;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int selectedTabIndex = 0;

  final List<(SettingsTab, String, Widget Function())> settingsTabs = [
    (SettingsTab.general, 'General', () => const GeneralSettings()),
    (SettingsTab.storageOptions, 'Storage options', () => const StorageOptionsSettings()),
    (SettingsTab.passwordGeneration, 'Password generation', () => const PasswordGenerationSettings()),
    (SettingsTab.ntpServer, 'Time sync', () => const NtpServerSettings()),
  ];

  Widget _buildNarrowLayout() {
    return ListView.builder(
      itemCount: settingsTabs.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(settingsTabs[index].$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              selectedTabIndex = index;
            });
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SettingsTabPage(
                  layoutBreakpoint: SettingsPage.layoutBreakpoint,
                  title: settingsTabs[index].$2,
                  child: settingsTabs[index].$3(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: ListView.builder(
            itemCount: settingsTabs.length,
            itemBuilder: (context, index) {
              final isSelected = index == selectedTabIndex;

              return ListTile(
                title: Text(settingsTabs[index].$2),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
              );
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: settingsTabs[selectedTabIndex].$3(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: DefaultPageBody(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= SettingsPage.layoutBreakpoint;

            if (isWide) {
              return _buildWideLayout();
            } else {
              return _buildNarrowLayout();
            }
          },
        ),
      ),
    );
  }
}
