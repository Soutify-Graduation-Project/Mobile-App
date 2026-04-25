import 'package:flutter/material.dart';

import 'core/accessibility/wcag_theme.dart';
import 'core/routing/app_router.dart';

class SoutifyApp extends StatelessWidget {
  const SoutifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soutify',
      theme: WcagTheme.buildTheme(),
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
