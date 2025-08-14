// 📁 lib/presentation/screens/user/mypage_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/app/theme/app_colors.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../login/login_screen.dart';

// 위젯 imports
import 'widgets/glass_card.dart';
// removed unused: icon_input_field, primary/secondary button (moved into widgets)
import 'widgets/info_row.dart';
// removed unused: menu_button
import 'widgets/profile_card.dart';
import 'widgets/account_actions_card.dart';
import 'widgets/profile_image_picker_sheet.dart';
import 'widgets/sky_background.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // 임시 사용자 데이터 (실제로는 API에서 가져옴)
  Map<String, dynamic> _userInfo = {
    'id': 1,
    'email': 'user@example.com',
    'nickname': '사용자',
    'profileImage': null,
    'createdAt': '2024-01-01',
  };

  File? _selectedImage;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = _userInfo['nickname'];
    _loadUserInfo();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final response = await authService.getUserInfo();

      setState(() {
        _userInfo = response;
        _nicknameController.text = response['nickname'] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진 촬영 중 오류가 발생했습니다')));
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ProfileImagePickerSheet(
          onTakePhoto: _takePhoto,
          onPickGallery: _pickImage,
        );
      },
    );
  }

  String? _validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    if (value.length < 2) {
      return '닉네임은 2자 이상이어야 합니다';
    }
    if (value.length > 10) {
      return '닉네임은 10자 이하여야 합니다';
    }
    return null;
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 사용자 정보 수정 API 호출
      // PUT /api/users/me
      // Authorization: Bearer {JWT_TOKEN}
      // Content-Type: multipart/form-data
      // {
      //   "nickname": _nicknameController.text,
      //   "profileImage": _selectedImage (optional)
      // }

      // 임시 딜레이 (실제 API 호출 시 제거)
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _userInfo['nickname'] = _nicknameController.text;
        if (_selectedImage != null) {
          _userInfo['profileImage'] = _selectedImage!.path;
        }
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('정보가 성공적으로 수정되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('정보 수정 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(false);
                }
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.logout();

      // UserProvider에서도 로그아웃 처리
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.logout();
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그아웃되었습니다')));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // 1단계: 상세한 경고 메시지
    final showWarning = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.notoSansTextTheme(
              Theme.of(context).textTheme,
            ),
            // Use default dialogTheme; apply font via textTheme above
          ),
          child: AlertDialog(
            title: const Text(
              '회원탈퇴 안내',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '회원탈퇴 시 다음 데이터가 영구적으로 삭제됩니다:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWarningItem('• 개인 정보 (이메일, 닉네임, 프로필 이미지)'),
                  _buildWarningItem('• 모든 리캡 카드와 앨범'),
                  _buildWarningItem('• 업로드된 사진들'),
                  _buildWarningItem('• 친구 목록 및 관계'),
                  _buildWarningItem('• 앱 사용 기록'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '탈퇴 후에는 복구가 불가능합니다!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '중요한 사진이나 앨범이 있다면 먼저 백업하시기를 권장합니다.',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 153, 0),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(context).pop(false);
                  }
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('탈퇴 진행'),
              ),
            ],
          ),
        );
      },
    );

    if (showWarning != true) return;

    // 2단계: 비밀번호 확인
    final passwordController = TextEditingController();
    final passwordConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.notoSansTextTheme(
              Theme.of(context).textTheme,
            ),
            // Use default dialogTheme
          ),
          child: AlertDialog(
            title: const Text(
              '비밀번호 확인',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '회원탈퇴를 위해\n현재 비밀번호를 입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (passwordController.text.isNotEmpty && mounted) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('탈퇴 확인'),
              ),
            ],
          ),
        );
      },
    );

    if (passwordConfirmed != true) return;

    // 3단계: 최종 확인
    final finalConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: GoogleFonts.notoSansTextTheme(
              Theme.of(context).textTheme,
            ),
            // Use default dialogTheme
          ),
          child: AlertDialog(
            title: const Text(
              '최종 확인',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  '정말로 회원탈퇴를 진행하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '이 작업은 되돌릴 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('탈퇴 완료'),
              ),
            ],
          ),
        );
      },
    );

    if (finalConfirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.deleteAccount(passwordController.text);

      if (mounted) {
        // UserProvider에서도 로그아웃 처리
        if (mounted) {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.logout();
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('회원탈퇴가 완료되었습니다. 그동안 이용해주셔서 감사했습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원탈퇴 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SkyBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      children: [
                        // 헤더
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios),
                              color: AppColors.textPrimary,
                            ),
                            Expanded(
                              child: Text(
                                '마이페이지',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jua(
                                  fontSize: 24,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // 균형 맞추기
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 프로필 섹션 (분리 위젯 사용)
                        ProfileCard(
                          isEditing: _isEditing,
                          nicknameController: _nicknameController,
                          email: _userInfo['email'],
                          nickname: _userInfo['nickname'],
                          profileImageUrl: _userInfo['profileImage'],
                          selectedImage: _selectedImage,
                          onEdit: () => setState(() => _isEditing = true),
                          onCancel: () => setState(() {
                            _isEditing = false;
                            _nicknameController.text = _userInfo['nickname'];
                            _selectedImage = null;
                          }),
                          onSave: _updateUserInfo,
                          onOpenImagePicker: _showImagePickerDialog,
                        ),
                        const SizedBox(height: 20),

                        // 계정 정보
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '계정 정보',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              InfoRow(
                                label: '가입일',
                                value: _userInfo['createdAt'],
                                icon: Icons.calendar_today,
                              ),
                              const SizedBox(height: 12),
                              InfoRow(
                                label: '이메일',
                                value: _userInfo['email'],
                                icon: Icons.email,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 계정 관리
                        AccountActionsCard(
                          onLogout: _logout,
                          onDelete: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
