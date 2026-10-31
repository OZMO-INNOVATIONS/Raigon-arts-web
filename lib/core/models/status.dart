import 'package:flutter/material.dart';

enum Status {
  pending,
  confirmed,
  onHold,
  cancelled,
  editingProgress,
  dispatchForPrinting,
  printReceived,
  framingProcess,
  completed,
  @Deprecated('Use editingProgress or framingProcess')
  inProgress;

  String get label => switch (this) {
    Status.pending => 'Pending',
    Status.confirmed => 'Confirmed',
    Status.onHold => 'On Hold',
    Status.cancelled => 'Cancelled',
    Status.editingProgress => 'Editing Progress',
    Status.dispatchForPrinting => 'Dispatch for Printing',
    Status.printReceived => 'Print Received',
    Status.framingProcess => 'Framing Process',
    Status.completed => 'Completed',
    Status.inProgress => 'In Progress',
  };

  Color get color => switch (this) {
    Status.pending => const Color(0xFFD97706),
    Status.confirmed => const Color(0xFF2563EB),
    Status.onHold => const Color(0xFFEA580C),
    Status.cancelled => const Color(0xFFDC2626),
    Status.editingProgress => const Color(0xFF7C3AED),
    Status.dispatchForPrinting => const Color(0xFF0D9488),
    Status.printReceived => const Color(0xFF0284C7),
    Status.framingProcess => const Color(0xFF9E7728),
    Status.completed => const Color(0xFF16A34A),
    Status.inProgress => const Color(0xFF9E7728),
  };

  /// The 9 standardized workflow statuses required by Raigon Art Order Management
  static List<Status> get standardStatuses => [
    Status.pending,
    Status.confirmed,
    Status.onHold,
    Status.cancelled,
    Status.editingProgress,
    Status.dispatchForPrinting,
    Status.printReceived,
    Status.framingProcess,
    Status.completed,
  ];

  /// The 7 linear production stages (excluding On Hold and Cancelled)
  static List<Status> get productionStages => [
    Status.pending,
    Status.confirmed,
    Status.editingProgress,
    Status.dispatchForPrinting,
    Status.printReceived,
    Status.framingProcess,
    Status.completed,
  ];

  bool get isProductionStage => productionStages.contains(this);
}
