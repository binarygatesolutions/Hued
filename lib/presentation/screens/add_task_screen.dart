import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hued/presentation/widgets/shared_app_bar.dart';
import 'package:ionicons/ionicons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_state.dart';
import '../blocs/project_event.dart';
import '../widgets/shared_text_field.dart';
import '../widgets/email_search_picker.dart';
import '../widgets/shared_button.dart';
import 'package:hued/core/utils/animations.dart';

class AddTaskScreen extends StatefulWidget {
  final ProjectEntity project;

  const AddTaskScreen({super.key, required this.project});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  bool _isSubmitting = false;

  // Worker selection — only for non-client roles
  List<UserEntity> _projectWorkers = [];
  List<String> _selectedWorkerIds = [];
  bool _loadingWorkers = false;

  @override
  void initState() {
    super.initState();
    _loadProjectWorkers();
  }

  Future<void> _loadProjectWorkers() async {
    final workerIds = widget.project.workerIds;
    if (workerIds.isEmpty) return;

    setState(() => _loadingWorkers = true);
    final List<UserEntity> workers = [];
    for (var i = 0; i < workerIds.length; i += 10) {
      final chunk = workerIds.sublist(
        i,
        (i + 10 > workerIds.length) ? workerIds.length : i + 10,
      );
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          workers.add(UserEntity.fromJson(data));
        }
      } catch (_) {}
    }
    if (mounted)
      setState(() {
        _projectWorkers = workers;
        _loadingWorkers = false;
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.theme.colorScheme.copyWith(
              primary: context.primary,
              surface: context.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final role = authState.user.role;
    final isClient = role == UserRole.client;
    final bool isApproved = !isClient;

    // Non-clients must assign at least one worker (if any workers exist on project)
    if (!isClient && _projectWorkers.isNotEmpty && _selectedWorkerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please assign at least one worker to this task'),
          backgroundColor: context.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    context.read<ProjectBloc>().add(
      AddTask(
        projectId: widget.project.id,
        title: _titleController.text,
        description: _descriptionController.text,
        deadline: _deadline,
        priority: _priority.name,
        isApproved: isApproved,
        creatorId: authState.user.id,
        assignedWorkerIds: _selectedWorkerIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isClient =
        authState is Authenticated && authState.user.role == UserRole.client;

    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (_isSubmitting && state is ProjectInitial) {
          context.pop();
        } else if (state is ProjectError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.background,
        extendBodyBehindAppBar: true,
        appBar: SharedAppBar(title: LangKeys.addTask.tr()),
        body: Stack(
          children: [
            _buildBackground(context),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 130,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Container(
                      padding: const EdgeInsets.all(32),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              LangKeys.taskDetails.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: context.onSurface.withOpacity(0.4),
                              ),
                            ).animateEntrance(delayMs: 400),
                            const SizedBox(height: 24),
                            SharedTextField(
                              controller: _titleController,
                              label: LangKeys.taskTitle.tr(),
                              icon: Ionicons.checkbox_outline,
                              validator: (v) => v?.isEmpty ?? true
                                  ? LangKeys.required.tr()
                                  : null,
                            ).animateEntrance(delayMs: 500),
                            const SizedBox(height: 20),
                            SharedTextField(
                              controller: _descriptionController,
                              label: LangKeys.description.tr(),
                              icon: Ionicons.document_text_outline,
                              maxLines: 3,
                              validator: (v) => v?.isEmpty ?? true
                                  ? LangKeys.required.tr()
                                  : null,
                            ).animateEntrance(delayMs: 600),
                            const SizedBox(height: 32),
                            Text(
                              LangKeys.timelineAndUrgency.tr(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: context.onSurface.withOpacity(0.4),
                              ),
                            ).animateEntrance(delayMs: 700),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPrioritySelector()
                                      .animateEntrance(delayMs: 800),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDeadlinePicker().animateEntrance(
                                    delayMs: 800,
                                  ),
                                ),
                              ],
                            ),
                            // Worker assignment section — hidden for clients
                            if (!isClient) ...[
                              const SizedBox(height: 32),
                              Text(
                                'ASSIGN WORKERS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: context.onSurface.withOpacity(0.4),
                                ),
                              ).animateEntrance(delayMs: 900),
                              const SizedBox(height: 16),
                              _buildWorkerPicker(
                                context,
                              ).animateEntrance(delayMs: 950),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ).animateScale(delayMs: 400),
                  const SizedBox(height: 48),
                  _buildSubmitButton(context).animateEntrance(delayMs: 1000),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerPicker(BuildContext context) {
    if (_loadingWorkers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_projectWorkers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.onSurface.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(
              Ionicons.information_circle_outline,
              size: 18,
              color: context.onSurface.withOpacity(0.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No workers assigned to this project yet.\nAdd workers in Team Management.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.onSurface.withOpacity(0.5),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MultiEmailSearchPicker(
      label: LangKeys.assignWorkers.tr(),
      initialUsers: _projectWorkers,
      initialSelectedIds: _selectedWorkerIds,
      filterRoles: const [UserRole.worker],
      onChanged: (selected) {
        setState(() {
          _selectedWorkerIds = List.from(selected);
        });
      },
    );
  }

  Widget _buildBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primary;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.black : const Color(0xFFFDFDFF),
      child: Stack(
        children: [
          Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(isDark ? 0.1 : 0.05),
                        primaryColor.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .move(
                begin: Offset.zero,
                end: const Offset(-40, 60),
                duration: 10.seconds,
                curve: Curves.easeInOut,
              ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SharedButton(
      onPressed: _submitForm,
      text: LangKeys.createTask.tr(),
      showShadow: true,
      disabled: _selectedWorkerIds.isEmpty,
      textStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 16,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LangKeys.priority.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: context.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.onSurface.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskPriority>(
              value: _priority,
              dropdownColor: context.surface,
              isExpanded: true,
              icon: Icon(
                Ionicons.chevron_down_outline,
                size: 16,
                color: context.primary,
              ),
              items: TaskPriority.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(
                    p.name.tr().toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LangKeys.deadline.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: context.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 56,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.onSurface.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Icon(
                  Ionicons.calendar_outline,
                  size: 18,
                  color: context.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_deadline),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
