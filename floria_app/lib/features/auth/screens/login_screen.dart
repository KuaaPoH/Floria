import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/screens/main_navigation_screen.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSubmitting = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  late final AnimationController _entranceController;
  late final AnimationController _mascotWaveController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _mascotFade;
  late final Animation<Offset> _mascotSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _loginBtnFade;
  late final Animation<Offset> _loginBtnSlide;
  late final Animation<double> _socialFade;
  late final Animation<Offset> _socialSlide;

  late final Animation<double> _mascotSway;
  Animation<double>? _routeSecondaryAnim;

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (mounted && _emailFocused != _emailFocus.hasFocus) {
        setState(() => _emailFocused = _emailFocus.hasFocus);
      }
    });
    _passwordFocus.addListener(() {
      if (mounted && _passwordFocused != _passwordFocus.hasFocus) {
        setState(() => _passwordFocused = _passwordFocus.hasFocus);
      }
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );

    _mascotWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _mascotSway = Tween<double>(begin: -0.045, end: 0.045).animate(
      CurvedAnimation(parent: _mascotWaveController, curve: Curves.easeInOutSine),
    );

    _headerFade = _fadeInterval(0.00, 0.28);
    _headerSlide = _slideInterval(0.00, 0.28, const Offset(0.0, -0.18));

    _mascotFade = _fadeInterval(0.14, 0.48);
    _mascotSlide = _slideInterval(0.14, 0.48, const Offset(0.85, 0.0));

    _titleFade = _fadeInterval(0.30, 0.56);
    _titleSlide = _slideInterval(0.30, 0.56, const Offset(0.0, 0.40));

    _emailFade = _fadeInterval(0.42, 0.68);
    _emailSlide = _slideInterval(0.42, 0.68, const Offset(0.0, 0.35));

    _passwordFade = _fadeInterval(0.54, 0.80);
    _passwordSlide = _slideInterval(0.54, 0.80, const Offset(0.0, 0.35));

    _loginBtnFade = _fadeInterval(0.68, 0.90);
    _loginBtnSlide = _slideInterval(0.68, 0.90, const Offset(0.0, 0.35));

    _socialFade = _fadeInterval(0.78, 1.00);
    _socialSlide = _slideInterval(0.78, 1.00, const Offset(0.0, 0.30));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (mounted) _entranceController.forward();
      });
    });
  }

  Animation<double> _fadeInterval(double begin, double end) {
    return CurvedAnimation(
      parent: _entranceController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slideInterval(double begin, double end, Offset offset) {
    return Tween<Offset>(begin: offset, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final secondaryAnim = ModalRoute.of(context)?.secondaryAnimation;
    if (secondaryAnim != null && secondaryAnim != _routeSecondaryAnim) {
      _routeSecondaryAnim?.removeStatusListener(_onSecondaryRouteStatus);
      _routeSecondaryAnim = secondaryAnim;
      _routeSecondaryAnim!.addStatusListener(_onSecondaryRouteStatus);
    }
  }

  void _onSecondaryRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse && mounted) {
      _entranceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _routeSecondaryAnim?.removeStatusListener(_onSecondaryRouteStatus);
    _entranceController.dispose();
    _mascotWaveController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final error = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = (screenHeight * 0.30).clamp(225.0, 290.0);

    return Scaffold(
      backgroundColor: c.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Gradient xanh lá (~30% chiều cao màn hình) + Floria/Slogan trái + Mascot phải
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeader(context, headerHeight),
                      ),
                    ),

                    // 2. Form nội dung chính + Footer đẩy xuống đáy màn hình
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 580),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Tiêu đề Welcome Back căn trái
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: SlideTransition(
                                      position: _titleSlide,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr('Mừng bạn trở lại!', 'Welcome Back!'),
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: c.textPrimary,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            context.tr(
                                              'Đăng nhập để tiếp tục chăm sóc khu vườn của bạn.',
                                              'Sign in to continue tending your lovely garden.',
                                            ),
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 14,
                                              color: c.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Email Input (kiểu viên thuốc nền dịu, không bóng)
                                  FadeTransition(
                                    opacity: _emailFade,
                                    child: SlideTransition(
                                      position: _emailSlide,
                                      child: _buildInputField(
                                        controller: _emailController,
                                        focusNode: _emailFocus,
                                        isFocused: _emailFocused,
                                        hintText: context.tr('Email của bạn', 'Email or phone'),
                                        icon: Icons.mail_outline_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
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
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password Input + Remember Me & Forgot Password
                                  FadeTransition(
                                    opacity: _passwordFade,
                                    child: SlideTransition(
                                      position: _passwordSlide,
                                      child: Column(
                                        children: [
                                          _buildInputField(
                                            controller: _passwordController,
                                            focusNode: _passwordFocus,
                                            isFocused: _passwordFocused,
                                            hintText: context.tr('Mật khẩu', 'Password'),
                                            icon: Icons.lock_outline_rounded,
                                            isPassword: true,
                                            obscureText: _obscurePassword,
                                            textInputAction: TextInputAction.done,
                                            onFieldSubmitted: (_) {
                                              if (!_isSubmitting) _submit();
                                            },
                                            onSuffixIconTap: () {
                                              setState(() => _obscurePassword = !_obscurePassword);
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return context.tr('Vui lòng nhập mật khẩu', 'Please enter password');
                                              }
                                              if (value.length < 6) {
                                                return context.tr(
                                                  'Mật khẩu phải từ 6 ký tự trở lên',
                                                  'Password must be at least 6 characters',
                                                );
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              InkWell(
                                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child: Checkbox(
                                                          value: _rememberMe,
                                                          onChanged: (val) {
                                                            setState(() => _rememberMe = val ?? true);
                                                          },
                                                          activeColor: c.primary,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          side: BorderSide(color: c.border, width: 1.5),
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        context.tr('Ghi nhớ đăng nhập', 'Remember me'),
                                                        style: GoogleFonts.beVietnamPro(
                                                          fontSize: 13,
                                                          color: c.textSecondary,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => _showForgotPasswordDialog(context),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  context.tr('Quên mật khẩu?', 'Forgot password?'),
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Nút Login Gradient xanh bo tròn viên thuốc
                                  FadeTransition(
                                    opacity: _loginBtnFade,
                                    child: SlideTransition(
                                      position: _loginBtnSlide,
                                      child: _buildGradientLoginButton(context),
                                    ),
                                  ),

                                  const Spacer(),
                                  const SizedBox(height: 24),

                                  // Cụm Footer: HOẶC TIẾP TỤC VỚI + Google/Apple + Chưa có tài khoản? Đăng ký ngay
                                  SafeArea(
                                    top: false,
                                    child: FadeTransition(
                                      opacity: _socialFade,
                                      child: SlideTransition(
                                        position: _socialSlide,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Divider(color: c.border)),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                  child: Text(
                                                    context.tr('HOẶC TIẾP TỤC VỚI', 'OR CONTINUE WITH'),
                                                    style: GoogleFonts.beVietnamPro(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: c.textMuted,
                                                      letterSpacing: 0.6,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(child: Divider(color: c.border)),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildSocialButton(
                                                    label: 'Google',
                                                    iconWidget: Image.asset(
                                                      'assets/images/google_logo.png',
                                                      width: 19,
                                                      height: 19,
                                                    ),
                                                    onTap: _handleGoogleLogin,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: _buildSocialButton(
                                                    label: 'Apple',
                                                    iconWidget: Icon(
                                                      Icons.apple,
                                                      color: c.textPrimary,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 22),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  context.tr('Chưa có tài khoản?', "Don't have an account?"),
                                                  style: GoogleFonts.beVietnamPro(
                                                    fontSize: 14,
                                                    color: c.textSecondary,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => const RegisterScreen(),
                                                      ),
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double headerHeight) {
    final c = context.colors;
    final gradientColors = c.isDark
        ? const [Color(0xFF153822), Color(0xFF235736), Color(0xFF2F6F45)]
        : const [Color(0xFF1F5430), Color(0xFF2E6F40), Color(0xFF4CA364)];
    final mascotHeight = (headerHeight * 0.80).clamp(180.0, 232.0);

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4D2B).withValues(alpha: c.isDark ? 0.35 : 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -55,
              left: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              right: -25,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Trái: Floria + Slogan ngay bên dưới
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Floria',
                                style: GoogleFonts.outfit(
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.tr(
                                  'Hỗ trợ quản lý chăm sóc cây trồng của bạn',
                                  'Your smart companion for plant care',
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: Colors.white.withValues(alpha: 0.90),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Phải: Mascot trượt từ phải vào & đung đưa nhẹ như đang vẫy tay
                        Expanded(
                          flex: 5,
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: SlideTransition(
                              position: _mascotSlide,
                              child: FadeTransition(
                                opacity: _mascotFade,
                                child: AnimatedBuilder(
                                  animation: _mascotSway,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _mascotSway.value,
                                      alignment: Alignment.bottomCenter,
                                      child: Transform.translate(
                                        offset: Offset(
                                          0,
                                          -3.0 * math.cos(_mascotWaveController.value * math.pi),
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    'assets/images/mascot_chao_mung.png',
                                    height: mascotHeight,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientLoginButton(BuildContext context) {
    final c = context.colors;
    final gradientColors = c.isDark
        ? const [Color(0xFF2B6B40), Color(0xFF479B62)]
        : const [Color(0xFF256137), Color(0xFF4CA364)];

    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _isSubmitting
              ? gradientColors.map((color) => color.withValues(alpha: 0.7)).toList()
              : gradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: 0.24),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSubmitting ? null : _submit,
          borderRadius: BorderRadius.circular(28),
          child: Center(
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
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixIconTap,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final c = context.colors;
    final fillColor = c.isDark ? c.surface : const Color(0xFFEFF3EC);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? c.surface : fillColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isFocused ? c.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: GoogleFonts.beVietnamPro(fontSize: 14.5, color: c.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.beVietnamPro(fontSize: 14, color: c.textMuted),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Icon(
              icon,
              color: isFocused ? c.primary : c.textMuted,
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 24),
          suffixIcon: isPassword
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isFocused ? c.primary : c.textMuted,
                      size: 20,
                    ),
                    onPressed: onSuffixIconTap,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
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
      height: 50,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: c.border),
      ),
      child: InkWell(
        onTap: onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${context.tr('Phương thức đăng nhập', 'Sign in method')} $label ${context.tr('đang được tích hợp', 'is coming soon')}",
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
        borderRadius: BorderRadius.circular(25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
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
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: c.textPrimary,
                ),
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
                      hintText: context.tr('Email của bạn', 'Your email'),
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
                  child: Text(
                    context.tr('Hủy', 'Cancel'),
                    style: GoogleFonts.beVietnamPro(color: c.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('Vui lòng nhập Email hợp lệ', 'Please enter a valid email'),
                                ),
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
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          context.tr('Gửi', 'Send'),
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
