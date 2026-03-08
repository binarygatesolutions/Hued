import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class EmptyTasksMessage extends StatelessWidget {
  const EmptyTasksMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          LangKeys.noTasksAddedYet.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: context.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
