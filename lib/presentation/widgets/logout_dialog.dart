import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/theme_ext.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../widgets/shared_button.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/localization/lang_keys.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (context) => const LogoutDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(color: Colors.white10),
      ),
      title: Text(
        LangKeys.signOut.tr(),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      content: Text(
        LangKeys.confirmEndSession.tr(),
        style: const TextStyle(color: Colors.white60),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LangKeys.stay.tr(),
            style: const TextStyle(color: Colors.white38),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, bottom: 8),
          child: SharedButton(
            width: null,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            borderRadius: 15,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            text: LangKeys.logoutButton.tr(),
          ),
        ),
      ],
    );
  }
}
