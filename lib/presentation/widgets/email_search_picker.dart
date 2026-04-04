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
  final List<UserRole>? filterRoles;

  const MultiEmailSearchPicker({
    super.key,
    required this.label,
    required this.initialUsers,
    required this.onChanged,
    this.initialSelectedIds = const [],
    this.filterRoles,
  });

  @override
  State<MultiEmailSearchPicker> createState() => _MultiEmailSearchPickerState();
}

class _MultiEmailSearchPickerState extends State<MultiEmailSearchPicker> {
  late List<String> _selectedIds;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<UserEntity> _filteredUsers = [];
  final Map<String, UserEntity> _resolvedUsers = {};

  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  StateSetter? _modalSetState;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelectedIds);
    for (var u in widget.initialUsers) {
      _resolvedUsers[u.id] = u;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchUsers();
      }
    }
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _lastDocument = null;
      _hasMore = true;
      _filteredUsers = [];
    }
    if (!_hasMore) return;

    if (mounted) setState(() => _isLoading = true);
    if (_modalSetState != null) _modalSetState!(() {});

    try {
      final queryText = _searchController.text.toLowerCase().trim();
      Query query = FirebaseFirestore.instance.collection('users');

      if (queryText.isEmpty) {
        if (widget.filterRoles != null && widget.filterRoles!.isNotEmpty) {
          query = query.where(
            'role',
            whereIn: widget.filterRoles!.map((r) => r.name).toList(),
          );
        }
        query = query.orderBy(FieldPath.documentId);
      } else {
        query = query
            .where('email', isGreaterThanOrEqualTo: queryText)
            .where('email', isLessThanOrEqualTo: '$queryText\uf8ff')
            .orderBy('email');
      }

      query = query.limit(10);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < 10) {
        _hasMore = false;
      }
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      final fetched = <UserEntity>[];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        final user = UserEntity.fromJson(data);

        // Local filtering if using inequalities because Firestore doesn't allow compound index easily here
        if (queryText.isNotEmpty &&
            widget.filterRoles != null &&
            widget.filterRoles!.isNotEmpty) {
          if (!widget.filterRoles!.contains(user.role)) continue;
        }

        fetched.add(user);
        _resolvedUsers[user.id] = user;
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _filteredUsers = fetched;
          } else {
            _filteredUsers.addAll(fetched);
          }
          _isLoading = false;
        });
      }
      if (_modalSetState != null) _modalSetState!(() {});

      if (queryText.isNotEmpty && fetched.isEmpty && _hasMore) {
        await _fetchUsers();
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) setState(() => _isLoading = false);
      if (_modalSetState != null) _modalSetState!(() {});
    }
  }

  void _showSearchModal() {
    _searchController.clear();
    _fetchUsers(refresh: true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _modalSetState = setModalState;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
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
          );
        },
      ),
    ).whenComplete(() {
      _modalSetState = null;
    });
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
                    ),
                  ),
                  if (widget.filterRoles != null &&
                      widget.filterRoles!.isNotEmpty)
                    Text(
                      LangKeys.filteredFor.tr(
                        args: [
                          widget.filterRoles!
                              .map(
                                (r) =>
                                    LangKeys.getLocalizedRole(r).toUpperCase(),
                              )
                              .join(', '),
                        ],
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
                _fetchUsers(refresh: true);
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
                  InkWell(
                    onTap: () => UserProfileSheet.show(context, user),
                    borderRadius: BorderRadius.circular(100),
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
    if (_filteredUsers.isEmpty && !_isLoading) {
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredUsers.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(color: context.primary),
            ),
          );
        }

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
            leading: InkWell(
              onTap: () => UserProfileSheet.show(context, user),
              borderRadius: BorderRadius.circular(100),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurface.withOpacity(0.5),
                  ),
                ),
                if (user.specialtyName != null &&
                    user.specialtyName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.specialtyName!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: context.secondary,
                        ),
                      ),
                    ),
                  ),
              ],
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
            InkWell(
              onTap: _showSearchModal,
              borderRadius: BorderRadius.circular(10),
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
          InkWell(
            onTap: _showSearchModal,
            borderRadius: BorderRadius.circular(16),
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
                    email: LangKeys.unknown.tr(),
                    name: LangKeys.loading.tr(),
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
                        InkWell(
                          onTap: () => UserProfileSheet.show(context, user),
                          borderRadius: BorderRadius.circular(100),
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
