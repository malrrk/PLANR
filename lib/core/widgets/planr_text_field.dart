import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/planr_design.dart';

class PlanrTextField extends StatelessWidget {
  const PlanrTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.label,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final String? label;
  final int maxLines;

  /// Hard cap on typed characters; matches the limits enforced by the database rules.
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      maxLines: obscureText ? 1 : maxLines,
      inputFormatters: maxLength == null
          ? null
          : [LengthLimitingTextInputFormatter(maxLength)],
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      cursorColor: PlanrDesign.accent,
      style: const TextStyle(
        color: PlanrDesign.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: PlanrDesign.softMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
                prefixIcon,
                color: PlanrDesign.softMuted,
                size: 20,
              ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: PlanrDesign.cardLight.withValues(alpha: 0.82),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _border(Colors.white.withValues(alpha: 0.95)),
        enabledBorder: _border(Colors.white.withValues(alpha: 0.95)),
        focusedBorder: _border(PlanrDesign.accent, width: 1.4),
        errorBorder: _border(const Color(0xFFD32F2F), width: 1.2),
        focusedErrorBorder: _border(const Color(0xFFD32F2F), width: 1.4),
        errorStyle: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: const TextStyle(
            color: PlanrDesign.muted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}