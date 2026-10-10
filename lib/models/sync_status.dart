enum SyncStatus { pending, syncing, synced, failed }

extension SyncStatusX on SyncStatus {
  String get value => name;

  static SyncStatus fromValue(String? value) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncStatus.pending,
    );
  }
}
