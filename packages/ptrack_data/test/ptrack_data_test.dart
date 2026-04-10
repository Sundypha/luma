import 'package:flutter_test/flutter_test.dart';
import 'package:ptrack_data/ptrack_data.dart';

void main() {
  test('packageName is stable', () {
    expect(PtrackData.packageName, 'ptrack_data');
  });
}
