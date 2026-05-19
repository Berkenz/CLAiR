import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/locale/app_locale_provider.dart';
import 'package:clair/core/locale/framework_locale_fallback.dart';
import 'package:clair/core/theme/app_theme.dart';
import 'package:clair/core/theme/appearance_provider.dart';
import 'package:clair/app/router.dart';
import 'package:clair/core/notifications/push_notification_bootstrap.dart';
import 'package:clair/l10n/app_localizations.dart';

class CLAiRApp extends ConsumerWidget {
  const CLAiRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final locale = ref.watch(appLocaleProvider);

    return PushNotificationBootstrap(
      child: MaterialApp.router(
      title: 'CLAiR',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        FallbackCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme(accent: appearance.accent),
      darkTheme: AppTheme.darkTheme(accent: appearance.accent),
      themeMode: appearance.flutterThemeMode,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(appearance.fontScale),
        ),
        child: child!,
      ),
      routerConfig: ref.watch(routerProvider),
    ),
    );
  }
}
