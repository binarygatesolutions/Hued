import 'package:flutter/material.dart';
import 'package:hued/presentation/widgets/shared_app_logo.dart';
import '../../core/theme/theme_ext.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: Center(child: SharedAppLogo()),
    );
  }
}
