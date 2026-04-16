import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clair/core/theme/app_theme.dart';
import 'package:clair/core/theme/appearance_provider.dart';
import 'package:clair/app/router.dart';

class CLAiRApp extends ConsumerWidget {
  const CLAiRApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);

    return MaterialApp.router(
      title: 'CLAiR',
      debugShowCheckedModeBanner: false,
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
    );
  }
}
