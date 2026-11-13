/// Small, pure helpers (no Flutter imports) so they are easy to unit test.
library;

const List<String> tripFlow = ['assigned', 'picked_up', 'in_transit', 'delivered'];

const Map<String, String> statusLabels = {
  'assigned': 'Assigned',
  'picked_up': 'Picked up',
  'in_transit': 'In transit',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

const Map<String, String> nextStepLabels = {
  'assigned': 'Mark as picked up',
  'picked_up': 'Start trip (in transit)',
  'in_transit': 'Mark as delivered',
};

const List<String> incidentCategories = [
  'breakdown',
  'accident',
  'delay',
  'cargo_damage',
  'other',
];

String statusLabel(String status) => statusLabels[status] ?? status;

/// The status a driver may move a trip to next, or null if the trip is closed.
String? nextStatus(String status) {
  final i = tripFlow.indexOf(status);
  if (i == -1 || i >= tripFlow.length - 1) return null;
  return tripFlow[i + 1];
}

bool isClosed(String status) => status == 'delivered' || status == 'cancelled';

String humanize(String snake) {
  if (snake.isEmpty) return snake;
  final spaced = snake.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// 372000 -> "UGX 372,000"
String formatUgx(num amount) {
  final digits = amount.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return 'UGX $sign${buffer.toString()}';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Accepts SQLite timestamps ("2026-11-16 10:05:00", UTC) and ISO strings.
DateTime? parseServerTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  var text = raw.trim();
  if (!text.contains('T')) text = text.replaceFirst(' ', 'T');
  final hasZone = text.endsWith('Z') || RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(text);
  if (!hasZone) text = '${text}Z';
  return DateTime.tryParse(text)?.toLocal();
}

/// "16 Nov, 13:05"
String friendlyTime(String? raw) {
  final t = parseServerTime(raw);
  if (t == null) return '';
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${_months[t.month - 1]}, $hh:$mm';
}
