import 'package:flutter/material.dart';
import 'package:ethercrypt/pages/settings/tabs/app_about.dart';
import 'package:ethercrypt/pages/settings/tabs/update_settings.dart';
import 'package:ethercrypt/pages/settings/settings_tab_page.dart';
import 'package:ethercrypt/pages/settings/tabs/general_settings.dart';
import 'package:ethercrypt/pages/settings/tabs/ntp_server_settings.dart';
import 'package:ethercrypt/pages/settings/tabs/password_generation_settings.dart';
import 'package:ethercrypt/pages/settings/tabs/storage_options_settings.dart';
import 'package:ethercrypt/pages/widgets/default_page_body.dart';

enum SettingsTab {
  general,
  updates,
  storageOptions,
  passwordGeneration,
  ntpServer,
  about,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.initalTab = SettingsTab.general});

  static const double layoutBreakpoint = 600;

  final SettingsTab initalTab;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTabIndex = 0;

  final List<(SettingsTab, String, Widget Function())> settingsTabs = [
    (SettingsTab.general, 'General', () => const GeneralSettings()),
    (SettingsTab.updates, 'Updates', () => const UpdateSettings()),
    (SettingsTab.storageOptions, 'Storage options', () => const StorageOptionsSettings()),
    (SettingsTab.passwordGeneration, 'Password generation', () => const PasswordGenerationSettings()),
    (SettingsTab.ntpServer, 'Time sync', () => const NtpServerSettings()),
    (SettingsTab.about, 'About', () => const AppAbout()),
  ];

  @override
  void initState() {
    super.initState();
    final int tabIndex = settingsTabs.indexWhere((t) => t.$1 == widget.initalTab);
    if (tabIndex != -1) _selectedTabIndex = tabIndex;
  }

  Widget _buildNarrowLayout() {
    return ListView.builder(
      itemCount: settingsTabs.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(settingsTabs[index].$2),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            setState(() {
              _selectedTabIndex = index;
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
              final isSelected = index == _selectedTabIndex;

              return ListTile(
                title: Text(settingsTabs[index].$2),
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
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
                    child: settingsTabs[_selectedTabIndex].$3(),
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
