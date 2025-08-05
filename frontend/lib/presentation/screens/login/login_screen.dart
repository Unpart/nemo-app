// lib/presentation/screens/login/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_view_model.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(title: const Text('회원가입'), centerTitle: true),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // 프로필 이미지 선택 (추후 기능 연결 예정)
                  GestureDetector(
                    onTap: () {
                      // TODO: 이미지 선택 기능 구현 예정
                    },
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.camera_alt, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 이메일 입력
                  TextField(
                    onChanged: viewModel.setEmail,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 비밀번호 입력
                  TextField(
                    onChanged: viewModel.setPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 닉네임 입력
                  TextField(
                    onChanged: viewModel.setNickname,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 에러 메시지
                  if (viewModel.errorMessage != null)
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 16),

                  // 회원가입 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              final success = await viewModel.signup();
                              if (success && context.mounted) {
                                Navigator.pop(context); // 회원가입 후 로그인 화면으로
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text('회원가입'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
