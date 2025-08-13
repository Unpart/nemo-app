import 'dart:convert';
import 'package:http/http.dart' as http;
import '../presentation/screens/login/signup_form_model.dart';

class AuthService {
  // ✅ 서버 URL 설정 (로컬 or 배포 서버로 교체해야 함)
  static const String baseUrl =
      'https://your-api-url.com'; // ← TODO: 실제 주소로 바꿔!

  // JWT 토큰 저장소
  static String? _accessToken;

  // JWT 토큰 설정
  static void setAccessToken(String token) {
    _accessToken = token;
  }

  // JWT 토큰 제거
  static void clearAccessToken() {
    _accessToken = null;
  }

  // JWT 토큰이 포함된 헤더 생성
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  /// 로그인 요청
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 로그인 성공 시 토큰 저장
        setAccessToken(data['accessToken']);
        return {
          'success': true,
          'accessToken': data['accessToken'],
          'userId': data['userId'],
          'nickname': data['nickname'],
          'profileImageUrl': data['profileImageUrl'],
        };
      } else if (response.statusCode == 401) {
        throw Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? '잘못된 요청입니다.');
      } else {
        throw Exception('로그인 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 회원가입 요청
  Future<bool> signup(SignupFormModel form) async {
    final uri = Uri.parse('$baseUrl/api/users/signup');

    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: false),
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

  /// 이메일 인증 메일 발송
  Future<void> sendEmailVerification(String email) async {
    final uri = Uri.parse('$baseUrl/api/auth/email/verification/send');
    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200) {
        if (response.statusCode == 429) {
          throw Exception('요청이 너무 많습니다. 잠시 후 다시 시도해주세요.');
        }
        final body = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
        throw Exception(
          body != null && body['message'] != null
              ? body['message']
              : '인증 메일 발송 실패 (${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 이메일 인증 코드 확인
  Future<bool> confirmEmailVerification({
    required String email,
    required String code,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/email/verification/confirm');
    try {
      final response = await http.post(
        uri,
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email, 'code': code}),
      );
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? '인증 코드가 올바르지 않습니다.');
      } else {
        throw Exception('인증 확인 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 사용자 정보 조회 (JWT 토큰 필요)
  Future<Map<String, dynamic>> getUserInfo() async {
    final uri = Uri.parse('$baseUrl/api/users/me');

    try {
      final response = await http.get(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('인증이 필요합니다.');
      } else {
        throw Exception('사용자 정보 조회 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 로그아웃 (JWT 토큰 무효화)
  Future<bool> logout() async {
    final uri = Uri.parse('$baseUrl/api/users/logout');

    try {
      final response = await http.post(uri, headers: _getHeaders());

      if (response.statusCode == 200) {
        // 로컬 토큰 제거
        clearAccessToken();
        return true;
      } else {
        throw Exception('로그아웃 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }

  /// 회원탈퇴 (비밀번호 확인 필요)
  Future<bool> deleteAccount(String password) async {
    final uri = Uri.parse('$baseUrl/api/users/me');

    try {
      final response = await http.delete(
        uri,
        headers: _getHeaders(),
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        // 로컬 토큰 제거
        clearAccessToken();
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('비밀번호가 올바르지 않습니다.');
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? '잘못된 요청입니다.');
      } else {
        throw Exception('회원탈퇴 실패 (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('네트워크 오류: $e');
    }
  }
}
