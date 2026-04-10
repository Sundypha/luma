import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

void main() {
  test('packageName is stable', () {
    expect(PtrackDomain.packageName, 'ptrack_domain');
  });
}
