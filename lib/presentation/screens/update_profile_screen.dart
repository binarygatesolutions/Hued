import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hued/presentation/blocs/auth_event.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_profile_avatar.dart';
import '../widgets/glass_container.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_text_field.dart';
import '../widgets/shared_button.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? profileImg;
  String? profileImgUrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is Authenticated) {
      final user = state.user;
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      profileImgUrl = user.profile;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        UpdateProfile(fullName: _nameController.text, profileImg: profileImg),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: SharedAppBar(
        title: LangKeys.editProfile.tr(),
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: context.purple.withOpacity(0.03),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(duration: 1000.ms),

          // Main Content
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildAvatarSection(),
                          const SizedBox(height: 40),
                          GlassContainer(
                            padding: const EdgeInsets.all(24),
                            opacity: 0.6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPremiumTextField(
                                  context,
                                  controller: _nameController,
                                  hint: LangKeys.enterYourName.tr(),
                                  label: LangKeys.fullName.tr(),
                                  icon: Ionicons.person_outline,
                                  validator: (v) => v?.isEmpty ?? true
                                      ? LangKeys.nameRequired.tr()
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _buildPremiumTextField(
                                  context,
                                  controller: _emailController,
                                  hint: LangKeys.enterYourEmail.tr(),
                                  label: LangKeys.emailAddress.tr(),
                                  readOnly: true,
                                  icon: Ionicons.mail_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => v?.isEmpty ?? true
                                      ? LangKeys.emailRequired.tr()
                                      : null,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
                          const SizedBox(height: 40),
                          _buildSaveButton(context),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(60),
        onTap: () async {
          final picked = await FilePicker.platform.pickFiles(
            type: FileType.image,
            allowMultiple: false,
            allowCompression: true,
          );
          if (picked != null) {
            profileImg = File(picked.files.first.path!);
            setState(() {});
          }
        },
        child: Stack(
          children: [
            SharedProfileAvatar(
              name: _nameController.text,
              radius: 60,
              showBorder: true,
              profileImg: profileImg,
              imageUrl: profileImgUrl,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.background, width: 3),
                ),
                child: const Icon(
                  Ionicons.camera,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ).animate().scale(curve: Curves.easeOutBack),
      ),
    );
  }

  Widget _buildPremiumTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return SharedTextField(
      controller: controller,
      label: label,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType ?? TextInputType.text,
      validator: validator,
      readOnly: readOnly,
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return SharedButton(
          onPressed: _submitForm,
          text: LangKeys.saveChanges.tr(),
          isLoading: state is AuthUpdatingProfile,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05);
      },
    );
  }
}
