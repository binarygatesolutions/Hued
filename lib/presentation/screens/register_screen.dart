import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:hued/core/navigation/app_router.dart';
import 'package:hued/core/theme/theme_ext.dart';
import 'package:hued/domain/entities/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import '../blocs/specialty_bloc.dart';
import '../widgets/shared_app_logo.dart';
import '../widgets/shared_text_field.dart';
import '../widgets/shared_button.dart';
import 'package:hued/core/utils/animations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  SpecialtyEntity? _selectedSpecialty;

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
                    LangKeys.createAccount.tr(),
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
                      LangKeys.joinWorkspace.tr(),
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
                            controller: _nameController,
                            label: LangKeys.fullName.tr(),
                            icon: Ionicons.person_outline,
                          ).animateListStep(index: 5),
                          const SizedBox(height: 20),
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
                                _performRegister();
                              }
                            },
                          ).animateListStep(index: 7),
                          const SizedBox(height: 20),
                          _buildRoleDropdown().animateListStep(index: 8),
                          if (_selectedRole == UserRole.worker) ...[
                            const SizedBox(height: 20),
                            _buildSpecialtyDropdown().animateListStep(index: 9),
                          ],
                          const SizedBox(height: 40),
                          _buildRegisterButton(context, state),
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<UserRole>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: LangKeys.accountType.tr(),
        prefixIcon: const Icon(Ionicons.person_circle_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: context.onSurface.withOpacity(0.05),
      ),
      isExpanded: true,
      items: [UserRole.client, UserRole.worker].map((role) {
        String localizedLabel;
        switch (role) {
          case UserRole.client:
            localizedLabel = LangKeys.roleClient.tr();
            break;
          case UserRole.worker:
            localizedLabel = LangKeys.roleWorker.tr();
            break;
          default:
            localizedLabel = role.label;
        }
        return DropdownMenuItem(
          value: role,
          child: Text(localizedLabel, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedRole = val;
            if (_selectedRole != UserRole.worker) {
              _selectedSpecialty = null;
            }
          });
        }
      },
    );
  }

  Widget _buildSpecialtyDropdown() {
    return BlocBuilder<SpecialtyBloc, SpecialtyState>(
      builder: (context, state) {
        return DropdownButtonFormField<SpecialtyEntity>(
          value: _selectedSpecialty,
          decoration: InputDecoration(
            labelText: LangKeys.specialty.tr(),
            prefixIcon: const Icon(Ionicons.briefcase_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: context.onSurface.withOpacity(0.05),
          ),
          isExpanded: true,
          items: state.specialties.map((specialty) {
            return DropdownMenuItem(
              value: specialty,
              child: Text(specialty.name, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            setState(() => _selectedSpecialty = val);
          },
        );
      },
    );
  }

  Widget _buildRegisterButton(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    return SharedButton(
      onPressed: _performRegister,
      text: LangKeys.submitSignUp.tr(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          LangKeys.alreadyHaveAccount.tr(),
          style: TextStyle(
            color: context.onSurface.withOpacity(0.4),
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            LangKeys.navSignIn.tr(),
            style: TextStyle(
              color: context.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  void _performRegister() {
    if (_emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _nameController.text.isNotEmpty) {
      if (_selectedRole == UserRole.worker && _selectedSpecialty == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LangKeys.pleaseSelectSpecialty.tr())),
        );
        return;
      }
      context.read<AuthBloc>().add(
        RegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          specialtyId: _selectedSpecialty?.id,
          specialtyName: _selectedSpecialty?.name,
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LangKeys.fillAllFields.tr())));
    }
  }
}
