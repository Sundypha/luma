import 'package:flutter/material.dart';
import 'package:ptrack_data/ptrack_data.dart';
import 'package:ptrack_domain/ptrack_domain.dart';

/// Temporary stub for TabShell wiring; replaced by the full home surface in Task 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.database,
    required this.calendar,
  });

  final PeriodRepository repository;
  final PtrackDatabase database;
  final PeriodCalendarContext calendar;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
