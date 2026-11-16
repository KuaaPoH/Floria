import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Helper hiển thị Toast thông báo dịu mắt, đồng bộ Light / Dark Mode.
class AppToast {
  static Color backgroundColor(BuildContext context, {bool isError = false}) {
    final isDark = context.colors.isDark;
    if (isError) {
      return isDark ? const Color(0xFF2E1E20) : const Color(0xFFFDF2F2);
    }
    return isDark ? const Color(0xFF1F2B22) : const Color(0xFFEEF6F0);
  }

  static Color borderColor(BuildContext context, {bool isError = false}) {
    final isDark = context.colors.isDark;
    if (isError) {
      return isDark ? const Color(0xFF553135) : const Color(0xFFF2C9C9);
    }
    return isDark ? const Color(0xFF334737) : const Color(0xFFC5DEC9);
  }

  static Color textColor(BuildContext context, {bool isError = false}) {
    final isDark = context.colors.isDark;
    if (isError) {
      return isDark ? const Color(0xFFF9DEDC) : const Color(0xFF4A1E1E);
    }
    return isDark ? const Color(0xFFE3EDE5) : const Color(0xFF1F2A21);
  }

  static Color accentColor(BuildContext context, {bool isError = false}) {
    final isDark = context.colors.isDark;
    if (isError) {
      return isDark ? const Color(0xFFEF8A8A) : const Color(0xFFC64B4B);
    }
    return isDark ? const Color(0xFF7BC48B) : const Color(0xFF2E6F40);
  }

  static BoxDecoration decoration(BuildContext context, {bool isError = false, double radius = 16}) {
    final isDark = context.colors.isDark;
    return BoxDecoration(
      color: backgroundColor(context, isError: isError),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor(context, isError: isError), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 20, left: 16, right: 16),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final accent = accentColor(context, isError: isError);
    final fg = textColor(context, isError: isError);

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: margin,
        duration: duration,
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: decoration(context, isError: isError),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ?? (isError ? Icons.error_outline_rounded : Icons.check_rounded),
                      color: accent,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        onAction();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.14),
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
