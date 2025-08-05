// 📁 lib/presentation/screens/login/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: const Color.fromARGB(137, 29, 29, 29),
                      boxShadow: [
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
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '네컷\n모아',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jua(fontSize: 26),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFC),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInputField('아이디/이메일 입력'),
                    const SizedBox(height: 16),
                    _buildInputField('비밀번호 입력', obscure: true),
                    const SizedBox(height: 20),
                    _buildRoundedButton(
                      '회원가입',
                      onTap: () {
                        // TODO: 회원가입 로직
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSocialButton(
                label: '카카오로 시작하기',
                color: const Color(0xFFFFE812),
                textColor: Colors.black,
                iconAsset:
                    'lib/presentation/screens/login/assets/kakao_icon.png',
                iconSize: 24,
                iconPadding: EdgeInsets.only(right: 35),
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                label: 'Google로 시작하기',
                color: Colors.white,
                textColor: Colors.black87,
                iconAsset:
                    'lib/presentation/screens/login/assets/google_icon.png',
                iconSize: 24,
                iconPadding: EdgeInsets.only(right: 35),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text.rich(
                  TextSpan(
                    text: '이미 회원이신가요? ',
                    children: [
                      TextSpan(
                        text: '로그인',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6)),
        ],
      ),
      child: TextField(
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFDCE7F8),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD1E2FA),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color color,
    required Color textColor,
    required String iconAsset,
    double iconSize = 24,
    EdgeInsets iconPadding = EdgeInsets.zero,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 6)),
        ],
      ),
      child: ListTile(
        leading: Padding(
          padding: iconPadding,
          child: Image.asset(iconAsset, width: iconSize, height: iconSize),
        ),
        title: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          // TODO: 소셜 로그인 연동
        },
      ),
    );
  }
}
