// Domain-level enum for the three values the theme switcher exposes.
// Maps 1:1 to Flutter's ThemeMode in the infrastructure layer; kept
// separate from the framework type so the domain layer stays Dart-pure
// (guide 26 §2).

enum AppThemeMode {
  system,
  light,
  dark,
}
