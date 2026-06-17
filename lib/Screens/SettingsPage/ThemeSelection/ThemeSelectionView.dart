// lib/Screens/SettingsPage/ThemeSelection/ThemeSelectionView.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controllers/SettingsController.dart';
import '../../../util/AppTheme.dart';

class ThemeSelectionView extends StatelessWidget {
  ThemeSelectionView({super.key});

  final SettingsController controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: Obx(() {
        final current = AppThemeOption.fromLabel(
          controller.settings.value.currentTheme,
        );

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (final option in AppThemeOption.values)
              RadioListTile<AppThemeOption>(
                value: option,
                groupValue: current,
                onChanged: (selected) {
                  if (selected != null) controller.updateTheme(selected);
                },
                secondary: Icon(option.icon),
                title: Text(option.label),
                subtitle: Text(_subtitle(option)),
              ),
          ],
        );
      }),
    );
  }

  String _subtitle(AppThemeOption option) {
    switch (option) {
      case AppThemeOption.system:
        return 'Match your device setting';
      case AppThemeOption.light:
        return 'Always use the light theme';
      case AppThemeOption.dark:
        return 'Always use the dark theme';
    }
  }
}
