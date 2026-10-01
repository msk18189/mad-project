enum DeadlineStatus {
  upcoming,
  approaching,
  urgent,
  due,
  completed,
  missed;

  String get label {
    switch (this) {
      case DeadlineStatus.upcoming:
        return 'UPCOMING';
      case DeadlineStatus.approaching:
        return 'APPROACHING';
      case DeadlineStatus.urgent:
        return 'URGENT';
      case DeadlineStatus.due:
        return 'DUE NOW';
      case DeadlineStatus.completed:
        return 'COMPLETED';
      case DeadlineStatus.missed:
        return 'MISSED';
    }
  }

  static DeadlineStatus fromString(String? val) {
    if (val == null) return DeadlineStatus.upcoming;
    return DeadlineStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DeadlineStatus.upcoming,
    );
  }
}
