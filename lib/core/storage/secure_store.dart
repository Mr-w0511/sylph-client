// 安全键值存储抽象。
//
// 平台实现通过条件导入选择：
// - 移动端/桌面：flutter_secure_storage（系统密钥环）
// - web：localStorage 封装（flutter_secure_storage 在 web 不可靠，
//   浏览器也无系统级密钥环；E2EE 私钥同样落 localStorage，见 e2ee_service）
export 'secure_store_stub.dart'
    if (dart.library.js_interop) 'secure_store_web.dart'
    if (dart.library.io) 'secure_store_native.dart';
