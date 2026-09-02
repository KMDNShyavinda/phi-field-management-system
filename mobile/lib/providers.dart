import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/api/api_client.dart';
import 'data/db/app_database.dart';
import 'data/inspection/inspection_repository.dart';
import 'data/sync/sync_service.dart';
import 'domain/models.dart';

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());

final apiProvider = Provider<ApiClient>((ref) => ApiClient());

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(dbProvider), ref.watch(apiProvider));
});

final sessionProvider = FutureProvider<SessionUser?>((ref) {
  return ref.watch(apiProvider).cachedUser();
});

final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository(ref.watch(dbProvider));
});

final dataTickProvider = StateProvider<int>((ref) => 0);
