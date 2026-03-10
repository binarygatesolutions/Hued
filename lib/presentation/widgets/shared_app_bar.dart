import 'package:flutter/material.dart';
import 'package:hued/core/theme/theme_ext.dart';
import 'package:hued/core/utils/font_helper.dart';
import 'package:hued/core/utils/haptics_service.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final TextStyle? titleStyle;

  const SharedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: FontHelper.getTextStyle(
          title,
          style: (titleStyle ?? context.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      leading:
          leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () {
                    HapticsService.light();
                    Navigator.of(context).pop();
                  },
                )
              : null),
      actions: [if (actions != null) ...actions!, const SizedBox(width: 8)],
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
