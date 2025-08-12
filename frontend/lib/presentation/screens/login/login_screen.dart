// 📁 lib/presentation/screens/login/login_screen.dart
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/app/theme/app_colors.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _SkyBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      child: _Logo(),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, (1 - value) * 16),
                            child: Transform.scale(
                              scale: 0.95 + 0.05 * value,
                              child: child,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '네컷 모아',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jua(
                        fontSize: 32,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 메인 진입: 세 가지 시작 버튼
                    _AnimatedPrimaryButton(
                      text: '이메일로 시작하기',
                      gradientColors: const [
                        AppColors.skyMid,
                        AppColors.primary,
                      ],
                      onTap: () => _showEmailLoginSheet(context),
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSocialButton(
                      label: '카카오로 시작하기',
                      backgroundColor: const Color(0xFFFFE812),
                      foregroundColor: Colors.black,
                      iconAsset:
                          'lib/presentation/screens/login/assets/kakao_icon.png',
                      onTap: () {
                        // TODO: 카카오 로그인/회원가입 통합 플로우
                      },
                    ),
                    const SizedBox(height: 24),
                    _AnimatedSocialButton(
                      label: 'Google로 시작하기',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      iconAsset:
                          'lib/presentation/screens/login/assets/google_icon.png',
                      onTap: () {
                        // TODO: 구글 로그인/회원가입 통합 플로우
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showEmailLoginSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '이메일로 로그인',
                  style: GoogleFonts.jua(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _IconInputField(
                  hintText: '아이디/이메일 입력',
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  strongBorder: true,
                ),
                const SizedBox(height: 12),
                _IconInputField(
                  hintText: '비밀번호 입력',
                  obscureText: true,
                  icon: Icons.lock_outline,
                  strongBorder: true,
                ),
                const SizedBox(height: 16),
                _PrimaryButton(
                  text: '로그인',
                  onTap: () {
                    // TODO: 로그인 로직
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // TODO: 비밀번호 찾기
                      },
                      child: const Text('비밀번호 찾기'),
                    ),
                    const SizedBox(width: 8),
                    const Text('|'),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('회원가입하기'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color.fromARGB(137, 29, 29, 29),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.grid_view_rounded,
        size: 120,
        color: Color(0xFFCBD9F5),
      ),
    );
  }
}

// _GlassCard: 현재 메인 진입 화면에서는 사용하지 않지만, 바텀시트/향후 폼 카드에 재활용할 수 있어 유지합니다.
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _IconInputField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData icon;
  final bool strongBorder; // 바텀시트용 진한 외곽선 스타일

  const _IconInputField({
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.strongBorder = false,
  });

  @override
  State<_IconInputField> createState() => _IconInputFieldState();
}

class _IconInputFieldState extends State<_IconInputField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;
    return TextField(
      focusNode: _focusNode,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(widget.icon, size: 20, color: AppColors.textSecondary),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 36,
        ),
        hintText: isFocused ? '' : widget.hintText,
        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.9)),
        filled: true,
        fillColor: widget.strongBorder
            ? Colors.white
            : Colors.white.withOpacity(0.28),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.strongBorder
                ? AppColors.divider
                : Colors.white.withOpacity(0.5),
            width: widget.strongBorder ? 1 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: widget.strongBorder ? 1.4 : 1.4,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final double height;

  const _PrimaryButton({
    required this.text,
    required this.onTap,
    this.gradientColors,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                gradientColors ??
                [
                  AppColors.primary.withOpacity(0.95),
                  AppColors.primary.withOpacity(0.75),
                ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 8),
            ),
          ],
        ),
        height: height,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final double height;

  const _AnimatedPrimaryButton({
    required this.text,
    required this.onTap,
    this.gradientColors,
    this.height = 52,
  });

  @override
  State<_AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<_AnimatedPrimaryButton> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? 0.98 : 1,
        child: _PrimaryButton(
          text: widget.text,
          onTap: widget.onTap,
          gradientColors: widget.gradientColors,
          height: widget.height,
        ),
      ),
    );
  }
}

class _AnimatedSocialButton extends StatelessWidget {
  final String label;
  final String iconAsset;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _AnimatedSocialButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressScale(
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Image.asset(iconAsset, width: 20, height: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  final Widget child;

  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;
  void _set(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _pressed ? 0.98 : 1,
        child: Stack(alignment: Alignment.center, children: [widget.child]),
      ),
    );
  }
}

class _SkyBackground extends StatelessWidget {
  const _SkyBackground();

  @override
  Widget build(BuildContext context) {
    return _SkyBackgroundAnimated();
  }
}

class _SkyBackgroundAnimated extends StatefulWidget {
  @override
  State<_SkyBackgroundAnimated> createState() => _SkyBackgroundAnimatedState();
}

class _SkyBackgroundAnimatedState extends State<_SkyBackgroundAnimated>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * math.pi;
          final dx1 = 6 * math.sin(t);
          final dy1 = 4 * math.cos(t);
          final dx2 = 8 * math.cos(t * 0.8);
          final dy2 = 5 * math.sin(t * 0.8);
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.skyLight, AppColors.skyMid],
                  ),
                ),
              ),
              Positioned(
                top: -40 + dy1,
                right: -20 + dx1,
                child: Opacity(
                  opacity: 0.35,
                  child: _Blob(size: 160, color: AppColors.accent),
                ),
              ),
              Positioned(
                bottom: -50 + dy2,
                left: -20 + dx2,
                child: Opacity(
                  opacity: 0.25,
                  child: _Blob(size: 200, color: AppColors.skyDeep),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color),
        ),
      ),
    );
  }
}
