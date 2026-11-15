import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _nameFocused = false;
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
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _submitBtnFade;
  late final Animation<Offset> _submitBtnSlide;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _footerSlide;

  late final Animation<double> _mascotSway;

  @override
  void initState() {
    super.initState();

    _nameFocus.addListener(() {
      if (mounted && _nameFocused != _nameFocus.hasFocus) {
        setState(() => _nameFocused = _nameFocus.hasFocus);
      }
    });
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

    _titleFade = _fadeInterval(0.28, 0.54);
    _titleSlide = _slideInterval(0.28, 0.54, const Offset(0.0, 0.38));

    _nameFade = _fadeInterval(0.38, 0.62);
    _nameSlide = _slideInterval(0.38, 0.62, const Offset(0.0, 0.34));

    _emailFade = _fadeInterval(0.48, 0.72);
    _emailSlide = _slideInterval(0.48, 0.72, const Offset(0.0, 0.34));

    _passwordFade = _fadeInterval(0.58, 0.82);
    _passwordSlide = _slideInterval(0.58, 0.82, const Offset(0.0, 0.34));

    _submitBtnFade = _fadeInterval(0.68, 0.90);
    _submitBtnSlide = _slideInterval(0.68, 0.90, const Offset(0.0, 0.34));

    _footerFade = _fadeInterval(0.78, 1.00);
    _footerSlide = _slideInterval(0.78, 1.00, const Offset(0.0, 0.30));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
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
  void dispose() {
    _entranceController.dispose();
    _mascotWaveController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final error = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Đăng ký thành công! Vui lòng vào hộp thư Email để XÁC THỰC tài khoản.',
              'Registration successful! Please check your email to verify your account.',
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
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
                    // 1. Header Gradient xanh lá (~30% màn hình) đồng bộ với LoginScreen
                    FadeTransition(
                      opacity: _headerFade,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeader(context, headerHeight),
                      ),
                    ),

                    // 2. Form nội dung đăng ký + Footer đáy màn hình
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
                                  // Tiêu đề căn trái
                                  FadeTransition(
                                    opacity: _titleFade,
                                    child: SlideTransition(
                                      position: _titleSlide,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr('Tạo tài khoản mới', 'Create New Account'),
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
                                              'Bắt đầu hành trình xanh cùng chúng tôi.',
                                              'Start your green journey with us.',
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

                                  // Name Input
                                  FadeTransition(
                                    opacity: _nameFade,
                                    child: SlideTransition(
                                      position: _nameSlide,
                                      child: _buildInputField(
                                        controller: _nameController,
                                        focusNode: _nameFocus,
                                        isFocused: _nameFocused,
                                        hintText: context.tr('Họ và Tên', 'Full Name'),
                                        icon: Icons.person_outline_rounded,
                                        textInputAction: TextInputAction.next,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return context.tr('Vui lòng nhập Họ và Tên', 'Please enter your full name');
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Email Input
                                  FadeTransition(
                                    opacity: _emailFade,
                                    child: SlideTransition(
                                      position: _emailSlide,
                                      child: _buildInputField(
                                        controller: _emailController,
                                        focusNode: _emailFocus,
                                        isFocused: _emailFocused,
                                        hintText: context.tr('Email của bạn', 'Your email'),
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

                                  // Password Input
                                  FadeTransition(
                                    opacity: _passwordFade,
                                    child: SlideTransition(
                                      position: _passwordSlide,
                                      child: _buildInputField(
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
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Nút Đăng Ký Gradient xanh bo tròn viên thuốc
                                  FadeTransition(
                                    opacity: _submitBtnFade,
                                    child: SlideTransition(
                                      position: _submitBtnSlide,
                                      child: _buildGradientSubmitButton(context),
                                    ),
                                  ),

                                  const Spacer(),
                                  const SizedBox(height: 24),

                                  // Footer Link (Sign In)
                                  SafeArea(
                                    top: false,
                                    child: FadeTransition(
                                      opacity: _footerFade,
                                      child: SlideTransition(
                                        position: _footerSlide,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              context.tr('Đã có tài khoản?', 'Already have an account?'),
                                              style: GoogleFonts.beVietnamPro(
                                                fontSize: 14,
                                                color: c.textSecondary,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context),
                                              child: Text(
                                                context.tr(' Đăng nhập', ' Sign in'),
                                                style: GoogleFonts.beVietnamPro(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: c.primary,
                                                ),
                                              ),
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

                        // Phải: Mascot trượt từ phải vào & đung đưa vẫy tay
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

  Widget _buildGradientSubmitButton(BuildContext context) {
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
                    context.tr('Đăng Ký', 'Sign Up'),
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
}
