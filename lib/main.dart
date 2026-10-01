import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/local_database_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline persistent local database & storage
  await LocalDatabaseService().init();
  await StorageService().init();

  // Initialize notifications service
  await NotificationService().init();

  runApp(
    const ProviderScope(
      child: DeadlineApp(),
    ),
  );
}
