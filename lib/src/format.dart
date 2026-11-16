const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "5 Mar 2026".
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
