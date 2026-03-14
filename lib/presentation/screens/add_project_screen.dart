import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart' show GoRouterHelper;
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/responsive_layout.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/project_state.dart';
import 'package:ionicons/ionicons.dart';
import '../widgets/glass_container.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_text_field.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_button.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      String creatorId = '';
      if (authState is Authenticated) {
        creatorId = authState.user.id;
      }

      setState(() => _isCreating = true);
      context.read<ProjectBloc>().add(
        CreateProject(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          creatorId: creatorId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = ResponsiveLayout.isLargeScreen(context);

    return Scaffold(
      backgroundColor: context.background,
      appBar: SharedAppBar(
        title: LangKeys.newProject.tr(),
        showBackButton: true,
      ),
      body: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (_isCreating && state is ProjectInitial) {
            context.pop();
          } else if (state is ProjectError) {
            setState(() => _isCreating = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: !isLarge ? 24 : 40,
            vertical: 32,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LangKeys.projectDetails.tr(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: context.onSurface.withOpacity(0.4),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.1),
                          const SizedBox(height: 24),
                          SharedTextField(
                                controller: _titleController,
                                label: LangKeys.projectTitle.tr(),
                                icon: Ionicons.folder_outline,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? LangKeys.pleaseEnterTitle.tr()
                                    : null,
                              )
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: -0.05),
                          const SizedBox(height: 20),
                          SharedTextField(
                                controller: _descriptionController,
                                label: LangKeys.description.tr(),
                                icon: Ionicons.document_text_outline,
                                maxLines: 4,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? LangKeys.pleaseEnterDescription.tr()
                                    : null,
                              )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideX(begin: -0.05),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  SharedButton(
                        onPressed: _submit,
                        text: LangKeys.createProject.tr(),
                        isLoading: _isCreating,
                        height: 52,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.2,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .scale(
                        curve: Curves.easeOutBack,
                        begin: const Offset(0.9, 0.9),
                      ),
                  const SizedBox(height: 100), // Bottom padding for scroll
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
