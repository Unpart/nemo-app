import 'package:flutter/material.dart';
import 'presentation/screens/login/login_screen.dart';
import 'providers/provider.dart'; // ✅ 이거만 import하면 됨

void main() {
  runApp(const NemoApp());
}

class NemoApp extends StatelessWidget {
  const NemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppProviders(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginScreen(),
      ),
    );
  }
}
