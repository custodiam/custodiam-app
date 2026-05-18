// DI for the splash feature. Provides DecideStartupDestination wired
// to the global AuthService. Per guide 26 §6.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/di/providers.dart';
import '../../domain/usecases/decide_startup_destination.dart';

final decideStartupDestinationProvider = Provider<DecideStartupDestination>(
  (ref) => DecideStartupDestination(ref.watch(authServiceProvider)),
);
