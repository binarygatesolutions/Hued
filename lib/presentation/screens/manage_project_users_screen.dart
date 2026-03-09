import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hued/presentation/widgets/custom_loading.dart';
import 'package:hued/presentation/widgets/shared_app_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:hued/presentation/widgets/shared_button.dart';
import 'package:hued/presentation/widgets/shared_profile_avatar.dart';
import 'package:ionicons/ionicons.dart';
import '../../domain/entities/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../blocs/project_bloc.dart';
import '../blocs/project_event.dart';
import '../blocs/project_state.dart';
import '../widgets/email_search_picker.dart';
import '../../core/utils/animations.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';

class ManageProjectUsersScreen extends StatefulWidget {
  final ProjectEntity project;

  const ManageProjectUsersScreen({super.key, required this.project});

  @override
  State<ManageProjectUsersScreen> createState() =>
      _ManageProjectUsersScreenState();
}

class _ManageProjectUsersScreenState extends State<ManageProjectUsersScreen> {
  late List<String> _supervisorIds;
  late List<String> _managerIds;
  late List<String> _clientIds;
  late List<String> _workerIds;
  bool _hasChanges = false;
  bool isLoading = true;
  bool _isSaving = false;
  List<UserEntity> initialUsers = [];
  Map<String, String> _workerManagerMap = {};

  @override
  void initState() {
    super.initState();
    _supervisorIds = List.from(widget.project.supervisorIds);
    _managerIds = List.from(widget.project.managerIds);
    _clientIds = List.from(widget.project.clientIds);
    _workerIds = List.from(widget.project.workerIds);
    _workerManagerMap = Map.from(widget.project.workerManagerMap);
    loadInitialUsers();
  }

