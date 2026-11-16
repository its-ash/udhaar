import 'package:flutter_test/flutter_test.dart';
import 'package:udhaar/src/csv.dart';
import 'package:udhaar/src/models.dart';
import 'package:udhaar/src/upi.dart';

Txn t(int id, int person, int paise, bool gave) =>
    Txn(id: id, personId: person, paise: paise, gave: gave, date: DateTime(2026, 3, 5));

void main() {
  group('balance', () {
    test('gave minus got', () {
      expect(balanceOf([t(1, 1, 50000, true), t(2, 1, 20000, false)]), 30000);
    });
    test('negative when you owe', () {
      expect(balanceOf([t(1, 1, 10000, false), t(2, 1, 2500, true)]), -7500);
    });
    test('empty is zero', () => expect(balanceOf([]), 0));
    test('totals split by sign', () {
      final totals = Totals.of([30000, -7500, 0, 500]);
      expect(totals.toGet, 30500);
      expect(totals.toGive, 7500);
      expect(totals.net, 23000);
    });
  });

  group('money', () {
    test('parsePaise', () {
      expect(parsePaise('1,250.5'), 125050);
      expect(parsePaise('₹100'), 10000);
      expect(parsePaise('0.05'), 5);
      expect(parsePaise('0'), isNull);
      expect(parsePaise('abc'), isNull);
      expect(parsePaise(''), isNull);
      expect(parsePaise('1.234'), isNull);
    });
    test('formatMoney uses Indian grouping', () {
      expect(formatMoney(0), '₹0');
      expect(formatMoney(99900), '₹999');
      expect(formatMoney(123456700), '₹12,34,567');
      expect(formatMoney(125050), '₹1,250.50');
      expect(formatMoney(-500), '-₹5');
    });
  });

  group('upi', () {
    test('builds link', () {
      expect(
        buildUpiLink(vpa: 'ash@upi', name: 'Ash Jangid', paise: 125050),
        'upi://pay?pa=ash@upi&pn=Ash%20Jangid&am=1250.50&cu=INR',
      );
    });
    test('whole rupees keep two decimals', () {
      expect(buildUpiLink(vpa: 'a@b', name: 'A', paise: 50000), 'upi://pay?pa=a@b&pn=A&am=500.00&cu=INR');
    });
    test('null without vpa or amount', () {
      expect(buildUpiLink(vpa: ' ', name: 'A', paise: 100), isNull);
      expect(buildUpiLink(vpa: 'a@b', name: 'A', paise: 0), isNull);
    });
    test('reminder includes amount and link', () {
      final m = reminderMessage(personName: 'Ravi', paise: 50000, myName: 'Ash', myVpa: 'ash@upi');
      expect(m, contains('Hi Ravi'));
      expect(m, contains('₹500'));
      expect(m, contains('upi://pay?pa=ash@upi&pn=Ash&am=500.00&cu=INR'));
    });
    test('reminder without vpa has no link', () {
      final m = reminderMessage(personName: 'Ravi', paise: 50000, myName: '', myVpa: '');
      expect(m, isNot(contains('upi://')));
    });
  });

  test('csv escapes and sorts', () {
    final csv = buildCsv(
      const [Person(id: 1, name: 'Rao, S', vpa: 'rao@upi')],
      [t(1, 1, 125050, true)],
    );
    final lines = csv.trim().split('\r\n');
    expect(lines.first, startsWith('Date,Person'));
    expect(lines[1], '2026-03-05,"Rao, S",,rao@upi,Gave,1250.50,,');
  });
}
