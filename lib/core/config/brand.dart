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

  // Default = phh (the original app / the existing adminhousing.vercel.app).
  // Home Cloud Asia builds pass --dart-define=BRAND=hca explicitly.
  static const String id = String.fromEnvironment('BRAND', defaultValue: 'phh');
  static const bool isPhh = id == 'phh';

  static const String appName = isPhh ? 'PHH Housing' : 'HomeCloudAsia';
  static const String envFile = isPhh ? '.env.phh' : '.env.hca';
  static const String logoAsset = isPhh
      ? 'assets/branding/logo_phh.png'
      : 'assets/branding/logo.png';

  /// Public web origin used in shareable links (event invitations, voucher
  /// QR codes). These links outlive the app: a printed voucher QR keeps
  /// pointing here forever, so the origin must be one we can repoint by DNS
  /// rather than one owned by the current host.
  ///
  /// Override at build time once a custom domain is live, without touching
  /// this file or re-testing the app:
  ///   flutter build ... --dart-define=WEB_BASE_URL=https://app.homecloudasia.com
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: _defaultWebBaseUrl,
  );

  static const String _defaultWebBaseUrl = isPhh
      ? 'https://adminhousing.vercel.app'
      : 'https://home-cloudasia.vercel.app';
}
