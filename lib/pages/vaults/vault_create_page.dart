import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:passwordmanager/engine/other/util.dart';
import 'package:passwordmanager/engine/persistence/source.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_controller.dart';
import 'package:passwordmanager/pages/flows/app_flows.dart';
import 'package:passwordmanager/pages/other/notifications.dart';
import 'package:passwordmanager/engine/other/safety.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_file.dart';
import 'package:passwordmanager/engine/persistence/storage/storage_provider.dart';
import 'package:passwordmanager/pages/other/storage_type_ui.dart';
import 'package:passwordmanager/pages/widgets/default_page_body.dart';
import 'package:passwordmanager/pages/widgets/obscured_text_field.dart';
import 'package:passwordmanager/pages/widgets/password_strength_indicator.dart';
import 'package:passwordmanager/pages/widgets/validation_controller.dart';

class VaultCreatePage extends StatefulWidget {
  const VaultCreatePage({super.key, this.sourceFile});

  final StorageFile? sourceFile;

  @override
  State<VaultCreatePage> createState() => _VaultCreatePageState();
}

class _VaultCreatePageState extends State<VaultCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  late final ValidationController _nameValidator;

  StorageType _selectedStorageType = StorageType.LocalFilesystem;
  double _rating = 0.0;

  bool _canCreate() => _nameValidator.state.isValid && _pwController.text.isNotEmpty;

  Future<String?> _validateNameInput(String input) async {
    try {
      if (!mounted) return null;
      if (input.isEmpty) return 'Cannot be empty';
      if (!isValidFilename(input)) return 'Discouraged vault name';

      final StorageController controller = context.read<StorageProvider>().controller(_selectedStorageType);
      final String location = await controller.getUserStorageLocation();
      if (await controller.repository.nameExists(name: input, location: location)) return 'Name already exists';
    } catch (_) {
      return 'Error occured';
    }
    return null;
  }

  Future<void> _createVault() async {
    final NavigatorState navigator = Navigator.of(context);
    final StorageProvider provider = context.read();

    await runAppFlow(context, () async {
      try {
        Notify.showLoading(context: context);
        final StorageController controller = provider.controller(_selectedStorageType);
        final String location = await controller.getUserStorageLocation();

        await Source.initialiseNew(
          controller.repository,
          name: _nameController.text,
          location: location,
          password: _pwController.text,
        );
        controller.load();
      } finally {
        navigator.pop();
      }
      navigator.pop();
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.sourceFile?.name ?? '';
    _nameValidator = ValidationController(validator: _validateNameInput, debounceDuration: const Duration(seconds: 1));
    _nameValidator.validate(_nameController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceFile == null ? 'Create vault' : 'Create vault copy'),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _nameValidator,
        builder: (context, child) {
          return FloatingActionButton(
            onPressed: _canCreate() ? _createVault : null,
            backgroundColor: _canCreate() ? Theme.of(context).floatingActionButtonTheme.backgroundColor : Colors.blueGrey,
            child: const Icon(Icons.check),
          );
        },
      ),
      body: DefaultPageBody(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              spacing: 20,
              children: [
                ListenableBuilder(
                  listenable: _nameValidator,
                  builder: (context, child) {
                    final ValidationState state = _nameValidator.state;

                    return Row(
                      spacing: 10,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Vault name',
                              errorText: state.error,
                            ),
                            onChanged: _nameValidator.validate,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Builder(
                              builder: (context) {
                                if (state.isValidating) {
                                  return const CircularProgressIndicator(strokeWidth: 2);
                                }
                                if (state.isValid) {
                                  return const Icon(
                                    Icons.check,
                                    size: 25,
                                    color: Colors.green,
                                  );
                                }
                                if (state.hasError) {
                                  return const Icon(
                                    Icons.error,
                                    size: 25,
                                    color: Colors.redAccent,
                                  );
                                }

                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                DropdownMenu<StorageType>(
                  label: const Text('Storage'),
                  leadingIcon: Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Icon(_selectedStorageType.icon),
                  ),
                  requestFocusOnTap: false,
                  enableSearch: false,
                  initialSelection: _selectedStorageType,
                  width: double.maxFinite,
                  onSelected: (StorageType? value) {
                    setState(() {
                      _selectedStorageType = value!;
                      _nameValidator.validate(_nameController.text);
                    });
                  },
                  dropdownMenuEntries: StorageType.values.where(((type) => context.read<StorageProvider>().isAvailable(type))).map((type) {
                    return DropdownMenuEntry(
                      value: type,
                      label: type.label,
                      leadingIcon: Icon(type.icon),
                    );
                  }).toList(),
                ),
                if (widget.sourceFile == null)
                  ObscuredTextField(
                    label: 'Password',
                    controller: _pwController,
                    onChanged: (value) {
                      setState(() {
                        _rating = SafetyAnalyser.rateSafety(password: value);
                      });
                    },
                  ),
                if (widget.sourceFile == null) PasswordStrengthIndicator(rating: _rating),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
