import 'package:flutter/material.dart';
import '../../core/theme/theme_ext.dart';

class SharedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;
  final Color? fillColor;
  final InputDecoration? decoration;
  final bool readOnly;

  const SharedTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.fillColor,
    this.decoration,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      maxLines: maxLines,
      style: context.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 15,
      ),
      readOnly: readOnly,
      decoration:
          decoration ??
          InputDecoration(
            labelText: maxLines == 1 ? label : null,
            hintText: hint ?? (maxLines > 1 ? label : null),
            labelStyle: TextStyle(
              color: context.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w400,
            ),
            hintStyle: TextStyle(
              color: context.onSurface.withOpacity(0.3),
              fontWeight: FontWeight.w300,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                bottom: maxLines > 1 ? (maxLines * 12.0) : 0,
              ),
              child: Icon(
                icon,
                size: 20,
                color: context.primary.withOpacity(0.6),
              ),
            ),
            contentPadding: const EdgeInsets.all(20),
            filled: true,
            fillColor: fillColor ?? context.onSurface.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
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
          ),
    );
  }
}
