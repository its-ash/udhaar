import 'models.dart';

/// Builds a `upi://pay` link. [paise] is formatted as rupees with two decimals.
/// Returns null when the VPA is empty or the amount is not positive.
String? buildUpiLink({required String vpa, required String name, required int paise}) {
  final pa = vpa.trim();
  if (pa.isEmpty || paise <= 0) return null;
  final am = '${paise ~/ 100}.${(paise % 100).toString().padLeft(2, '0')}';
  final pn = Uri.encodeComponent(name.trim());
  return 'upi://pay?pa=$pa&pn=$pn&am=$am&cu=INR';
}

/// A polite reminder to send to someone who owes you [paise].
/// The UPI link points to *your* VPA (from Settings) when it is set.
String reminderMessage({
  required String personName,
  required int paise,
  required String myName,
  required String myVpa,
  DateTime? due,
  String Function(DateTime)? formatDate,
}) {
  final amount = formatMoney(paise);
  final b = StringBuffer('Hi $personName, a gentle reminder about the ');
  b.write(amount);
  b.write(' you owe me');
  if (due != null) {
    b.write(' (due ${(formatDate ?? _date)(due)})');
  }
  b.write('. Whenever you get a moment, please send it over. Thank you!');
  final link = buildUpiLink(vpa: myVpa, name: myName, paise: paise);
  if (link != null) {
    b.write('\n\nPay with UPI: $link');
  }
  if (myName.trim().isNotEmpty) b.write('\n- ${myName.trim()}');
  return b.toString();
}

String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
