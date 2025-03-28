import 'package:auspex/ViewModel/notification_viewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: provider.enableNotifications,
                onChanged:
                    (value) =>
                        provider.updateSettings(enableNotifications: value),
              ),
              SwitchListTile(
                title: const Text('Enable Sound'),
                value: provider.enableSound,
                onChanged:
                    provider.enableNotifications
                        ? (value) => provider.updateSettings(enableSound: value)
                        : null,
              ),
              SwitchListTile(
                title: const Text('Enable Vibration'),
                value: provider.enableVibration,
                onChanged:
                    provider.enableNotifications
                        ? (value) =>
                            provider.updateSettings(enableVibration: value)
                        : null,
              ),
              ListTile(
                title: const Text('Check Time'),
                subtitle: Text('${provider.checkTime.format(context)}'),
                onTap:
                    provider.enableNotifications
                        ? () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: provider.checkTime,
                          );
                          if (time != null) {
                            provider.updateSettings(checkTime: time);
                          }
                        }
                        : null,
              ),
            ],
          );
        },
      ),
    );
  }
}
