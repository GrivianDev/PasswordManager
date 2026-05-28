import 'package:ethercrypt/engine/persistence/appstate.dart';
import 'package:ethercrypt/pages/flows/app_flows.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PasswordGenerationSettings extends StatefulWidget {
  const PasswordGenerationSettings({super.key});

  @override
  State<PasswordGenerationSettings> createState() => _PasswordGenerationSettingsState();
}

class _PasswordGenerationSettingsState extends State<PasswordGenerationSettings> {
  @override
  Widget build(BuildContext context) {
    final AppState appState = context.watch();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Text(
          'Password generation',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Password length: ${appState.pwGenMinCharacters.value} - ${appState.pwGenMaxCharacters.value}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        RangeSlider(
          values: RangeValues(
            appState.pwGenMinCharacters.value.toDouble(),
            appState.pwGenMaxCharacters.value.toDouble(),
          ),
          min: 8,
          max: 100,
          onChanged: (range) {
            runAppFlow(context, () async {
              appState.pwGenMinCharacters.value = range.start.toInt();
              appState.pwGenMaxCharacters.value = range.end.toInt();
              await appState.save();
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Checkbox.adaptive(
              value: appState.pwGenUseLetters.value,
              onChanged: (value) {
                runAppFlow(context, () async {
                  appState.pwGenUseLetters.value = value!;
                  await appState.save();
                });
              },
            ),
            Flexible(
              child: Text(
                'Use letters',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox.adaptive(
              value: appState.pwGenUseNumbers.value,
              onChanged: (value) {
                runAppFlow(context, () async {
                  appState.pwGenUseNumbers.value = value!;
                  await appState.save();
                });
              },
            ),
            Flexible(
              child: Text(
                'Use numbers',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox.adaptive(
              value: appState.pwGenUseSpecialChars.value,
              onChanged: (value) {
                runAppFlow(context, () async {
                  appState.pwGenUseSpecialChars.value = value!;
                  await appState.save();
                });
              },
            ),
            Flexible(
              child: Text(
                'Use special characters',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
