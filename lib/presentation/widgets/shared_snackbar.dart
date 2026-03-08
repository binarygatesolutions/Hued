import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../core/theme/theme_ext.dart';
import 'glass_container.dart';

enum SnackBarType { success, error, info, warning }

class SharedSnackBar extends StatelessWidget {
  final String message;
  final SnackBarType type;

  const SharedSnackBar({
    super.key,
    required this.message,
    this.type = SnackBarType.info,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: Border.all(color: _getBackgroundColor(context).withOpacity(0.2)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getBackgroundColor(context).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(),
              color: _getBackgroundColor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case SnackBarType.success:
        return Ionicons.checkmark_circle_outline;
      case SnackBarType.error:
        return Ionicons.alert_circle_outline;
      case SnackBarType.warning:
        return Ionicons.warning_outline;
      case SnackBarType.info:
        return Ionicons.information_circle_outline;
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (type) {
      case SnackBarType.success:
        return context.mintGreen;
      case SnackBarType.error:
        return context.error;
      case SnackBarType.warning:
        return context.secondary;
      case SnackBarType.info:
        return context.primary;
    }
  }
}
