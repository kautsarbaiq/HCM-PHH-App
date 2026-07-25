import 'package:http/http.dart' as http;

/// Mobile/desktop: plain client — we capture and replay the better-auth
/// session cookie manually (see InventoryAuth).
http.Client createHttpClient() => http.Client();

/// On IO platforms the app manages the session cookie itself.
const bool browserManagesCookies = false;
