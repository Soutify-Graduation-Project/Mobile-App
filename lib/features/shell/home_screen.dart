import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/large_primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                child: Center(
                  child: Image.asset(
                    AppAssets.soutifyLogo,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'اختر التخصيص لتسجيل الجمل، أو الكلام المباشر للتعرف على الصوت.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LargePrimaryButton(
                label: 'التخصيص',
                semanticLabel: 'فتح التسجيل للتخصيص',
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRouter.enrollment,
                ),
              ),
              const SizedBox(height: 12),
              LargePrimaryButton(
                label: 'الكلام المباشر',
                semanticLabel: 'فتح التعرف على الكلام المباشر',
                onPressed: () => Navigator.of(context).pushNamed(
                  AppRouter.liveAsr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
