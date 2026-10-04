/// Build configuration from `--dart-define` / `--dart-define-from-file`
/// (brief §11: no secrets in the repository). Pure Dart, so the release
/// preflight (`tool/check_release_config.dart`) uses the same rules.
library;

enum OctoMode { fake, real }

/// The keys this app reads.
abstract final class ConfigKeys {
  static const mode = 'OCTO_MODE';
  static const apiBase = 'OCTO_API_BASE';
  static const supabaseUrl = 'SUPABASE_URL';
  static const supabaseAnonKey = 'SUPABASE_ANON_KEY';

  /// Where email links and Google send people back (on the Supabase
  /// redirect allow list). Defaults to `octo://auth-callback`.
  static const authRedirect = 'OCTO_AUTH_REDIRECT';

  /// `firebase` turns push on (needs the Firebase config files).
  static const push = 'OCTO_PUSH';
}

class AppConfig {
  const AppConfig({
    required this.mode,
    required this.apiBase,
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.authRedirect = defaultAuthRedirect,
    this.pushEnabled = false,
  });

  static const defaultAuthRedirect = 'octo://auth-callback';

  /// Fake mode with the simulator, for tests and debug builds.
  static final fake = AppConfig(
    mode: OctoMode.fake,
    apiBase: Uri.parse('https://www.october.dev'),
  );

  final OctoMode mode;
  final Uri apiBase;
  final Uri? supabaseUrl;
  final String? supabaseAnonKey;
  final String authRedirect;
  final bool pushEnabled;

  bool get isFake => mode == OctoMode.fake;
}

/// The result of reading the configuration: a usable [AppConfig], or the
/// reason the build can't run. Never falls back to fake mode silently.
sealed class ConfigResult {
  const ConfigResult();
}

final class ConfigOk extends ConfigResult {
  const ConfigOk(this.config);

  final AppConfig config;
}

final class ConfigProblem extends ConfigResult {
  const ConfigProblem(this.problems);

  /// For developers only (logs, the preflight); never shown to people.
  final List<String> problems;
}

/// Reads the configuration compiled into this build.
ConfigResult configFromEnvironment({required bool isRelease}) =>
    parseConfig(const {
      ConfigKeys.mode: String.fromEnvironment(ConfigKeys.mode),
      ConfigKeys.apiBase: String.fromEnvironment(ConfigKeys.apiBase),
      ConfigKeys.supabaseUrl: String.fromEnvironment(ConfigKeys.supabaseUrl),
      ConfigKeys.supabaseAnonKey: String.fromEnvironment(
        ConfigKeys.supabaseAnonKey,
      ),
      ConfigKeys.authRedirect: String.fromEnvironment(ConfigKeys.authRedirect),
      ConfigKeys.push: String.fromEnvironment(ConfigKeys.push),
    }, isRelease: isRelease);

/// Validates [values]. Fake mode is refused in release builds; real mode
/// needs every value it will use, over https.
ConfigResult parseConfig(
  Map<String, Object?> values, {
  required bool isRelease,
}) {
  String text(String key) {
    final v = values[key];
    return v is String ? v.trim() : '';
  }

  final problems = <String>[];
  final modeText = text(ConfigKeys.mode);
  final mode = switch (modeText) {
    'fake' => OctoMode.fake,
    'real' => OctoMode.real,
    _ => null,
  };
  if (mode == null) {
    problems.add(
      modeText.isEmpty
          ? '${ConfigKeys.mode} is not set (use fake or real)'
          : '${ConfigKeys.mode} must be fake or real, not "$modeText"',
    );
    return ConfigProblem(problems);
  }
  if (mode == OctoMode.fake && isRelease) {
    return const ConfigProblem(['fake mode is not allowed in a release build']);
  }

  Uri? httpsUri(String key, {required bool required}) {
    final value = text(key);
    if (value.isEmpty) {
      if (required) problems.add('$key is not set');
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      problems.add('$key must be an https URL');
      return null;
    }
    return uri;
  }

  final real = mode == OctoMode.real;
  final apiBase =
      httpsUri(ConfigKeys.apiBase, required: false) ??
      Uri.parse('https://www.october.dev');
  final supabaseUrl = httpsUri(ConfigKeys.supabaseUrl, required: real);
  final anonKey = text(ConfigKeys.supabaseAnonKey);
  if (real && anonKey.isEmpty) {
    problems.add('${ConfigKeys.supabaseAnonKey} is not set');
  }
  final redirectText = text(ConfigKeys.authRedirect);
  final redirect = Uri.tryParse(
    redirectText.isEmpty ? AppConfig.defaultAuthRedirect : redirectText,
  );
  if (redirect == null ||
      redirect.scheme.isEmpty ||
      redirect.scheme == 'http') {
    problems.add('${ConfigKeys.authRedirect} must be an app link or https URL');
  }
  final pushText = text(ConfigKeys.push);
  if (pushText.isNotEmpty && pushText != 'firebase') {
    problems.add('${ConfigKeys.push} must be firebase or empty');
  }
  if (problems.isNotEmpty) return ConfigProblem(problems);
  return ConfigOk(
    AppConfig(
      mode: mode,
      apiBase: apiBase,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: anonKey.isEmpty ? null : anonKey,
      authRedirect: redirect!.toString(),
      pushEnabled: pushText == 'firebase',
    ),
  );
}
