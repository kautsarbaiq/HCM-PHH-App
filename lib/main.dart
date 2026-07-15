import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/brand.dart';
import 'core/routing/app_router.dart';
import 'core/services/push_service.dart';
import 'core/services/realtime_sync.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Each brand ships its own Supabase project credentials.
  await dotenv.load(fileName: Brand.envFile);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    // Sessions persist on BOTH web and mobile: a logged-in user stays logged
    // in until they explicitly log out (client request, 15/07 point 1).
  );

  // Push notifications (mobile only; no-op on web, never blocks startup).
  unawaited(PushService.init());

  runApp(const ProviderScope(child: HCMApp()));
}

class HCMApp extends ConsumerWidget {
  const HCMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    // Initialize ScreenUtil for responsive UI based on a standard mobile design draft size (e.g., iPhone 14)
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return RealtimeSync(
          child: MaterialApp.router(
            title: Brand.appName,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: pushMessengerKey,
            theme: AppTheme.lightTheme,
            locale: lang.locale,
            supportedLocales: const [Locale('en'), Locale('ms'), Locale('zh')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
