import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:theme/theme.dart';

import '../src/format.dart';
import '../src/models.dart';
import '../src/store.dart';
import '../src/upi.dart';
import 'person_sheet.dart';
import 'txn_sheet.dart';

/// One person: balance, actions (gave / got, remind, pay, settle up) and the entries.
class PersonScreen extends StatelessWidget {
  const PersonScreen({super.key, required this.store, required this.personId});

  final LedgerStore store;
  final int personId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final person = store.personById(personId);
        if (person == null) return const UiScaffold(body: SizedBox.shrink());
        final balance = store.balanceFor(personId);
        final entries = store.txnsOf(personId);
        return UiScaffold(
          appBar: UiAppBar(
            title: person.name,
            actions: [
              UiIconButton(
                Icons.edit_outlined,
                tooltip: 'Edit person',
                onPressed: () => PersonSheet.show(context, store, existing: person),
              ),
              UiIconButton(Icons.delete_outline_rounded, tooltip: 'Delete person', onPressed: () => _deletePerson(context, person)),
            ],
          ),
          scrollable: true,
          body: UiColumn(
            gap: UiSpace.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BalanceCard(person: person, balance: balance),
              Row(
                children: [
                  Expanded(
                    child: UiButton(
                      'I gave',
                      icon: Icons.north_east_rounded,
                      onPressed: () => TxnSheet.show(context, store, personId, gave: true),
                    ),
                  ),
                  const SizedBox(width: UiSpace.md),
                  Expanded(
                    child: UiButton(
                      'I got',
                      icon: Icons.south_west_rounded,
                      variant: UiButtonVariant.secondary,
                      onPressed: () => TxnSheet.show(context, store, personId, gave: false),
                    ),
                  ),
                ],
              ),
              if (balance > 0) ...[
                UiButton(
                  'Send reminder',
                  icon: Icons.ios_share_rounded,
                  variant: UiButtonVariant.secondary,
                  onPressed: () => _remind(person, balance, entries),
                ),
                if (_whatsAppUrl(person, _message(person, balance, entries)) != null)
                  UiButton(
                    'Remind on WhatsApp',
                    icon: Icons.chat_rounded,
                    variant: UiButtonVariant.ghost,
                    onPressed: () => UiUrl.open(_whatsAppUrl(person, _message(person, balance, entries))!),
                  ),
              ],
              if (balance < 0 && person.vpa.trim().isNotEmpty)
                UiButton('Pay ${formatMoney(-balance)}', icon: Icons.payments_rounded, onPressed: () => _pay(context, person, -balance)),
              if (balance != 0)
                UiButton(
                  'Settle up',
                  icon: Icons.check_circle_outline_rounded,
                  variant: UiButtonVariant.ghost,
                  onPressed: () => _settle(context, person, balance),
                ),
              if (entries.isEmpty)
                const UiEmptyState(title: 'No entries', message: 'Tap I gave or I got to add one.', compact: true)
              else
                UiListGroup(
                  header: 'History',
                  children: [for (final t in entries) _TxnTile(txn: t, onTap: () => _entryActions(context, t))],
                ),
            ],
          ),
        );
      },
    );
  }

  DateTime? _nextDue(List<Txn> entries) {
    final today = dateOnly(DateTime.now());
    final dues = [for (final t in entries) if (t.gave && t.due != null) t.due!];
    if (dues.isEmpty) return null;
    dues.sort();
    return dues.firstWhere((d) => !d.isBefore(today), orElse: () => dues.last);
  }

  String _message(Person p, int balance, List<Txn> entries) => reminderMessage(
        personName: p.name,
        paise: balance,
        myName: store.myName,
        myVpa: store.myVpa,
        due: _nextDue(entries),
        formatDate: formatDate,
      );

  Future<void> _remind(Person p, int balance, List<Txn> entries) {
    return SharePlus.instance.share(ShareParams(text: _message(p, balance, entries)));
  }

  String? _whatsAppUrl(Person p, String message) {
    var digits = p.phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) digits = '91$digits';
    if (digits.length < 11) return null;
    return 'https://wa.me/$digits?text=${Uri.encodeComponent(message)}';
  }

  Future<void> _pay(BuildContext context, Person p, int paise) async {
    final link = buildUpiLink(vpa: p.vpa, name: p.name, paise: paise);
    if (link == null) return;
    final ok = await UiUrl.open(link);
    if (!ok && context.mounted) context.showToast('No UPI app found');
  }

  Future<void> _settle(BuildContext context, Person p, int balance) async {
    final ok = await UiDialog.confirm(
      context,
      title: 'Settle up with ${p.name}?',
      message: balance > 0
          ? 'This records ${formatMoney(balance)} received and clears the balance.'
          : 'This records ${formatMoney(-balance)} paid and clears the balance.',
      confirmLabel: 'Settle up',
    );
    if (ok) await store.settleUp(p.id);
  }

  Future<void> _deletePerson(BuildContext context, Person p) async {
    final ok = await UiDialog.confirm(
      context,
      title: 'Delete ${p.name}?',
      message: 'All their entries are deleted too.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok) return;
    await store.deletePerson(p.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _entryActions(BuildContext context, Txn t) async {
    final v = await UiActionSheet.show<String>(
      context,
      actions: const [
        UiSheetAction('Edit', value: 'edit', icon: Icons.edit_outlined),
        UiSheetAction('Delete', value: 'delete', icon: Icons.delete_outline_rounded, destructive: true),
      ],
    );
    if (!context.mounted) return;
    if (v == 'edit') {
      await TxnSheet.show(context, store, personId, existing: t);
    } else if (v == 'delete') {
      final ok = await UiDialog.confirm(
        context,
        title: 'Delete this entry?',
        message: '${formatMoney(t.paise)} on ${formatDate(t.date)}',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (ok) await store.deleteTxn(t.id);
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.person, required this.balance});

  final Person person;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final settled = balance == 0;
    final status = balance > 0 ? UiStatus.success : UiStatus.danger;
    final label = settled ? 'All settled up' : (balance > 0 ? '${person.name} owes you' : 'You owe ${person.name}');
    return UiCard(
      variant: UiCardVariant.filled,
      padding: const EdgeInsets.all(UiSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.bodySmall),
          const SizedBox(height: UiSpace.xs),
          Text(
            formatMoney(balance.abs()),
            style: context.text.displaySmall?.copyWith(color: settled ? context.colors.text : context.colors.tone(status).color),
          ),
          if (person.vpa.trim().isNotEmpty) ...[
            const SizedBox(height: UiSpace.xs),
            Text(person.vpa, style: context.text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn, required this.onTap});

  final Txn txn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = txn.gave ? UiStatus.success : UiStatus.danger;
    final parts = [
      formatDate(txn.date),
      if (txn.note.isNotEmpty) txn.note,
      if (txn.due != null) 'due ${formatDate(txn.due!)}',
    ];
    return UiListTile(
      txn.gave ? 'You gave' : 'You got',
      subtitle: parts.join(' · '),
      icon: txn.gave ? Icons.north_east_rounded : Icons.south_west_rounded,
      iconStatus: status,
      trailing: Text(
        formatMoney(txn.paise),
        style: context.text.titleSmall?.copyWith(color: context.colors.tone(status).color),
      ),
      onTap: onTap,
    );
  }
}
