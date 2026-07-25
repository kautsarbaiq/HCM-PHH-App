import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web: the browser owns the better-auth session cookie; `withCredentials`
/// makes it ride along on every request (the server allows this via
/// CORS `credentials: true` + an origin allowlist).
http.Client createHttpClient() => BrowserClient()..withCredentials = true;

const bool browserManagesCookies = true;
