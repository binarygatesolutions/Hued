import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/theme/theme_ext.dart';
import '../../domain/entities/entities.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class TaskFilterDropdown extends StatelessWidget {
  final TaskStatus? selectedStatus;
  final Function(TaskStatus?) onStatusSelected;

  const TaskFilterDropdown({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      onSelected: (val) {
        if (val == 0) {
          onStatusSelected(null);
        } else {
          onStatusSelected(val as TaskStatus);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.surface,
      offset: const Offset(0, 44),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedStatus != null
              ? context.primary.withOpacity(0.1)
              : context.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selectedStatus != null
                ? context.primary.withOpacity(0.2)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Ionicons.options_outline,
              size: 16,
              color: selectedStatus != null
                  ? context.primary
                  : context.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Text(
              selectedStatus == null
                  ? LangKeys.filterLabel.tr()
                  : _getStatusLabel(selectedStatus!),
              style: TextStyle(
                fontSize: 12,
                color: selectedStatus != null
                    ? context.primary
                    : context.onSurface.withOpacity(0.7),
                fontWeight: selectedStatus != null
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Ionicons.chevron_down,
              size: 12,
              color: selectedStatus != null
                  ? context.primary.withOpacity(0.5)
                  : context.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: 0, child: Text(LangKeys.allTasks.tr())),
        ...TaskStatus.values.map(
          (s) => PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(_getStatusLabel(s))),
                if (selectedStatus == s)
                  Icon(Ionicons.checkmark, size: 16, color: context.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return LangKeys.taskStatusPending.tr();
      case TaskStatus.inProgress:
        return LangKeys.taskStatusInProgress.tr();
      case TaskStatus.completed:
        return LangKeys.taskStatusCompleted.tr();
      case TaskStatus.cancelled:
        return LangKeys.taskStatusCancelled.tr();
    }
  }
}
