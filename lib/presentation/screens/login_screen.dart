import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:hued/core/theme/theme_ext.dart';
import '../widgets/shared_app_logo.dart';
import '../widgets/shared_text_field.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_button.dart';
import 'package:hued/core/utils/animations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      context.goNamed(AppRouter.dashboard);
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: _onAuthStateChanged,
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const SharedAppLogo(
                    height: 66,
                    heroTag: 'app_logo',
                  ).animateEntrance(),
                  const SizedBox(height: 35),
                  Text(
                    LangKeys.welcomeBack.tr(),
                    style: context.textTheme.displayLarge?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ).animateEntrance(delayMs: 200),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      LangKeys.enterCredentials.tr(),
                      style: TextStyle(
                        color: context.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ).animateEntrance(delayMs: 300),
                  ),
                  const SizedBox(height: 35),

                  Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: context.onSurface.withOpacity(0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SharedTextField(
                            controller: _emailController,
                            label: LangKeys.emailAddress.tr(),
                            icon: Ionicons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ).animateListStep(index: 6),
                          const SizedBox(height: 20),
                          SharedTextField(
                            controller: _passwordController,
                            label: LangKeys.passwordLabel.tr(),
                            icon: Ionicons.lock_closed_outline,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (state is! AuthLoading) {
                                _performLogin();
                              }
                            },
                          ).animateListStep(index: 7),
                          const SizedBox(height: 40),
                          _buildLoginButton(context, state),
                        ],
                      ),
                    ),
                  ).animateScale(delayMs: 400),
                  const SizedBox(height: 22),
                  _buildFooter(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return SharedButton(
      onPressed: _performLogin,
      text: LangKeys.signIn.tr(),
      isLoading: isLoading,
      showShadow: true,
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 16,
        letterSpacing: 1.2,
      ),
    ).animateScale(delayMs: 600);
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              LangKeys.dontHaveAccount.tr(),
              style: TextStyle(
                color: context.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed(AppRouter.register),
              child: Text(
                LangKeys.signUp.tr(),
                style: TextStyle(
                  color: context.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: () => context.pushNamed(AppRouter.forgotPassword),
          child: Text(
            LangKeys.forgotPassword.tr(),
            style: TextStyle(
              color: context.primary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  void _performLogin() {
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      context.read<AuthBloc>().add(
        LoginRequested(_emailController.text, _passwordController.text),
      );
    }
  }
}
