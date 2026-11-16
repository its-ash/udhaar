/// A person you lend to or borrow from.
class Person {
  const Person({required this.id, required this.name, this.phone = '', this.vpa = ''});

  final int id;
  final String name;
  final String phone;

  /// The person's UPI address (used by the Pay button when you owe them).
  final String vpa;

  Person copyWith({String? name, String? phone, String? vpa}) =>
      Person(id: id, name: name ?? this.name, phone: phone ?? this.phone, vpa: vpa ?? this.vpa);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'phone': phone, 'vpa': vpa};

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: (j['phone'] as String?) ?? '',
        vpa: (j['vpa'] as String?) ?? '',
      );
}

/// One money movement with a person. Amounts are whole paise (1/100 rupee).
class Txn {
  const Txn({
    required this.id,
    required this.personId,
    required this.paise,
    required this.gave,
    required this.date,
    this.note = '',
    this.due,
  });

  final int id;
  final int personId;

  /// Always positive.
  final int paise;

  /// True: you gave money (they owe you more). False: you got money (you owe more, or they paid back).
  final bool gave;
  final DateTime date;
  final String note;

  /// Optional due date for a reminder notification.
  final DateTime? due;

  /// Signed effect on the balance: positive means they owe you.
  int get signed => gave ? paise : -paise;

  Txn copyWith({int? paise, bool? gave, DateTime? date, String? note, DateTime? due, bool clearDue = false}) => Txn(
        id: id,
        personId: personId,
        paise: paise ?? this.paise,
        gave: gave ?? this.gave,
        date: date ?? this.date,
        note: note ?? this.note,
        due: clearDue ? null : (due ?? this.due),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'personId': personId,
        'paise': paise,
        'gave': gave,
        'date': date.millisecondsSinceEpoch,
        'note': note,
        'due': due?.millisecondsSinceEpoch,
      };

  factory Txn.fromJson(Map<String, dynamic> j) => Txn(
        id: j['id'] as int,
        personId: j['personId'] as int,
        paise: j['paise'] as int,
        gave: j['gave'] as bool,
        date: DateTime.fromMillisecondsSinceEpoch(j['date'] as int),
        note: (j['note'] as String?) ?? '',
        due: j['due'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['due'] as int),
      );
}

/// Net balance in paise from a list of transactions: positive = they owe you, negative = you owe them.
int balanceOf(Iterable<Txn> txns) => txns.fold(0, (sum, t) => sum + t.signed);

/// Totals over per-person balances.
class Totals {
  const Totals({required this.toGet, required this.toGive});

  /// Sum of positive balances (paise).
  final int toGet;

  /// Sum of the amounts you owe (paise, positive).
  final int toGive;

  int get net => toGet - toGive;

  factory Totals.of(Iterable<int> balances) {
    var get = 0;
    var give = 0;
    for (final b in balances) {
      if (b > 0) get += b;
      if (b < 0) give += -b;
    }
    return Totals(toGet: get, toGive: give);
  }
}

/// Parses user input like "1,250.5" to paise. Returns null when empty, invalid or not positive.
int? parsePaise(String input) {
  final s = input.replaceAll(',', '').replaceAll('₹', '').trim();
  if (s.isEmpty) return null;
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
  if (m == null) return null;
  final rupees = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(2, '0');
  final paise = rupees * 100 + int.parse(frac.isEmpty ? '0' : frac);
  return paise > 0 ? paise : null;
}

/// "₹1,23,456" or "₹1,234.50" with Indian digit grouping. Decimals only when needed.
String formatMoney(int paise, {bool sign = false}) {
  final neg = paise < 0;
  final abs = paise.abs();
  final rupees = abs ~/ 100;
  final rest = abs % 100;
  var digits = rupees.toString();
  if (digits.length > 3) {
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (head.length > 2) {
      parts.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) parts.insert(0, head);
    digits = '${parts.join(',')},$tail';
  }
  final frac = rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}';
  final prefix = neg ? '-' : (sign && paise > 0 ? '+' : '');
  return '$prefix₹$digits$frac';
}
