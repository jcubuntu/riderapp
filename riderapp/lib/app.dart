import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/deep_link/deep_link.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';

class RiderApp extends ConsumerStatefulWidget {
  const RiderApp({super.key});

  @override
  ConsumerState<RiderApp> createState() => _RiderAppState();
}

class _RiderAppState extends ConsumerState<RiderApp> {
  @override
  void initState() {
    super.initState();
    // Initialize deep link handler after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
    });
  }

  void _initializeDeepLinks() {
    final router = ref.read(routerProvider);
    final deepLinkNotifier = ref.read(deepLinkNotifierProvider.notifier);
    deepLinkNotifier.initialize(router);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Watch deep link state for potential side effects
    ref.listen<DeepLinkState>(deepLinkNotifierProvider, (previous, next) {
      // Handle deep link state changes if needed
      if (next is DeepLinkFailed) {
        debugPrint('Deep link failed: ${next.error}');
      }
    });

    return MaterialApp.router(
      title: 'RiderApp',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme
      theme: AppTheme.lightTheme,

      // Router
      routerConfig: router,
    );
  }
}
