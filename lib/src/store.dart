import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'reminders.dart';

/// All app data: people, transactions and the user's own UPI details.
/// Stored as one JSON string in SharedPreferences. Fully offline.
class LedgerStore extends ChangeNotifier {
  LedgerStore({Reminders? reminders}) : reminders = reminders ?? NoReminders();

  static const _key = 'udhaar_ledger_v1';

  final Reminders reminders;

  List<Person> people = [];
  List<Txn> txns = [];
  String myName = '';
  String myVpa = '';
  bool ready = false;
  int _nextId = 1;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      people = [for (final p in (j['people'] as List? ?? [])) Person.fromJson(p as Map<String, dynamic>)];
      txns = [for (final t in (j['txns'] as List? ?? [])) Txn.fromJson(t as Map<String, dynamic>)];
      myName = (j['myName'] as String?) ?? '';
      myVpa = (j['myVpa'] as String?) ?? '';
      _nextId = (j['nextId'] as int?) ?? 1;
    }
    ready = true;
    notifyListeners();
    // Re-plan reminders so they match the data (e.g. after a restore).
    for (final t in txns) {
      final p = personById(t.personId);
      if (p != null && t.due != null) await reminders.schedule(t, p);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'people': [for (final p in people) p.toJson()],
        'txns': [for (final t in txns) t.toJson()],
        'myName': myName,
        'myVpa': myVpa,
        'nextId': _nextId,
      }),
    );
  }

  Future<void> _commit() async {
    notifyListeners();
    await _save();
  }

  Person? personById(int id) {
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Txn> txnsOf(int personId) =>
      txns.where((t) => t.personId == personId).toList()..sort((a, b) => b.date.compareTo(a.date));

  int balanceFor(int personId) => balanceOf(txns.where((t) => t.personId == personId));

  Totals get totals => Totals.of(people.map((p) => balanceFor(p.id)));

  /// People sorted by the size of their balance, largest first; settled people last.
  List<Person> get sortedPeople {
    final list = [...people];
    list.sort((a, b) {
      final d = balanceFor(b.id).abs().compareTo(balanceFor(a.id).abs());
      return d != 0 ? d : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<Person> addPerson({required String name, String phone = '', String vpa = ''}) async {
    final p = Person(id: _nextId++, name: name.trim(), phone: phone.trim(), vpa: vpa.trim());
    people = [...people, p];
    await _commit();
    return p;
  }

  Future<void> updatePerson(Person p) async {
    people = [for (final x in people) x.id == p.id ? p : x];
    await _commit();
  }

  Future<void> deletePerson(int id) async {
    for (final t in txns.where((t) => t.personId == id)) {
      await reminders.cancel(t.id);
    }
    txns = txns.where((t) => t.personId != id).toList();
    people = people.where((p) => p.id != id).toList();
    await _commit();
  }

  Future<Txn> addTxn({
    required int personId,
    required int paise,
    required bool gave,
    required DateTime date,
    String note = '',
    DateTime? due,
  }) async {
    final t = Txn(id: _nextId++, personId: personId, paise: paise, gave: gave, date: date, note: note.trim(), due: due);
    txns = [...txns, t];
    await _commit();
    final p = personById(personId);
    if (p != null) await reminders.schedule(t, p);
    return t;
  }

  Future<void> updateTxn(Txn t) async {
    txns = [for (final x in txns) x.id == t.id ? t : x];
    await _commit();
    final p = personById(t.personId);
    if (p != null) await reminders.schedule(t, p);
  }

  Future<void> deleteTxn(int id) async {
    txns = txns.where((t) => t.id != id).toList();
    await reminders.cancel(id);
    await _commit();
  }

  /// Adds the opposite transaction that brings the balance to zero and cancels pending reminders.
  Future<void> settleUp(int personId, {DateTime? now}) async {
    final bal = balanceFor(personId);
    if (bal == 0) return;
    for (final t in txns.where((t) => t.personId == personId)) {
      await reminders.cancel(t.id);
    }
    txns = [
      for (final t in txns)
        if (t.personId == personId && t.due != null) t.copyWith(clearDue: true) else t,
    ];
    final t = Txn(
      id: _nextId++,
      personId: personId,
      paise: bal.abs(),
      gave: bal < 0, // you owed them: you gave it back. They owed you: you got it.
      date: now ?? DateTime.now(),
      note: 'Settled up',
    );
    txns = [...txns, t];
    await _commit();
  }

  Future<void> saveProfile({required String name, required String vpa}) async {
    myName = name.trim();
    myVpa = vpa.trim();
    await _commit();
  }
}
