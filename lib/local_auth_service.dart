import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalAuthService {
  // Kept under the existing class name to avoid changing all callers.
  // Authentication is now handled by Firebase, not local SharedPreferences.

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> register(
    String email,
    String password, {
    String displayName = '',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty || password.length < 6) {
      return 'Nhập email hợp lệ và mật khẩu ít nhất 6 ký tự.';
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) return 'Không thể tạo tài khoản. Vui lòng thử lại.';

      final name = displayName.trim().isEmpty
          ? normalizedEmail.split('@').first
          : displayName.trim();

      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': normalizedEmail,
        'emailLower': normalizedEmail,
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } on FirebaseException catch (e) {
      return e.message ?? 'Không thể lưu hồ sơ người dùng trên Firestore.';
    } catch (_) {
      return 'Không thể tạo tài khoản. Vui lòng thử lại.';
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        final profile = _firestore.collection('users').doc(user.uid);
        final snapshot = await profile.get();
        if (!snapshot.exists) {
          final normalizedEmail = user.email ?? email.trim().toLowerCase();
          await profile.set({
            'uid': user.uid,
            'email': normalizedEmail,
            'emailLower': normalizedEmail,
            'displayName': user.displayName ??
                normalizedEmail.split('@').first,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } on FirebaseException catch (e) {
      return e.message ?? 'Không thể tải hồ sơ người dùng.';
    } catch (_) {
      return 'Đăng nhập không thành công. Vui lòng thử lại.';
    }
  }

  static String _authError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Hãy đăng nhập.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu cần có ít nhất 6 ký tự.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng thử lại.';
      default:
        return error.message ?? 'Xác thực thất bại. Vui lòng thử lại.';
    }
  }

  static Future<String?> currentUser() async => _auth.currentUser?.email;

  static Future<void> logout() async {
    await _auth.signOut();
  }
}
