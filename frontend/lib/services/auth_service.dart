import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/login/signup_form_model.dart';

class AuthService {
  // ✅ 서버 URL 설정 (로컬 or 배포 서버로 교체해야 함)
  static const String baseUrl =
      'https://your-api-url.com'; // ← TODO: 실제 주소로 바꿔!

  /// 회원가입 요청
  Future<bool> signup(SignupFormModel form) async {
    final uri = Uri.parse('$baseUrl/api/users/signup');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(form.toJson()),
      );

      if (response.statusCode == 201) {
        // 성공적으로 회원가입 완료
        return true;
      } else if (response.statusCode == 409) {
        throw Exception('이미 존재하는 이메일입니다.');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? '잘못된 요청입니다.');
      } else {
        throw Exception('회원가입 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }
}
