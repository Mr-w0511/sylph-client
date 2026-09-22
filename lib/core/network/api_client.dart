import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/secure_store.dart';
import 'api_exceptions.dart';

/// 统一 HTTP 客户端：
/// 1) 请求自动注入 Bearer accessToken；
/// 2) 401 / 业务码 40101、40102 时用 refreshToken 调 /api/auth/refresh
///    （全局单飞），成功后重试原请求一次，再失败清空登录态并回调；
/// 3) 解包后端统一信封 {code,message,traceId,data}，code != 0 抛 [BizException]。
class ApiClient {
  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';

  final SecureStore _store;
  final Dio dio;
  final Dio _plain;

  /// 刷新彻底失败时回调（会话控制器清态回登录页）。
  void Function()? onAuthLost;

  bool _refreshing = false;
  Future<String?>? _refreshFuture;

  /// 内存中的当前 accessToken（WebSocket 建连需同步读取；持久副本在 store）。
  String? accessTokenSync;
  String? refreshTokenSync;

  ApiClient(this._store)
      : dio = Dio(BaseOptions(
          baseUrl: Env.apiBase,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )),
        _plain = Dio(BaseOptions(baseUrl: Env.apiBase)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _store.read(_kAccess);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<void> saveTokens(String access, String refresh) async {
    accessTokenSync = access;
    refreshTokenSync = refresh;
    await _store.write(_kAccess, access);
    await _store.write(_kRefresh, refresh);
  }

  Future<void> updateAccessToken(String access) async {
    accessTokenSync = access;
    await _store.write(_kAccess, access);
  }

  Future<String?> get accessToken async => accessTokenSync ??= await _store.read(_kAccess);

  /// 启动时把持久 token 载入内存。
  Future<void> hydrateTokens() async {
    accessTokenSync = await _store.read(_kAccess);
    refreshTokenSync = await _store.read(_kRefresh);
  }

  Future<void> clearTokens() async {
    accessTokenSync = null;
    refreshTokenSync = null;
    await _store.delete(_kAccess);
    await _store.delete(_kRefresh);
  }

  Future<Map<String, dynamic>?> get(String path,
          {Map<String, dynamic>? query}) =>
      request('GET', path, queryParameters: query);

  Future<Map<String, dynamic>?> post(String path, {Object? data}) =>
      request('POST', path, data: data);

  Future<Map<String, dynamic>?> put(String path, {Object? data}) =>
      request('PUT', path, data: data);

  Future<Map<String, dynamic>?> delete(String path, {Object? data}) =>
      request('DELETE', path, data: data);

  /// multipart 上传（web 支持 bytes）。
  Future<Map<String, dynamic>?> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    String type = 'FILE',
  }) {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
      'type': type,
    });
    return request('POST', path, data: form);
  }

  Future<Map<String, dynamic>?> request(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isRetry = false,
  }) async {
    Response<dynamic> resp;
    try {
      resp = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException();
      }
      // HTTP 401（Spring Security 直接返回的信封）也尝试刷新。
      if (e.response != null && !isRetry &&
          e.response!.statusCode == 401) {
        if (await _tryRefreshAndRetry()) {
          return request(method, path,
              data: data, queryParameters: queryParameters, isRetry: true);
        }
      }
      throw _errorFromResponse(e.response);
    }

    final body = _asMap(resp.data);
    final code = (body?['code'] as num?)?.toInt() ?? -1;
    if (code == 0) {
      final d = body?['data'];
      return d is Map<String, dynamic> ? d : null;
    }
    // 业务码层面的 token 失效。
    if ((code == 40101 || code == 40102) && !isRetry) {
      if (await _tryRefreshAndRetry()) {
        return request(method, path,
            data: data, queryParameters: queryParameters, isRetry: true);
      }
    }
    throw BizException(code, (body?['message'] as String?) ?? '请求失败',
        httpStatus: resp.statusCode);
  }

  /// 不限制 data 形态的原始请求，返回信封 data（Map/List/标量均可）。
  Future<dynamic> requestDynamic(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isRetry = false,
  }) async {
    Response<dynamic> resp;
    try {
      resp = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException();
      }
      if (e.response != null && !isRetry &&
          e.response!.statusCode == 401) {
        if (await _tryRefreshAndRetry()) {
          return requestDynamic(method, path,
              data: data, queryParameters: queryParameters, isRetry: true);
        }
      }
      throw _errorFromResponse(e.response);
    }
    final body = _asMap(resp.data);
    final code = (body?['code'] as num?)?.toInt() ?? -1;
    if (code == 0) return body?['data'];
    if ((code == 40101 || code == 40102) && !isRetry) {
      if (await _tryRefreshAndRetry()) {
        return requestDynamic(method, path,
            data: data, queryParameters: queryParameters, isRetry: true);
      }
    }
    throw BizException(code, (body?['message'] as String?) ?? '请求失败',
        httpStatus: resp.statusCode);
  }

  Future<bool> _tryRefreshAndRetry() async {
    final refresh = await _store.read(_kRefresh);
    if (refresh == null || refresh.isEmpty) {
      _notifyAuthLost();
      return false;
    }
    final fut = _refreshFuture ??= _doRefresh(refresh);
    try {
      final newAccess = await fut;
      return newAccess != null;
    } finally {
      // 让下一轮失败可以重新尝试（单飞仅针对同一次 401 风暴）。
      if (!_refreshing) _refreshFuture = null;
    }
  }

  Future<String?> _doRefresh(String refreshToken) async {
    _refreshing = true;
    try {
      final resp = await _plain.post<dynamic>('/api/auth/refresh',
          data: {'refreshToken': refreshToken});
      final body = _asMap(resp.data);
      final code = (body?['code'] as num?)?.toInt() ?? -1;
      if (code == 0 && body?['data'] is Map) {
        final access = body!['data']['accessToken'] as String?;
        if (access != null) {
          accessTokenSync = access;
          await _store.write(_kAccess, access);
          return access;
        }
      }
      _notifyAuthLost();
      return null;
    } catch (_) {
      _notifyAuthLost();
      return null;
    } finally {
      _refreshing = false;
    }
  }

  void _notifyAuthLost() {
    clearTokens();
    onAuthLost?.call();
  }

  ApiException _errorFromResponse(Response<dynamic>? resp) {
    final body = _asMap(resp?.data);
    if (body != null && body['code'] is num) {
      return BizException(
        (body['code'] as num).toInt(),
        (body['message'] as String?) ?? '请求失败',
        httpStatus: resp?.statusCode,
      );
    }
    return NetworkException('HTTP ${resp?.statusCode ?? '-'}');
  }

  Map<String, dynamic>? _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : null;
}
