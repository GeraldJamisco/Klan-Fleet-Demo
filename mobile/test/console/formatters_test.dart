import 'package:flutter_test/flutter_test.dart';
import 'package:klan_fleet_mobile/console/core/formatters.dart';

void main() {
  test('longDate and shortDate', () {
    final d = DateTime(2026, 11, 12);
    expect(longDate(d), 'Thursday, 12 November 2026');
    expect(shortDate(d), '12 Nov 2026');
  });

  test('dayAndTime pads the time', () {
    expect(dayAndTime(DateTime(2026, 11, 13, 7, 5)), '13 Nov, 07:05');
  });

  test('greetingFor follows the hour', () {
    expect(greetingFor(DateTime(2026, 1, 1, 9)), 'Good morning');
    expect(greetingFor(DateTime(2026, 1, 1, 14)), 'Good afternoon');
    expect(greetingFor(DateTime(2026, 1, 1, 19)), 'Good evening');
  });

  test('ugxCompact', () {
    expect(ugxCompact(8400000), 'UGX 8.4M');
    expect(ugxCompact(42800000), 'UGX 42.8M');
    expect(ugxCompact(950000), 'UGX 950K');
    expect(ugxCompact(500), 'UGX 500');
    expect(ugxCompact(2000000), 'UGX 2M');
  });

  test('initialsOf and firstNameOf', () {
    expect(initialsOf('Gerald Jamisco'), 'GJ');
    expect(initialsOf('Gerald'), 'G');
    expect(initialsOf('  '), '?');
    expect(firstNameOf('Gerald Jamisco'), 'Gerald');
  });

  test('thousands', () {
    expect(thousands(482190), '482,190');
    expect(thousands(999), '999');
    expect(thousands(1000), '1,000');
    expect(thousands(-4850000), '-4,850,000');
  });
}
