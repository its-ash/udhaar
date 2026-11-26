import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../src/format.dart';
import '../src/models.dart';
import '../src/store.dart';

/// Bottom sheet to add or edit a transaction.
class TxnSheet extends StatefulWidget {
  const TxnSheet({super.key, required this.store, required this.personId, this.existing, this.gave = true});

  final LedgerStore store;
  final int personId;
  final Txn? existing;

  /// Initial direction for a new transaction.
  final bool gave;

  static Future<void> show(
    BuildContext context,
    LedgerStore store,
    int personId, {
    Txn? existing,
    bool gave = true,
  }) {
    return UiSheet.show<void>(
      context,
      title: existing == null ? (gave ? 'You gave' : 'You got') : 'Edit entry',
      child: TxnSheet(store: store, personId: personId, existing: existing, gave: gave),
    );
  }

  @override
  State<TxnSheet> createState() => _TxnSheetState();
}

class _TxnSheetState extends State<TxnSheet> {
  late bool _gave = widget.existing?.gave ?? widget.gave;
  late final _amount = TextEditingController(
    text: widget.existing == null ? '' : _plain(widget.existing!.paise),
  );
  late final _note = TextEditingController(text: widget.existing?.note);
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late DateTime? _due = widget.existing?.due;
  String? _error;
  bool _saving = false;

  static String _plain(int paise) =>
      paise % 100 == 0 ? '${paise ~/ 100}' : '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final paise = parsePaise(_amount.text);
    if (paise == null) {
      setState(() => _error = 'Enter an amount above 0');
      return;
    }
    final store = widget.store;
    final old = widget.existing;
    final note = _note.text;
    final gave = _gave;
    final date = dateOnly(_date);
    final due = _due;
    setState(() => _saving = true);
    try {
      if (due != null) {
        await store.reminders.requestPermission();
        if (!mounted) return;
      }
      if (old == null) {
        await store.addTxn(
          personId: widget.personId,
          paise: paise,
          gave: gave,
          date: date,
          note: note,
          due: due,
        );
      } else {
        await store.updateTxn(
          old.copyWith(
            paise: paise,
            gave: gave,
            date: date,
            note: note.trim(),
            due: due,
            clearDue: due == null,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UiColumn(
      gap: UiSpace.md,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiSegmentedControl<bool>(
          const [UiSegment(true, label: 'I gave'), UiSegment(false, label: 'I got')],
          value: _gave,
          expand: true,
          onChanged: (v) => setState(() => _gave = v),
        ),
        UiTextField(
          label: 'Amount (₹)',
          controller: _amount,
          error: _error,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() => _error = null),
        ),
        UiTextField(label: 'Note (optional)', controller: _note, textCapitalization: TextCapitalization.sentences),
        UiDateField(
          label: 'Date',
          value: _date,
          clearable: false,
          lastDate: DateTime.now().add(const Duration(days: 1)),
          onChanged: (d) => setState(() => _date = d ?? _date),
        ),
        UiDateField(
          label: 'Due date (optional, adds a reminder)',
          value: _due,
          firstDate: dateOnly(DateTime.now()),
          onChanged: (d) => setState(() => _due = d),
          helper: _due == null ? null : 'You will be notified on ${formatDate(_due!)} at 9:00.',
        ),
        const SizedBox(height: UiSpace.sm),
        UiButton('Save', loading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
