import '../../core/network/api_client.dart';
import '../models/models.dart';

class UserSearchResult {
  final List<AppUser> list;
  final int total;
  const UserSearchResult(this.list, this.total);
}

class UserRepository {
  final ApiClient api;
  UserRepository(this.api);

  Future<AppUser> me() async {
    final data = await api.get('/api/users/me') as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile({
    String? username,
    String? nickname,
    String? avatarUrl,
    String? bio,
    String? gender,
  }) async {
    final data = await api.put('/api/users/me', data: {
      'username': ?username,
      'nickname': ?nickname,
      'avatarUrl': ?avatarUrl,
      'bio': ?bio,
      'gender': ?gender,
    }) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  Future<UserSearchResult> search(String keyword,
      {int page = 1, int size = 20}) async {
    final data =
        await api.get('/api/users/search', query: {
      'keyword': keyword,
      'page': page,
      'size': size,
    }) as Map<String, dynamic>;
    final list = ((data['list'] as List?) ?? const [])
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return UserSearchResult(list, (data['total'] as num?)?.toInt() ?? 0);
  }

  Future<List<UserDevice>> devices() async {
    final data = await api.requestDynamic('GET', '/api/users/devices') as List;
    return data
        .map((e) => UserDevice.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> revokeDevice(int id) =>
      api.delete('/api/users/devices/$id');
}
