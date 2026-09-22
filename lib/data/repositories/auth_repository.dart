import '../../core/network/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);

  Future<AppUser> register({
    required String username,
    required String password,
    String? nickname,
  }) async {
    final data = await api.post('/api/auth/register', data: {
      'username': username,
      'password': password,
      if (nickname != null && nickname.trim().isNotEmpty)
        'nickname': nickname.trim(),
    }) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  /// 旧的 username + password 登录（兼容旧客户端，不再是主流程）。
  Future<TokenPair> login({
    required String username,
    required String password,
    required DeviceInfo device,
  }) async {
    final data = await api.post('/api/auth/login', data: {
      'username': username,
      'password': password,
      'device': device.toJson(),
    }) as Map<String, dynamic>;
    return TokenPair.fromJson(data);
  }

  /// 发送邮箱验证码（登录或注册通用，未注册邮箱首次登录时自动创建账号）。
  Future<void> sendEmailCode(String email) async {
    await api.post('/api/auth/send-email-code', data: {'email': email.trim()});
  }

  /// 邮箱 + 验证码登录。首次登录后端自动注册并生成 8 位 UID。
  Future<TokenPair> loginByEmail({
    required String email,
    required String code,
    required DeviceInfo device,
  }) async {
    final data = await api.post('/api/auth/login-by-email', data: {
      'email': email.trim(),
      'code': code.trim(),
      'device': device.toJson(),
    }) as Map<String, dynamic>;
    return TokenPair.fromJson(data);
  }

  /// UID + 密码登录（次级登录方式）。
  Future<TokenPair> loginByUid({
    required String uid,
    required String password,
    required DeviceInfo device,
  }) async {
    final data = await api.post('/api/auth/login-by-uid', data: {
      'uid': uid.trim(),
      'password': password,
      'device': device.toJson(),
    }) as Map<String, dynamic>;
    return TokenPair.fromJson(data);
  }

  /// 首次设置初始密码（邮箱登录后用户主动设置）。
  Future<void> setInitialPassword(String password) async =>
      api.post('/api/auth/set-password', data: {'password': password});

  /// 修改密码（需已设置过密码）。
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      api.post('/api/auth/change-password',
          data: {'oldPassword': oldPassword, 'newPassword': newPassword});

  Future<void> logout() async {
    await api.post('/api/auth/logout');
  }
}
