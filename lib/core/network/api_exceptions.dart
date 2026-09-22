/// 业务/网络异常体系。后端统一信封为 {code,message,traceId,data}，
/// code != 0 时抛出 [BizException]。
class ApiException implements Exception {
  final int code;
  final String message;
  final int? httpStatus;

  const ApiException(this.code, this.message, {this.httpStatus});

  bool get isUnauthorized => code == 40101 || code == 40102 || httpStatus == 401;

  @override
  String toString() => message;
}

class BizException extends ApiException {
  const BizException(super.code, super.message, {super.httpStatus});
}

class NetworkException extends ApiException {
  const NetworkException([String message = '网络连接失败']) : super(-1, message);
}
