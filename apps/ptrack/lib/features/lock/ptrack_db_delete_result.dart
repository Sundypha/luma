/// Outcome of attempting to remove the on-disk SQLite file used by the app database.
sealed class PtrackDbDeleteResult {
  const PtrackDbDeleteResult();
}

/// File existed and was deleted successfully.
final class PtrackDbDeleted extends PtrackDbDeleteResult {
  const PtrackDbDeleted();
}

/// No database file was present at the expected path.
final class PtrackDbNotFound extends PtrackDbDeleteResult {
  const PtrackDbNotFound();
}

/// Deletion failed (e.g. IO error). [cause] is for logging only.
final class PtrackDbDeleteFailed extends PtrackDbDeleteResult {
  const PtrackDbDeleteFailed(this.cause);
  final Object cause;
}
