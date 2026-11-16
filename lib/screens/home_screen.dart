import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:theme/theme.dart';

import '../src/csv.dart';
import '../src/models.dart';
import '../src/store.dart';
import 'person_screen.dart';
import 'person_sheet.dart';
import 'settings_screen.dart';

/// People with their net balance, and the totals.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final LedgerStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LedgerStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    store.load();
  }

  Future<void> _export() async {
    if (store.txns.isEmpty) {
      context.showToast('Nothing to export yet');
      return;
    }
    final csv = buildCsv(store.people, store.txns);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: 'udhaar.csv')],
        fileNameOverrides: const ['udhaar.csv'],
        subject: 'Udhaar ledger',
      ),
    );
  }

  Future<void> _addPerson() async {
    final p = await PersonSheet.show(context, store);
    if (p != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PersonScreen(store: store, personId: p.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return UiScaffold(
          appBar: UiAppBar(
            title: 'Udhaar',
            actions: [
              UiIconButton(Icons.ios_share_rounded, tooltip: 'Export CSV', onPressed: _export),
              UiIconButton(
                Icons.settings_rounded,
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => SettingsScreen(store: store)),
                ),
              ),
            ],
          ),
          fab: UiFab(Icons.person_add_alt_1_rounded, label: 'Add person', onPressed: _addPerson),
          scrollable: store.ready && store.people.isNotEmpty,
          body: !store.ready
              ? const Center(child: UiSpinner(size: 28))
              : store.people.isEmpty
                  ? UiEmptyState(
                      title: 'No one yet',
                      message: 'Add a person, then note what you gave or got.',
                      icon: Icons.handshake_outlined,
                      action: UiButton('Add person', icon: Icons.person_add_alt_1_rounded, onPressed: _addPerson),
                    )
                  : _content(context),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final totals = store.totals;
    final people = store.sortedPeople;
    return UiColumn(
      gap: UiSpace.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TotalCard(label: "You'll get", paise: totals.toGet, status: UiStatus.success),
            ),
            const SizedBox(width: UiSpace.md),
            Expanded(
              child: _TotalCard(label: 'You owe', paise: totals.toGive, status: UiStatus.danger),
            ),
          ],
        ),
        UiListGroup(
          header: 'People',
          children: [
            for (final p in people)
              _PersonTile(
                person: p,
                balance: store.balanceFor(p.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => PersonScreen(store: store, personId: p.id)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 72),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.label, required this.paise, required this.status});

  final String label;
  final int paise;
  final UiStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(status);
    return UiCard(
      variant: UiCardVariant.filled,
      padding: const EdgeInsets.all(UiSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.text.labelMedium?.copyWith(color: context.colors.textMuted)),
          const SizedBox(height: UiSpace.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(paise), style: context.text.headlineSmall?.copyWith(color: tone.color)),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, required this.balance, required this.onTap});

  final Person person;
  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settled = balance == 0;
    final status = balance > 0 ? UiStatus.success : UiStatus.danger;
    return UiListTile(
      person.name,
      subtitle: settled ? 'Settled up' : (balance > 0 ? "You'll get" : 'You owe'),
      leading: UiAvatar(name: person.name),
      trailing: settled
          ? null
          : Text(
              formatMoney(balance.abs()),
              style: context.text.titleSmall?.copyWith(color: context.colors.tone(status).color),
            ),
      chevron: true,
      onTap: onTap,
    );
  }
}
