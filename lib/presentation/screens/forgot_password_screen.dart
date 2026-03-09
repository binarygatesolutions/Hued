import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:hued/core/theme/theme_ext.dart';
import 'package:hued/core/utils/animations.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_app_logo.dart';
import '../widgets/shared_text_field.dart';
import '../widgets/shared_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (state is Unauthenticated && ModalRoute.of(context)?.isCurrent == true) {
      // If we are currently in Unauthenticated state and on this screen,
      // it means the email was sent successfully (per AuthBloc logic).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LangKeys.passwordResetSent.tr()),
          backgroundColor: context.mintGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.goNamed(AppRouter.login);
    } else if (state is AuthError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.primary,
          behavior: SnackBarBehavior.floating,
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
                    LangKeys.forgotPasswordTitle.tr(),
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
                      LangKeys.enterEmailReset.tr(),
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
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            fillColor: Colors.grey[100],
                            onSubmitted: (_) {
                              if (state is! AuthLoading) {
                                _performReset();
                              }
                            },
                          ).animateEntrance(delayMs: 600),
                          const SizedBox(height: 40),
                          _buildResetButton(context, state),
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

  Widget _buildResetButton(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return SharedButton(
      onPressed: _performReset,
      text: LangKeys.sendResetLink.tr(),
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
    return TextButton(
      onPressed: () => context.goNamed(AppRouter.login),
      child: Text(
        LangKeys.backToLogin.tr(),
        style: TextStyle(
          color: context.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void _performReset() {
    if (_emailController.text.isNotEmpty) {
      context.read<AuthBloc>().add(
        ForgotPasswordRequested(_emailController.text.trim()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LangKeys.pleaseEnterEmail.tr())));
    }
  }
}
