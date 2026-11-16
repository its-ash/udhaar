import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../src/store.dart';

/// Your name and UPI ID for reminders, then Appearance, Updates and Developer.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final LedgerStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final _name = TextEditingController(text: widget.store.myName);
  late final _vpa = TextEditingController(text: widget.store.myVpa);

  @override
  void dispose() {
    _name.dispose();
    _vpa.dispose();
    super.dispose();
  }

  void _save() => widget.store.saveProfile(name: _name.text, vpa: _vpa.text);

  @override
  Widget build(BuildContext context) {
    return UiScaffold(
      appBar: const UiAppBar(title: 'Settings'),
      scrollable: true,
      body: UiColumn(
        gap: UiSpace.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSection(
            title: 'Your payment details',
            subtitle: 'Added to the reminder you share, so people can pay you by UPI.',
            child: UiColumn(
              gap: UiSpace.md,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiTextField(
                  label: 'Your name',
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _save(),
                ),
                UiTextField(
                  label: 'Your UPI ID',
                  hint: 'name@bank',
                  controller: _vpa,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _save(),
                ),
              ],
            ),
          ),
          const UiAppearanceSection(),
          const UiUpdateSection(storeId: 'udhaar'),
          const UiDeveloperSection(),
        ],
      ),
    );
  }
}
