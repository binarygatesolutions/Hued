import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ionicons/ionicons.dart';
import '../../domain/entities/entities.dart';
import '../../core/theme/theme_ext.dart';
import 'glass_container.dart';
import 'animated_list_wrapper.dart';
import 'shared_profile_avatar.dart';
import 'premium_card.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';
import 'user_profile_sheet.dart';

class MultiEmailSearchPicker extends StatefulWidget {
  final String label;
  final List<String> initialSelectedIds;
  final List<UserEntity> initialUsers;
  final ValueChanged<List<String>> onChanged;
  final UserRole? filterRole;

  const MultiEmailSearchPicker({
    super.key,
    required this.label,
    required this.initialUsers,
    required this.onChanged,
    this.initialSelectedIds = const [],
    this.filterRole,
  });

  @override
  State<MultiEmailSearchPicker> createState() => _MultiEmailSearchPickerState();
}

class _MultiEmailSearchPickerState extends State<MultiEmailSearchPicker> {
  late List<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  List<UserEntity> _filteredUsers = [];
  final Map<String, UserEntity> _resolvedUsers = {};

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    for (var u in widget.initialUsers) {
      _resolvedUsers[u.id] = u;
    }
  }

  void _showSearchModal() {
    _searchController.clear();
    _filteredUsers = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildModalHeader(context, setModalState),
              if (_selectedIds.isNotEmpty)
                _buildSelectedHorizontalList(context, setModalState),
              const SizedBox(height: 12),
              Expanded(child: _buildSearchResults(context, setModalState)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context, StateSetter setModalState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (widget.filterRole != null)
                    Text(
                      LangKeys.filteredFor.tr(
                        args: [widget.filterRole!.label.toUpperCase()],
                      ),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: context.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  LangKeys.numSelected.tr(
                    args: [_selectedIds.length.toString()],
                  ),
                  style: TextStyle(
                    color: context.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            opacity: 0.05,
            borderRadius: 20,
            showShadow: false,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: LangKeys.searchByEmailOrName.tr(),
                prefixIcon: Icon(
                  Ionicons.search_outline,
                  color: context.primary,
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onChanged: (val) {
                setModalState(() {
                  _updateSearchResults(val);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedHorizontalList(
    BuildContext context,
    StateSetter setModalState,
  ) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _selectedIds.length,
        itemBuilder: (context, index) {
          final id = _selectedIds[index];
          final user =
              _resolvedUsers[id] ??
              UserEntity(
                id: id,
                email: LangKeys.unknown.tr(),
                name: LangKeys.loading.tr(),
                profile: '',
                role: UserRole.client,
              );
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: PremiumCard(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: 14,
              showShadow: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => UserProfileSheet.show(context, user),
                    child: SharedProfileAvatar(
                      name: user.name,
                      radius: 10,
                      showBorder: false,
                      imageUrl: user.profile,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Ionicons.close, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() => _selectedIds.remove(user.id));
                      setModalState(() {});
                      widget.onChanged(_selectedIds);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, StateSetter setModalState) {
    if (_filteredUsers.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Ionicons.search_outline,
              size: 64,
              color: context.onSurface.withOpacity(0.05),
            ),
            const SizedBox(height: 16),
            Text(
              LangKeys.noMatchesFound.tr(),
              style: TextStyle(
                color: context.onSurface.withOpacity(0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        final isSelected = _selectedIds.contains(user.id);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? context.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? context.primary.withOpacity(0.2)
                  : Colors.transparent,
            ),
          ),
          child: ListTile(
            leading: GestureDetector(
              onTap: () => UserProfileSheet.show(context, user),
              child: SharedProfileAvatar(
                name: user.name,
                radius: 18,
                showBorder: false,
                imageUrl: user.profile,
              ),
            ),
            title: Text(
              user.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? context.primary : context.onSurface,
              ),
            ),
            subtitle: Text(
              user.email,
              style: TextStyle(
                fontSize: 12,
                color: context.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: isSelected
                ? Icon(Ionicons.checkmark_circle, color: context.primary)
                : Icon(
                    Ionicons.add_circle_outline,
                    color: context.onSurface.withOpacity(0.2),
                  ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIds.remove(user.id);
                } else {
                  _selectedIds.add(user.id);
                }
              });
              setModalState(() {});
              widget.onChanged(_selectedIds);
            },
          ),
        );
      },
    );
  }

  void _updateSearchResults(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _filteredUsers = []);
      return;
    }

    final lowerQuery = query.toLowerCase();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: lowerQuery)
          .where('email', isLessThanOrEqualTo: lowerQuery + '\uf8ff')
          .limit(10)
          .get();

      final fetched = <UserEntity>[];
      for (var userDoc in querySnapshot.docs) {
        final data = userDoc.data();
        data['id'] = userDoc.id;
        final user = UserEntity.fromJson(data);
        if (widget.filterRole != null && user.role != widget.filterRole) {
          continue;
        }
        fetched.add(user);
        _resolvedUsers[user.id] = user;
      }

      if (mounted) {
        setState(() {
          _filteredUsers = fetched;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: context.onSurface.withOpacity(0.3),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  Text(
                    LangKeys.usersAssigned.tr(
                      args: [_selectedIds.length.toString()],
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.primary,
                    ),
                  ),
              ],
            ),
            GestureDetector(
              onTap: _showSearchModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Ionicons.add, size: 14, color: context.primary),
                    const SizedBox(width: 4),
                    Text(
                      LangKeys.add.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedIds.isEmpty)
          GestureDetector(
            onTap: _showSearchModal,
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 16,
              opacity: 0.03,
              showShadow: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.mail_outline,
                    size: 18,
                    color: context.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    LangKeys.searchAndAssignByEmail.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _selectedIds.asMap().entries.map((entry) {
              final index = entry.key;
              final id = entry.value;
              final user =
                  _resolvedUsers[id] ??
                  UserEntity(
                    id: id,
                    email: 'Unknown',
                    name: 'Loading...',
                    profile: '',
                    role: UserRole.client,
                  );
              return AnimatedListWrapper(
                index: index,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    borderRadius: 16,
                    opacity: 0.05,
                    showShadow: false,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => UserProfileSheet.show(context, user),
                          child: SharedProfileAvatar(
                            name: user.name,
                            radius: 16,
                            showBorder: false,
                            imageUrl: user.profile,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Ionicons.close_circle_outline,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() => _selectedIds.remove(id));
                            widget.onChanged(_selectedIds);
                          },
                          color: context.onSurface.withOpacity(0.2),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
