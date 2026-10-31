
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const _emailKey = 'demo_email';
  static const _passwordKey = 'demo_password';
  static const _sessionKey = 'logged_in_email';

  // Đăng ký tài khoản thử nghiệm.
  static Future<String?> register(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.length < 6) {
      return 'Nhập email hợp lệ và mật khẩu ít nhất 6 ký tự.';
    }

    final existingEmail = prefs.getString(_emailKey);

    if (existingEmail == normalizedEmail) {
      return 'Email này đã được đăng ký trên thiết bị.';
    }

    await prefs.setString(_emailKey, normalizedEmail);
    await prefs.setString(_passwordKey, password);

    return null;
  }

  // Đăng nhập.
  static Future<String?> login(
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString(_emailKey);
    final savedPassword = prefs.getString(_passwordKey);

    if (email.trim().toLowerCase() != savedEmail ||
        password != savedPassword) {
      return 'Email hoặc mật khẩu không chính xác.';
    }

    await prefs.setString(
      _sessionKey,
      email.trim().toLowerCase(),
    );

    return null;
  }

  // Lấy email của phiên đăng nhập hiện tại.
  static Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  // Đăng xuất.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
