import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/localization/lang_keys.dart';
import '../../core/theme/theme_ext.dart';
import '../blocs/specialty_bloc.dart';
import '../widgets/custom_loading.dart';
import '../widgets/glass_container.dart';
import '../widgets/shared_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class ManageSpecialtiesScreen extends StatefulWidget {
  const ManageSpecialtiesScreen({super.key});

  @override
  State<ManageSpecialtiesScreen> createState() =>
      _ManageSpecialtiesScreenState();
}

class _ManageSpecialtiesScreenState extends State<ManageSpecialtiesScreen> {
  final TextEditingController _nameController = TextEditingController();

  void _showAddSpecialtyDialog() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.onSurface.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Icon + title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.primary,
                          context.primary.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: context.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Ionicons.briefcase_outline,
                      color: context.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${LangKeys.add.tr()} ${LangKeys.specialty.tr()}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Fill in the specialty name below",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Text field
              TextField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(
                  color: context.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Civil Engineer, Designer...",
                  hintStyle: TextStyle(
                    color: context.onSurface.withOpacity(0.3),
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: Icon(
                    Ionicons.create_outline,
                    color: context.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: context.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                onSubmitted: (_) {
                  if (_nameController.text.trim().isNotEmpty) {
                    context.read<SpecialtyBloc>().add(
                      AddSpecialty(_nameController.text.trim()),
                    );
                    _nameController.clear();
                    Navigator.pop(ctx);
                  }
                },
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: context.onSurface.withOpacity(0.15),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        LangKeys.cancel.tr(),
                        style: TextStyle(
                          color: context.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.trim().isNotEmpty) {
                          context.read<SpecialtyBloc>().add(
                            AddSpecialty(_nameController.text.trim()),
                          );
                          _nameController.clear();
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: context.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Ionicons.add_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            LangKeys.add.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: SharedAppBar(
        title: LangKeys.specialty.tr(),
        showBackButton: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSpecialtyDialog,
        backgroundColor: context.primary,
        icon: const Icon(Ionicons.add_outline),
        label: Text(LangKeys.add.tr()),
      ),
      body: BlocBuilder<SpecialtyBloc, SpecialtyState>(
        builder: (context, state) {
          if (state.isLoading && state.specialties.isEmpty) {
            return const Center(child: CustomLoading());
          }

          if (state.specialties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Ionicons.briefcase_outline,
                    size: 64,
                    color: context.onSurface.withOpacity(0.15),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No Specialties Added",
                    style: TextStyle(
                      color: context.onSurface.withOpacity(0.4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.specialties.length,
            itemBuilder: (context, index) {
              final specialty = state.specialties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Ionicons.briefcase_outline,
                          size: 20,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        specialty.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
