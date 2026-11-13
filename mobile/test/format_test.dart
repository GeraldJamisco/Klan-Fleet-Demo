import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/core/format.dart';

void main() {
  test('formatUgx groups thousands', () {
    expect(formatUgx(0), 'UGX 0');
    expect(formatUgx(950), 'UGX 950');
    expect(formatUgx(372000), 'UGX 372,000');
    expect(formatUgx(1234567), 'UGX 1,234,567');
  });

  test('nextStatus follows the trip flow and stops at the end', () {
    expect(nextStatus('assigned'), 'picked_up');
    expect(nextStatus('picked_up'), 'in_transit');
    expect(nextStatus('in_transit'), 'delivered');
    expect(nextStatus('delivered'), isNull);
    expect(nextStatus('cancelled'), isNull);
  });

  test('isClosed covers delivered and cancelled only', () {
    expect(isClosed('delivered'), isTrue);
    expect(isClosed('cancelled'), isTrue);
    expect(isClosed('in_transit'), isFalse);
  });

  test('humanize turns snake_case into words', () {
    expect(humanize('cargo_damage'), 'Cargo damage');
    expect(humanize('delay'), 'Delay');
  });

  test('parseServerTime treats SQLite timestamps as UTC', () {
    final t = parseServerTime('2026-11-16 10:05:00');
    expect(t, isNotNull);
    expect(t!.toUtc().hour, 10);
    expect(t.toUtc().minute, 5);
  });

  test('parseServerTime accepts ISO strings and rejects junk', () {
    expect(parseServerTime('2026-11-16T10:05:00.000Z')!.toUtc().hour, 10);
    expect(parseServerTime(null), isNull);
    expect(parseServerTime('not a date'), isNull);
  });

  test('friendlyTime returns empty text for missing values', () {
    expect(friendlyTime(null), '');
    expect(friendlyTime(''), '');
  });
}
