class ActivityLog {
  ActivityLog({
    required this.ruleName,
    required this.contact,
    required this.detail,
    this.success = true,
    this.isTest = false,
  }) : time = DateTime.now();

  final DateTime time;
  final String ruleName;
  final String contact;
  final String detail;
  final bool success;
  final bool isTest;

  /// Real customer runs only (excludes tests and "You" housekeeping entries).
  bool get isCustomerRun => !isTest && contact != 'You';
}
