import 'dart:async';

import 'package:ethercrypt/pages/other/notifications.dart';
import 'package:ethercrypt/pages/widgets/validation_controller.dart';
import 'package:flutter/material.dart';

/// Displays a confirmation dialog with a text input field and returns the entered value.
/// Supports live validation of the input as the user types.
///
/// **Parameters:**
/// - [context] – Build context for showing the dialog.
/// - [title] – Dialog title.
/// - [description] – Description or instructions displayed above the input field.
/// - [labelText] – Optional label for the text field.
/// - [hintText] – Optional hint to display on emtpy text field.
/// - [validator] – Optional function called whenever the input changes.
///   - Should return `null` if the input is valid.
///   - Should return an error message string if invalid.
/// - [obscured] – If input should be obscured.
/// - [allowEmptyInput] – Whether to allow empty input.
///
/// **Behavior:**
/// - The confirm button is only accepted if:
///   1. The input is **not empty**, and
///   2. [validator] returns `null` (or is not provided).
/// - Pressing Enter will also confirm if the input is valid.
///
/// **Returns:**
/// - The entered string if the user confirmed with valid input.
/// - `null` if the dialog was cancelled.
Future<String?> getUserInputDialog({
  required BuildContext context,
  required String title,
  String? description,
  String? labelText,
  String? hintText,
  FutureOr<String?> Function(String input)? validator,
  bool obscured = false,
  bool allowEmptyInput = false,
}) async {
  bool currentlyObscured = obscured;
  String? userInput;
  String currentInput = '';

  final ValidationController controller = ValidationController(
    validator: validator,
    debounceDuration: const Duration(seconds: 1),
  );

  await Notify.dialog(
    context: context,
    type: NotificationType.confirmDialog,
    title: title,
    content: SizedBox(
      width: double.maxFinite,
      child: StatefulBuilder(
        builder: (context, setState) {
          return ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final ValidationState state = controller.state;

              return Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (description != null) Text(description),
                  Row(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          obscureText: currentlyObscured,
                          onChanged: (value) {
                            currentInput = value;
                            controller.validate(value);
                          },
                          onSubmitted: (value) {
                            currentInput = value;
                            if (state.error == null && (currentInput.isNotEmpty || allowEmptyInput) && !state.isValidating) {
                              userInput = currentInput;
                              Navigator.pop(context);
                            }
                          },
                          decoration: InputDecoration(
                            prefixIcon: obscured
                                ? const Padding(
                                    padding: EdgeInsets.only(left: 5.0),
                                    child: Icon(Icons.key),
                                  )
                                : null,
                            suffixIcon: obscured
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 5.0),
                                    child: IconButton(
                                      onPressed: () => setState(() {
                                        currentlyObscured = !currentlyObscured;
                                      }),
                                      icon: Icon(
                                        currentlyObscured ? Icons.visibility : Icons.visibility_off,
                                      ),
                                    ),
                                  )
                                : null,
                            labelText: labelText,
                            hintText: hintText,
                            errorText: state.error,
                            errorMaxLines: 10,
                          ),
                        ),
                      ),
                      if (validator != null)
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
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
    onConfirm: () {
      final ValidationState state = controller.state;
      if (state.error == null && (currentInput.isNotEmpty || allowEmptyInput) && !state.isValidating) {
        userInput = currentInput;
        Navigator.pop(context);
      }
    },
  );

  controller.dispose();

  return userInput;
}
