import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/utils/responsive_layout.dart';
import '../../domain/entities/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/custom_loading.dart';
import '../widgets/shared_profile_avatar.dart';
import '../widgets/glass_container.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_app_logo.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  TextEditingController searchQuery = TextEditingController();
  UserRole? _filterRole;
  bool isLoading = false;

  void _showRoleChangeConfirmation(UserEntity user, UserRole newRole) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Text(
          LangKeys.changeRole.tr(),
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        content: Text.rich(
          TextSpan(
            style: TextStyle(
              color: context.onSurface.withOpacity(0.55),
              fontSize: 14,
              height: 1.6,
            ),
            children: [
              TextSpan(text: LangKeys.change.tr()),
              TextSpan(
                text: user.name,
                style: TextStyle(
                  color: context.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(text: LangKeys.to.tr()),
              TextSpan(
                text: newRole.label,
                style: TextStyle(
                  color: context.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop();
            },
            child: Text(
              LangKeys.cancel.tr(),
              style: const TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .update({'role': newRole.name});
              context.pop();
            },
            child: Text(LangKeys.yes.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          final isMobile = ResponsiveLayout.isMobile(context);
          return Scaffold(
            backgroundColor: context.background,
            appBar: SharedAppBar(
              title: LangKeys.team.tr(),
              showBackButton: false,
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: SharedAppLogo(height: 30),
              ),
            ),
            body: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 40,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 30),
                        _buildUserList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Scaffold(body: CustomLoading());
      },
    );
  }

  Widget _buildSearchBar() {
    return GlassContainer(
      borderRadius: 14,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Ionicons.search_outline,
            color: context.onSurface.withOpacity(0.3),
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onSubmitted: (v) async {
                setState(() => isLoading = true);
                await Future.delayed(Duration(milliseconds: 500));
                isLoading = false;
                _filterRole = null;
                setState(() => searchQuery.text = v);
              },
              controller: searchQuery,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: context.onSurface,
              ),
              decoration: InputDecoration(
                hintText: LangKeys.searchByNameOrEmail.tr(),
                hintStyle: TextStyle(
                  color: context.onSurface.withOpacity(0.28),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          PopupMenuButton<dynamic>(
            onSelected: (val) async {
              setState(() {
                isLoading = true;
              });
              searchQuery.clear();
              if (val == 0) {
                _filterRole = null;
              } else {
                _filterRole = val;
              }
              await Future.delayed(Duration(milliseconds: 500));
              setState(() {
                isLoading = false;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: context.surface,
            offset: const Offset(0, 44),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _filterRole != null
                    ? context.primary.withOpacity(0.1)
                    : context.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Ionicons.options_outline,
                    size: 14,
                    color: _filterRole != null
                        ? context.primary
                        : context.onSurface.withOpacity(0.4),
                  ),
                  if (_filterRole != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      _filterRole!.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.primary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(value: 0, child: Text(LangKeys.allRoles.tr())),
              ...UserRole.values.map(
                (r) => PopupMenuItem(value: r, child: Text(r.label)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    if (isLoading) return SizedBox(height: 500, child: CustomLoading());

    return FirestorePagination(
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      query: searchQuery.text.isNotEmpty
          ? FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: searchQuery.text)
          : _filterRole == null
          ? FirebaseFirestore.instance.collection('users')
          : FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: _filterRole!.name),
      initialLoader: CustomLoading(),
      bottomLoader: CustomLoading(),
      onEmpty: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(
            children: [
              Icon(
                Ionicons.people_outline,
                size: 44,
                color: context.onSurface.withOpacity(0.07),
              ),
              const SizedBox(height: 12),
              Text(
                LangKeys.noUsersFound.tr(),
                style: TextStyle(
                  color: context.onSurface.withOpacity(0.25),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
      separatorBuilder: (_, __) => SizedBox(height: 20),
      itemBuilder: (context, snapshots, idx) {
        final userData = snapshots[idx].data() as Map<String, dynamic>;
        userData['id'] = snapshots[idx].id;

        final user = UserEntity.fromJson(userData);
        return _buildUserCard(user, idx);
      },
    );
  }

  Widget _buildUserCard(UserEntity user, int index) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SharedProfileAvatar(
            name: user.name,
            radius: 26,
            showBorder: false,
            imageUrl: user.profile,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.onSurface.withOpacity(0.38),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<UserRole>(
            onSelected: (newRole) => _showRoleChangeConfirmation(user, newRole),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: context.surface,
            offset: const Offset(0, 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: context.primary.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.role.label,
                    style: TextStyle(
                      color: context.primary.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Ionicons.chevron_down,
                    size: 10,
                    color: context.primary.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => UserRole.values.map((role) {
              final isSelected = role == user.role;
              return PopupMenuItem(
                value: role,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        role.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isSelected
                              ? context.primary
                              : context.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Ionicons.checkmark_outline,
                        size: 14,
                        color: context.primary,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideY(begin: 0.04);
  }
}
