/// Display helpers for the manager console (no Flutter imports).
library;

const List<String> _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "Thursday, 12 November 2026"
String longDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// "12 Nov 2026"
String shortDate(DateTime d) =>
    '${d.day} ${_monthNames[d.month - 1].substring(0, 3)} ${d.year}';

/// "13 Nov, 07:00"
String dayAndTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_monthNames[d.month - 1].substring(0, 3)}, $hh:$mm';
}

String greetingFor(DateTime d) {
  if (d.hour < 12) return 'Good morning';
  if (d.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// 8400000 -> "UGX 8.4M", 42800000 -> "UGX 42.8M", 950000 -> "UGX 950K".
String ugxCompact(num amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 1000000) {
    return 'UGX $sign${_trim(abs / 1000000)}M';
  }
  if (abs >= 1000) {
    return 'UGX $sign${_trim(abs / 1000)}K';
  }
  return 'UGX $sign${abs.round()}';
}

String _trim(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

/// "Gerald Jamisco" -> "GJ"
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String firstNameOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  return parts.isEmpty || parts.first.isEmpty ? name : parts.first;
}

/// 482190 -> "482,190"
String thousands(num value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-${buffer.toString()}' : buffer.toString();
}
