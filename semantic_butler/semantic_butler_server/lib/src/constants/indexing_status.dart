/// Standardized status values for indexing operations.
/// Use these constants instead of string literals for consistency.
library;

/// Status values for FileIndex model
class FileIndexStatus {
  static const String pending = 'pending';
  static const String indexing = 'indexing';
  static const String indexed = 'indexed';
  static const String failed = 'failed';
  static const String skipped = 'skipped';

  static const List<String> all = [pending, indexing, indexed, failed, skipped];

  static bool isValid(String status) => all.contains(status);
}

/// Status values for IndexingJob model
class JobStatus {
  static const String queued = 'queued';
  static const String running = 'running';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [queued, running, completed, failed, cancelled];
  static const List<String> active = [queued, running];
  static const List<String> terminal = [completed, failed, cancelled];

  static bool isValid(String status) => all.contains(status);
  static bool isActive(String status) => active.contains(status);
  static bool isTerminal(String status) => terminal.contains(status);
}

/// Status values for IndexingJobDetail (per-file status within a job)
class JobDetailStatus {
  static const String pending = 'pending';
  static const String extracting = 'extracting';
  static const String embedding = 'embedding';
  static const String complete = 'complete';
  static const String failed = 'failed';
  static const String skipped = 'skipped';

  static const List<String> all = [
    pending,
    extracting,
    embedding,
    complete,
    failed,
    skipped,
  ];
  static const List<String> inProgress = [extracting, embedding];
  static const List<String> terminal = [complete, failed, skipped];

  static bool isValid(String status) => all.contains(status);
  static bool isInProgress(String status) => inProgress.contains(status);
  static bool isTerminal(String status) => terminal.contains(status);
}
