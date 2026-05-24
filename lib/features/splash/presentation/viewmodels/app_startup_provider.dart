// FutureProvider that exposes the resolved startup destination so
// SplashPage can await it. Per guide 26 §7.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/decide_startup_destination.dart';
import 'splash_di.dart';

final appStartupProvider = FutureProvider<StartupDestination>((ref) async {
  final usecase = ref.watch(decideStartupDestinationProvider);
  return usecase();
});
