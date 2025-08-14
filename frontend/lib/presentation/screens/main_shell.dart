import 'package:flutter/material.dart';
import 'package:frontend/app/theme/app_colors.dart';
import 'user/mypage_screen.dart';
import 'qr/qr_scanner_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; // 0: 홈, 1: 앨범, 2: QR, 3: 공유, 4: 마이페이지

  final List<Widget> _pages = const [
    _PlaceholderScreen(title: '홈'),
    _PlaceholderScreen(title: '앨범 관리'),
    _PlaceholderScreen(title: 'QR 스캔'), // 눌렀을 때 별도 화면 push
    _PlaceholderScreen(title: '공유 및 친구'),
    MyPageScreen(),
  ];

  Future<void> _onNavTap(int index) async {
    if (index == 2) {
      // QR 스캔은 별도 전체 화면으로 푸시
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '앨범',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            selectedIcon: Icon(Icons.qr_code),
            label: 'QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '공유',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('$title 준비 중', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