  Future<void> loadInitialUsers() async {
    final allUserIds = {
      ..._supervisorIds,
      ..._managerIds,
      ..._clientIds,
      ..._workerIds,
    }.toList();

    if (allUserIds.isEmpty) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    final List<UserEntity> fetchedUsers = [];
    for (var i = 0; i < allUserIds.length; i += 10) {
      final chunk = allUserIds.sublist(
        i,
        (i + 10 > allUserIds.length) ? allUserIds.length : i + 10,
      );
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          fetchedUsers.add(UserEntity.fromJson(data));
        }
      } catch (e) {
        debugPrint('Error fetching user chunk: $e');
      }
    }

    if (mounted) {
      setState(() {
        initialUsers = fetchedUsers;
        isLoading = false;
      });
    }
  }

  void _saveChanges() {
    if (_workerIds.isNotEmpty) {
      for (final workerId in _workerIds) {
        final pmId = _workerManagerMap[workerId];
        if (pmId == null || !_managerIds.contains(pmId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LangKeys.assignPmToWorker.tr()),
              backgroundColor: context.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    }

    _workerManagerMap.removeWhere(
      (wId, pmId) => !_workerIds.contains(wId) || !_managerIds.contains(pmId),
    );

    setState(() => _isSaving = true);
    context.read<ProjectBloc>().add(
      UpdateProjectUsers(
        projectId: widget.project.id,
        supervisorIds: _supervisorIds,
        managerIds: _managerIds,
        clientIds: _clientIds,
        workerIds: _workerIds,
        workerManagerMap: _workerManagerMap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: SharedAppBar(title: LangKeys.teamManagement.tr()),
        body: const Center(child: CustomLoading()),
      );
    }

    return BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (_isSaving && state is ProjectInitial) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LangKeys.userAssignmentsUpdated.tr()),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ProjectError) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = authState.user;
          // Admins and supervisors manage the project team
          final canManage =
              user.role == UserRole.admin || user.role == UserRole.supervisor;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: SharedAppBar(title: LangKeys.teamManagement.tr()),
            body: Stack(
              children: [
                _buildBackground(context),
                SafeArea(
                  child: canManage
                      ? _buildManagementContent(context)
                      : _buildRestrictedAccess(context),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CustomLoading()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestrictedAccess(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Ionicons.lock_closed_outline,
            size: 64,
            color: context.onSurface.withOpacity(0.1),
          ).animateEntrance(),
          const SizedBox(height: 24),
          Text(
            LangKeys.adminAccessOnly.tr(),
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ).animateEntrance(delayMs: 100),
          const SizedBox(height: 12),
          Text(
            LangKeys.noPermissionToManageUsers.tr(),
            style: TextStyle(color: context.onSurface.withOpacity(0.5)),
          ).animateEntrance(delayMs: 200),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Ionicons.arrow_back),
            label: Text(LangKeys.goBack.tr()),
          ).animateEntrance(delayMs: 300),
        ],
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = context.primary;
    final secondaryColor = context.purple;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark ? Colors.black : const Color(0xFFFDFDFF),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -100,
            child:
                Container(
                      width: 450,
                      height: 450,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withOpacity(isDark ? 0.18 : 0.1),
                            primaryColor.withOpacity(0),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: Offset.zero,
                      end: const Offset(-50, 70),
                      duration: 12.seconds,
                      curve: Curves.easeInOut,
                    ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child:
                Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryColor.withOpacity(isDark ? 0.15 : 0.08),
                            secondaryColor.withOpacity(0),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: Offset.zero,
                      end: const Offset(70, -50),
                      duration: 15.seconds,
                      curve: Curves.easeInOut,
                    ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementContent(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(context).animateEntrance(),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      LangKeys.managementAndOversight.tr(),
                      Ionicons.shield_checkmark_outline,
                    ).animateEntrance(delayMs: 200),
                    const SizedBox(height: 20),
                    _buildPickerWithLabel(
                      label: LangKeys.supervisors.tr(),
                      ids: _supervisorIds,
                      role: UserRole.supervisor,
                      onChanged: (ids) => setState(() {
                        _supervisorIds = ids;
                        _hasChanges = true;
                      }),
                    ).animateEntrance(delayMs: 300),
                    const SizedBox(height: 16),
                    _buildPickerWithLabel(
                      label: LangKeys.projectManagers.tr(),
                      ids: _managerIds,
                      role: UserRole.projectManager,
                      onChanged: (ids) => setState(() {
                        _managerIds = ids;
                        _hasChanges = true;
                      }),
                    ).animateEntrance(delayMs: 400),
                    const SizedBox(height: 40),
                    _buildSectionHeader(
                      LangKeys.stakeholders.tr(),
                      Ionicons.people_outline,
                    ).animateEntrance(delayMs: 500),
                    const SizedBox(height: 20),
                    _buildPickerWithLabel(
                      label: LangKeys.clientsExternal.tr(),
                      ids: _clientIds,
                      role: UserRole.client,
                      onChanged: (ids) => setState(() {
                        _clientIds = ids;
                        _hasChanges = true;
                      }),
                    ).animateEntrance(delayMs: 600),

                    if (_workerIds.isNotEmpty && _managerIds.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _buildSectionHeader(
                        LangKeys.workers.tr(),
                        Ionicons.construct_outline,
                      ).animateEntrance(delayMs: 700),
                      const SizedBox(height: 20),
                      _buildPickerWithLabel(
                        label: LangKeys.workers.tr(),
                        ids: _workerIds,
                        role: UserRole.worker,
                        onChanged: (ids) => setState(() {
                          _workerIds = ids;
                          _hasChanges = true;
                        }),
                      ).animateEntrance(delayMs: 800),
                      const SizedBox(height: 32),
                      _buildSectionHeader(
                        LangKeys.workerAssignments.tr(),
                        Ionicons.git_branch_outline,
                      ).animateEntrance(delayMs: 900),
                      const SizedBox(height: 16),
                      _buildWorkerManagerMapping().animateEntrance(
                        delayMs: 1000,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_hasChanges)
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: _buildSaveButton(context),
          ),
      ],
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final totalTeam =
        _supervisorIds.length +
        _managerIds.length +
        _clientIds.length +
        _workerIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.project.title,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: context.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          LangKeys.manageTeamComposition.tr(),
          style: TextStyle(
            fontSize: 15,
            color: context.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildMiniStat(
              label: LangKeys.teamSize.tr(),
              value: '$totalTeam',
              icon: Ionicons.people,
              color: context.primary,
            ),
            const SizedBox(width: 12),
            _buildMiniStat(
              label: LangKeys.changes.tr(),
              value: _hasChanges
                  ? LangKeys.pendingChanges.tr()
                  : LangKeys.savedChanges.tr(),
              icon: _hasChanges ? Ionicons.sync : Ionicons.checkmark_done,
              color: _hasChanges ? context.secondary : context.mintGreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.onSurface.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: context.onSurface,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: context.onSurface.withOpacity(0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerWithLabel({
    required String label,
    required List<String> ids,
    required UserRole role,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MultiEmailSearchPicker(
          label: label,
          initialSelectedIds: ids,
          filterRoles: [role],
          onChanged: onChanged,
          initialUsers: initialUsers,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: context.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: context.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: context.onSurface.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SharedButton(
      onPressed: _saveChanges,
      text: LangKeys.updateTeam.tr(),
    );
  }

  Widget _buildWorkerManagerMapping() {
    final availableManagers = initialUsers
        .where((u) => _managerIds.contains(u.id))
        .toList();

    return Column(
      children: _workerIds.map((workerId) {
        final worker = initialUsers.firstWhere(
          (u) => u.id == workerId,
          orElse: () => UserEntity(
            id: workerId,
            name: LangKeys.unknownWorker.tr(),
            email: '',
            role: UserRole.worker,
            profile: '',
          ),
        );

        final assignedManagerId = _workerManagerMap[workerId];
        final isValidManager =
            assignedManagerId != null &&
            _managerIds.contains(assignedManagerId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isValidManager
                  ? context.primary.withOpacity(0.1)
                  : context.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              SharedProfileAvatar(
                name: worker.name,
                radius: 16,
                showBorder: false,
                imageUrl: worker.profile,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      LangKeys.getLocalizedRole(worker.role),
                      style: TextStyle(
                        fontSize: 10,
                        color: context.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Ionicons.arrow_forward_outline,
                size: 14,
                color: context.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: isValidManager ? assignedManagerId : null,
                  hint: Text(
                    LangKeys.selectPm.tr(),
                    style: TextStyle(fontSize: 12, color: context.error),
                  ),
                  icon: Icon(
                    Ionicons.chevron_down,
                    size: 16,
                    color: context.onSurface.withOpacity(0.5),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.primary,
                  ),
                  dropdownColor: context.surface,
                  borderRadius: BorderRadius.circular(12),
                  items: availableManagers.map((pm) {
                    return DropdownMenuItem(value: pm.id, child: Text(pm.name));
                  }).toList(),
                  onChanged: (newPmId) {
                    if (newPmId != null) {
                      setState(() {
                        _workerManagerMap[workerId] = newPmId;
                        _hasChanges = true;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
