import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión del build leída del pubspec en runtime: versionName + número de
/// build, p. ej. `0.1.0+7`. `package_info_plus` lee exactamente lo que el
/// build incrustó desde `pubspec.yaml` (`version:`).
///
/// Es un FutureProvider porque el plugin usa platform channels; en una VM
/// de tests sin mock la llamada falla y el consumidor trata el valor como
/// "no disponible" (no muestra nada), sin romper.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version}+${info.buildNumber}';
});
