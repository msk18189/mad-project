import 'package:flutter/material.dart';
import 'deadline_category.dart';

export 'deadline_category.dart';

extension DeadlineCategoryExtensions on DeadlineCategory {
  String get label => DeadlineCategoryConfig.from(this).displayName;
  String get emoji => DeadlineCategoryConfig.from(this).emoji;
  IconData get icon => DeadlineCategoryConfig.from(this).icon;
  Color get color => DeadlineCategoryConfig.from(this).color;
  String get description => DeadlineCategoryConfig.from(this).description;
}
