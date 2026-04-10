import 'package:flutter_test/flutter_test.dart';
import 'package:luma/features/lock/ptrack_db_delete_result.dart';
import 'package:luma/features/lock/reset_ptrack_database_file.dart';

void main() {
  test('closeAndDeletePtrackDatabaseFile returns failure and notifies hook', () async {
    PtrackDbDeleteResult? observed;
    final result = await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async {},
      deleteDatabaseFile: () async => const PtrackDbDeleteFailed('simulated io error'),
      onAfterDelete: (r) => observed = r,
    );

    expect(result, isA<PtrackDbDeleteFailed>());
    expect((result as PtrackDbDeleteFailed).cause, 'simulated io error');
    expect(observed, same(result));
  });

  test('closeAndDeletePtrackDatabaseFile returns deleted when delete succeeds', () async {
    final result = await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async {},
      deleteDatabaseFile: () async => const PtrackDbDeleted(),
    );
    expect(result, isA<PtrackDbDeleted>());
  });

  test('closeAndDeletePtrackDatabaseFile returns notFound when file absent', () async {
    final result = await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async {},
      deleteDatabaseFile: () async => const PtrackDbNotFound(),
    );
    expect(result, isA<PtrackDbNotFound>());
  });

  test('closeAndDeletePtrackDatabaseFile runs close before delete', () async {
    final order = <String>[];
    await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async => order.add('close'),
      deleteDatabaseFile: () async {
        order.add('delete');
        return const PtrackDbDeleted();
      },
    );
    expect(order, ['close', 'delete']);
  });

  test('onAfterDelete receives notFound for successful no-op delete', () async {
    PtrackDbDeleteResult? observed;
    final result = await closeAndDeletePtrackDatabaseFile(
      closeDatabase: () async {},
      deleteDatabaseFile: () async => const PtrackDbNotFound(),
      onAfterDelete: (r) => observed = r,
    );
    expect(result, isA<PtrackDbNotFound>());
    expect(observed, isA<PtrackDbNotFound>());
  });
}
