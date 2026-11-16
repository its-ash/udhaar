import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../src/models.dart';
import '../src/store.dart';

/// Bottom sheet to add or edit a person. Returns the saved person.
class PersonSheet extends StatefulWidget {
  const PersonSheet({super.key, required this.store, this.existing});

  final LedgerStore store;
  final Person? existing;

  static Future<Person?> show(BuildContext context, LedgerStore store, {Person? existing}) {
    return UiSheet.show<Person>(
      context,
      title: existing == null ? 'Add person' : 'Edit person',
      child: PersonSheet(store: store, existing: existing),
    );
  }

  @override
  State<PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<PersonSheet> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _vpa = TextEditingController(text: widget.existing?.vpa);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vpa.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final store = widget.store;
    final Person p;
    if (widget.existing == null) {
      p = await store.addPerson(name: name, phone: _phone.text, vpa: _vpa.text);
    } else {
      p = widget.existing!.copyWith(name: name, phone: _phone.text.trim(), vpa: _vpa.text.trim());
      await store.updatePerson(p);
    }
    if (mounted) Navigator.of(context).pop(p);
  }

  @override
  Widget build(BuildContext context) {
    return UiColumn(
      gap: UiSpace.md,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiTextField(
          label: 'Name',
          controller: _name,
          error: _error,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _error = null),
        ),
        UiTextField(label: 'Phone (optional)', controller: _phone, keyboardType: TextInputType.phone),
        UiTextField(
          label: 'UPI ID (optional)',
          hint: 'name@bank',
          helper: 'Used by the Pay button when you owe them.',
          controller: _vpa,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton('Save', onPressed: _save),
      ],
    );
  }
}
