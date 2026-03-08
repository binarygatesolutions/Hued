import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_button.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: SharedAppBar(title: LangKeys.createProject.tr()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                LangKeys.startNewJourney.tr(),
                style: context.textTheme.displayLarge?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                LangKeys.fillDetailsForNewProject.tr(),
                style: TextStyle(color: context.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: LangKeys.projectTitle.tr(),
                  prefixIcon: const Icon(Ionicons.briefcase_outline),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? LangKeys.required.tr()
                    : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: LangKeys.description.tr(),
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Ionicons.document_text_outline),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? LangKeys.required.tr()
                    : null,
              ),
              const SizedBox(height: 48),
              SharedButton(
                onPressed: _submit,
                text: LangKeys.createProject.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        context.read<ProjectBloc>().add(
          CreateProject(
            title: _titleController.text,
            description: _descriptionController.text,
            creatorId: authState.user.id,
          ),
        );
        context.pop();
      }
    }
  }
}
