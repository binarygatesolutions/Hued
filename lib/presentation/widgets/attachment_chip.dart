import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:hued/core/theme/theme_ext.dart';

class AttachmentChip extends StatelessWidget {
  final String fileName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AttachmentChip({
    super.key,
    required this.fileName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.onSurface.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.attach_outline, size: 16, color: context.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(100),
              child: Icon(
                Ionicons.close_circle_outline,
                size: 16,
                color: context.error.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
