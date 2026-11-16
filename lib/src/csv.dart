import 'models.dart';

String _cell(String s) {
  if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _day(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _amount(int paise) => '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';

/// All transactions as CSV: Date, Person, Phone, UPI, Type, Amount (INR), Note, Due.
String buildCsv(List<Person> people, List<Txn> txns) {
  final byId = {for (final p in people) p.id: p};
  final sorted = [...txns]..sort((a, b) => a.date.compareTo(b.date));
  final b = StringBuffer('Date,Person,Phone,UPI,Type,Amount (INR),Note,Due\r\n');
  for (final t in sorted) {
    final p = byId[t.personId];
    b.write([
      _day(t.date),
      _cell(p?.name ?? ''),
      _cell(p?.phone ?? ''),
      _cell(p?.vpa ?? ''),
      t.gave ? 'Gave' : 'Got',
      _amount(t.paise),
      _cell(t.note),
      t.due == null ? '' : _day(t.due!),
    ].join(','));
    b.write('\r\n');
  }
  return b.toString();
}
