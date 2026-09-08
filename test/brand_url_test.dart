import 'package:flutter_test/flutter_test.dart';
import 'package:hcm_app/core/config/brand.dart';

/// Shareable links (event invitations, voucher QR codes) outlive the app — a
/// printed QR keeps resolving to whatever origin was baked in at build time.
/// The origin must therefore be overridable without a code change.
void main() {
  test('web base url is an https origin with no trailing slash', () {
    expect(Brand.webBaseUrl, startsWith('https://'));
    expect(Brand.webBaseUrl, isNot(endsWith('/')));
  });

  test('never an IP address — a moved server must be a DNS change', () {
    final looksLikeIp = RegExp(r'^https?://\d{1,3}(\.\d{1,3}){3}');
    expect(looksLikeIp.hasMatch(Brand.webBaseUrl), isFalse);
  });

  test('defaults to the brand host when WEB_BASE_URL is not passed', () {
    // No --dart-define in `flutter test`, so this exercises the fallback.
    expect(Brand.webBaseUrl, contains(Brand.isPhh ? 'adminhousing' : 'cloudasia'));
  });
}
