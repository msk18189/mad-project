import 'package:flutter/material.dart';
import 'deadline_priority.dart';

export 'deadline_priority.dart';

extension DeadlinePriorityExtensions on DeadlinePriority {
  String get label => DeadlinePriorityConfig.from(this).label;
  Color get color => DeadlinePriorityConfig.from(this).color;
  Color get textColor => DeadlinePriorityConfig.from(this).textColor;
  int get weight => DeadlinePriorityConfig.from(this).weight;
  String get description => DeadlinePriorityConfig.from(this).description;
}
