import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../home/screens/main_navigation_screen.dart';
import 'register_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final error = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isSubmitting = false);

    if (error == null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? context.tr('Đăng nhập thất bại', 'Login failed'))),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Đăng nhập Google thất bại', 'Google sign-in failed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Background Decor Orbs
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: c.isDark ? 0.12 : 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primary.withValues(alpha: c.isDark ? 0.08 : 0.08),
              ),
            ),
          ),

          // Scrollable Form Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Logo
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.surface.withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: c.shadow,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Brand Name
                      Text(
                        'Floria',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: c.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Greeting
                      Text(
                        context.tr('Mừng bạn trở lại!', 'Welcome Back!'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Tiếp tục chăm sóc khu vườn của bạn.', 'Continue tending your lovely garden.'),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      _buildInputField(
                        controller: _emailController,
                        hintText: context.tr("Email của bạn", "Your email"),
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('Vui lòng nhập Email', 'Please enter your email');
                          }
                          if (!value.contains('@')) {
                            return context.tr('Email không đúng định dạng', 'Invalid email format');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      _buildInputField(
                        controller: _passwordController,
                        hintText: context.tr("Mật khẩu", "Password"),
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onSuffixIconTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return context.tr('Vui lòng nhập mật khẩu', 'Please enter password');
                          }
                          if (value.length < 6) {
                            return context.tr('Mật khẩu phải từ 6 ký tự trở lên', 'Password must be at least 6 characters');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            _showForgotPasswordDialog(context);
                          },
                          child: Text(
                            context.tr('Quên mật khẩu?', 'Forgot password?'),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            shadowColor: c.shadow,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  context.tr('Đăng Nhập', 'Sign In'),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: c.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              context.tr('HOẶC TIẾP TỤC VỚI', 'OR CONTINUE WITH'),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: c.textMuted,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: c.border)),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Social Login
                      Row(
                        children: [
                          Expanded(
                            child: _buildSocialButton(
                              label: "Google",
                              iconWidget: Image.asset(
                                'assets/images/google_logo.png',
                                width: 18,
                                height: 18,
                              ),
                              onTap: _handleGoogleLogin,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildSocialButton(
                              label: "Apple",
                              iconWidget: Icon(
                                Icons.apple,
                                color: c.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Footer Link (Sign Up)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('Chưa có tài khoản?', 'Don\'t have an account?'),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              color: c.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              context.tr(' Đăng ký ngay', ' Sign up now'),
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: c.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixIconTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.beVietnamPro(fontSize: 14, color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 14, color: c.textMuted),
          prefixIcon: Icon(icon, color: c.textMuted, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: c.textMuted,
                    size: 20,
                  ),
                  onPressed: onSuffixIconTap,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget iconWidget,
    VoidCallback? onTap,
  }) {
    final c = context.colors;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "${context.tr('Phương thức đăng nhập', 'Sign in method')} $label ${context.tr('đang được tích hợp', 'is coming soon')}",
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final c = context.colors;
    final resetEmailController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                context.tr('Khôi phục mật khẩu', 'Reset Password'),
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: c.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(
                      'Vui lòng nhập Email của bạn. Chúng tôi sẽ gửi một đường dẫn để đặt lại mật khẩu.',
                      'Please enter your email. We will send a link to reset your password.',
                    ),
                    style: GoogleFonts.beVietnamPro(fontSize: 14, color: c.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.beVietnamPro(fontSize: 14, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: context.tr("Email của bạn", "Your email"),
                      hintStyle: GoogleFonts.beVietnamPro(fontSize: 13, color: c.textMuted),
                      prefixIcon: Icon(Icons.mail_outline, size: 20, color: c.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.tr('Hủy', 'Cancel'), style: GoogleFonts.beVietnamPro(color: c.textMuted)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('Vui lòng nhập Email hợp lệ', 'Please enter a valid email')),
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSending = true);
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final error = await authProvider.resetPassword(email);
                          if (!ctx.mounted) return;
                          setStateDialog(() => isSending = false);

                          if (error == null) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr(
                                    'Đã gửi Email khôi phục! Vui lòng kiểm tra hộp thư.',
                                    'Reset email sent! Please check your inbox.',
                                  ),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error)),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('Gửi', 'Send'), style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
