import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_palette.dart';

enum Status {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label => switch (this) {
    Status.pending => 'Pending',
    Status.inProgress => 'In Progress',
    Status.completed => 'Completed',
    Status.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    Status.pending || Status.inProgress => AppPalette.statusGold,
    Status.completed => AppPalette.statusGreen,
    Status.cancelled => AppPalette.statusRed,
  };
}
