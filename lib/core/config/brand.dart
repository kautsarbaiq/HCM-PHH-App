/// White-label brand switch. One codebase builds two apps:
///
///   PHH Housing      : flutter build apk --flavor phh --dart-define=BRAND=phh
///   Home Cloud Asia  : flutter build apk --flavor hca --dart-define=BRAND=hca
///
/// Each brand points at its OWN Supabase project via its own env file
/// (.env.phh / .env.hca), so the two apps have completely separate databases
/// and users.
class Brand {
  Brand._();

  static const String id = String.fromEnvironment('BRAND', defaultValue: 'hca');
  static const bool isPhh = id == 'phh';

  static const String appName = isPhh ? 'PHH Housing' : 'Home Cloud Asia';
  static const String envFile = isPhh ? '.env.phh' : '.env.hca';
  static const String logoAsset = isPhh
      ? 'assets/branding/logo_phh.png'
      : 'assets/branding/logo.png';
}
