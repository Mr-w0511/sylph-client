import 'dart:async';
import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// 相册图片解码使用独立 ML Kit 实例：mobile_scanner.analyzeImage 在 release
// 混淆包上同样会 getClient() 空指针，且 PlatformException 被吞成 null。
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    as ml;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sylph_client/l10n/app_localizations.dart';

import '../../../core/monitor/crash_reporter.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';
import '../contacts/user_profile_page.dart';

/// 解析 sylph://u/{token} 与 sylph://g/{token}，支持裸 token / 数字 UID / 群号输入。
/// kind 取值：'u' 用户名片 token；'g' 群名片 token；'gnum' 群号（G#######）；
/// 'unum' 8 位数字 UID。
({String kind, String token})? parseSylphCode(String raw) {
  final s = raw.trim();
  final m = RegExp(r'^sylph://(u|g)/([A-Za-z0-9_-]+)').firstMatch(s);
  if (m != null) return (kind: m.group(1)!, token: m.group(2)!);
  // 手动输入：群号 G + 6 位以上数字。
  if (RegExp(r'^G\d{6,}$').hasMatch(s)) {
    return (kind: 'gnum', token: s);
  }
  // 手动输入：纯 8 位数字 → UID（不能落到通用 token 分支，否则会被当成二维码 token）。
  if (RegExp(r'^\d{8}$').hasMatch(s)) {
    return (kind: 'unum', token: s);
  }
  // 手动输入：纯 token 默认按用户名片处理。
  if (RegExp(r'^[A-Za-z0-9_-]{8,}$').hasMatch(s)) {
    return (kind: 'u', token: s);
  }
  return null;
}

/// 当前是否为桌面平台（无相机或权限模型不同）。
bool get _isDesktop =>
    !kIsWeb &&
    (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// 当前是否为需要主动申请相机权限的移动平台。
bool get _isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 扫码后统一跳转：用户名片 → 用户详情；群名片/群号 → 群详情。
Future<void> handleSylphCode(
    BuildContext context, WidgetRef ref, String raw) async {
  final parsed = parseSylphCode(raw);
  final router = GoRouter.of(context);
  if (parsed == null) {
    AppToast.error(context, AppL10n.of(context).qrUnrecognized);
    return;
  }
  try {
    if (parsed.kind == 'u') {
      final brief = await ref.read(socialRepoProvider).resolveUser(parsed.token);
      if (context.mounted) {
        router.push('/user-profile', extra: UserProfileArgs(user: brief));
      }
    } else if (parsed.kind == 'unum') {
      // UID 走搜索接口（后端为 LIKE 模糊匹配），客户端再做等值精确过滤。
      final list = await ref.read(socialRepoProvider).search(parsed.token);
      final brief = list.where((u) => u.uid == parsed.token).firstOrNull;
      if (!context.mounted) return;
      if (brief == null) {
        AppToast.error(context, AppL10n.of(context).userNotFound);
        return;
      }
      router.push('/user-profile', extra: UserProfileArgs(user: brief));
    } else if (parsed.kind == 'gnum') {
      final brief =
          await ref.read(groupRepoProvider).resolveByNumber(parsed.token);
      if (context.mounted) router.push('/group-profile', extra: brief);
    } else {
      final brief =
          await ref.read(groupRepoProvider).resolve(parsed.token);
      if (context.mounted) router.push('/group-profile', extra: brief);
    }
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, AppL10n.of(context).qrInvalidReason('$e'));
    }
  }
}

/// 深链跳转：检查剪贴板是否含 sylph:// 链接，若未消费过则跳转到资料页。
/// 已是好友/群成员则静默跳过，每个链接仅跳转一次（持久化到 SharedPreferences）。
Future<void> checkClipboardDeepLink(
    BuildContext context, WidgetRef ref) async {
  // 仅处理完整的 sylph:// 链接，避免误触裸 token。
  String? raw;
  try {
    final data = await Clipboard.getData('text/plain');
    raw = data?.text;
  } catch (_) {
    return;
  }
  if (raw == null || !raw.startsWith('sylph://')) return;
  final parsed = parseSylphCode(raw);
  if (parsed == null) return;

  final prefs = await SharedPreferences.getInstance();
  final key = 'deeplink_consumed_${parsed.token}';
  if (prefs.getBool(key) == true) return;

  // 标记为已消费（无论跳转与否，避免重复触发）
  await prefs.setBool(key, true);

  final router = GoRouter.of(context);
  try {
    if (parsed.kind == 'u') {
      final brief = await ref.read(socialRepoProvider).resolveUser(parsed.token);
      // 已是好友则不跳转
      if (brief.relation == 'FRIEND') return;
      if (context.mounted) {
        router.push('/user-profile', extra: UserProfileArgs(user: brief));
      }
    } else if (parsed.kind == 'unum') {
      final list = await ref.read(socialRepoProvider).search(parsed.token);
      final brief = list.where((u) => u.uid == parsed.token).firstOrNull;
      if (brief == null || brief.relation == 'FRIEND') return;
      if (context.mounted) {
        router.push('/user-profile', extra: UserProfileArgs(user: brief));
      }
    } else if (parsed.kind == 'gnum') {
      final brief =
          await ref.read(groupRepoProvider).resolveByNumber(parsed.token);
      // 已是群成员则不跳转
      if (brief.relation == 'MEMBER') return;
      if (context.mounted) router.push('/group-profile', extra: brief);
    } else {
      final brief =
          await ref.read(groupRepoProvider).resolve(parsed.token);
      if (brief.relation == 'MEMBER') return;
      if (context.mounted) router.push('/group-profile', extra: brief);
    }
  } catch (_) {
    // 静默失败，不打扰用户
  }
}

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

/// 相机状态：初始化中 / 运行中 / 权限被拒 / 启动失败 / 当前设备不可用（桌面无相机）。
enum _CameraStatus { initializing, ready, permissionDenied, startFailed, unavailable }

class _ScanPageState extends ConsumerState<ScanPage> {
  MobileScannerController? _controller;
  final _manualCtrl = TextEditingController();

  /// 扫码节流：跳转期间只处理一次，返回后复位以支持连续扫码。
  bool _handled = false;
  bool _busy = false;

  /// 去重：DetectionSpeed.normal 会重复上报同一码，2s 内相同值忽略。
  String? _lastRaw;
  DateTime? _lastTime;

  _CameraStatus _status = _CameraStatus.initializing;
  bool _running = false;
  bool _torchOn = false;
  bool _torchSupported = false;

  /// 最近一次相机启动异常（错误面板展示原生原因，便于 logcat 定位）。
  MobileScannerException? _lastError;

  /// 启动看门狗：部分 ROM bindToLifecycle 既不成功也不回调错误，12s 兜底。
  Timer? _watchdog;

  /// 重试计数：每次重试换一个新 controller 实例。
  int _scannerKey = 0;

  @override
  void initState() {
    super.initState();
    CrashReporter.b('scan page enter');
    _bootstrapCamera();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _controller?.removeListener(_onControllerValue);
    _controller?.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  void _onControllerValue() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final v = controller.value;
    // 错误优先：启动失败立即呈现面板，避免被“无限转圈”遮罩吞掉。
    final error = v.error;
    if (error != null) {
      debugPrint(
          'scanner start failed: ${error.errorCode} ${error.errorDetails?.message ?? error.errorDetails ?? ''}');
      _watchdog?.cancel();
      final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
      final target =
          denied ? _CameraStatus.permissionDenied : _CameraStatus.startFailed;
      if (_status != target || _lastError != error) {
        setState(() {
          _lastError = error;
          _running = false;
          _status = target;
        });
      }
      return;
    }
    final running = v.isRunning;
    final torchSupported = v.torchState != TorchState.unavailable;
    if (running != _running ||
        torchSupported != _torchSupported ||
        (_torchOn != (v.torchState == TorchState.on)) ||
        (running && _status != _CameraStatus.ready)) {
      setState(() {
        _running = running;
        _torchSupported = torchSupported;
        _torchOn = v.torchState == TorchState.on;
        if (running) {
          _watchdog?.cancel();
          _status = _CameraStatus.ready;
        }
      });
    }
  }

  /// 按平台申请权限并创建相机控制器（控制器由 MobileScanner widget 负责 start）。
  Future<void> _bootstrapCamera() async {
    if (_isDesktop) {
      setState(() => _status = _CameraStatus.unavailable);
      return;
    }
    setState(() {
      _status = _CameraStatus.initializing;
      _running = false;
    });
    if (_isMobile) {
      final granted = await _requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _status = _CameraStatus.permissionDenied);
        return;
      }
    }
    _createController();
  }

  Future<bool> _requestPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted || status.isLimited;
  }

  void _createController() {
    final old = _controller;
    old?.removeListener(_onControllerValue);
    final controller = MobileScannerController(
      // 使用 normal 模式 + 250ms 节流，noDuplicates 在部分机型上会导致卡死。
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 250,
      formats: const [BarcodeFormat.qrCode],
    );
    CrashReporter.b('scan controller created #$_scannerKey');
    controller.addListener(_onControllerValue);
    _controller = controller;
    _scannerKey++;
    _lastError = null;
    // widget 挂载后会自动 start；listener 在 isRunning 时把状态切到 ready。
    if (mounted) setState(() {});
    // 旧 controller 延后一帧销毁：MobileScanner widget 在 dispose 时还会对它
    // 调 stop()，立刻 dispose 会抛 controllerDisposed 异常。
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          old.dispose();
        } catch (_) {}
      });
    }
    // 启动看门狗：12s 仍未运行且无错误回调 → 按启动失败呈现。
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      final v = _controller?.value;
      if (_status == _CameraStatus.initializing &&
          !(v?.isRunning ?? false) &&
          v?.error == null) {
        debugPrint('scanner start watchdog timeout');
        setState(() {
          _status = _CameraStatus.startFailed;
          _running = false;
        });
      }
    });
  }

  /// 错误面板点击“重试”：重建一个全新控制器。
  Future<void> _retryCamera() async {
    if (_isMobile) {
      final granted = await _requestPermission();
      if (!mounted) return;
      if (!granted) {
        setState(() => _status = _CameraStatus.permissionDenied);
        return;
      }
    }
    _createController();
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !_running || !_torchSupported) return;
    try {
      await controller.toggleTorch();
    } catch (e) {
      debugPrint('toggleTorch failed: $e');
      if (mounted) {
        AppToast.info(context, AppL10n.of(context).torchUnsupported);
      }
    }
  }

  /// 从相册选取图片并识别二维码。
  /// 使用 google_mlkit_barcode_scanning 直接解码（InputImage.fromFilePath
  /// 支持 content uri 与 HEIF，异常会正常抛出，不再被 method channel 吞掉）。
  Future<void> _pickFromAlbum() async {
    if (_busy) return;
    if (kIsWeb || _isDesktop) {
      AppToast.info(context, AppL10n.of(context).imageScanUnsupported);
      return;
    }
    _busy = true;
    ml.BarcodeScanner? scanner;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return;
      // 文件校验：部分机型选择器返回的缓存路径可能被清理。
      final f = File(path);
      if (!await f.exists() || await f.length() == 0) {
        if (mounted) {
          AppToast.error(context, AppL10n.of(context).imageReadFailed);
        }
        return;
      }
      final input = ml.InputImage.fromFilePath(path);
      // 先 QR 专用（速度快），未命中再全格式扫一遍。
      scanner = ml.BarcodeScanner(formats: const [ml.BarcodeFormat.qrCode]);
      var barcodes = await scanner.processImage(input);
      String? raw = barcodes.firstOrNull?.rawValue;
      if (raw == null || raw.isEmpty) {
        await scanner.close();
        scanner = ml.BarcodeScanner();
        barcodes = await scanner.processImage(input);
        raw = barcodes.firstOrNull?.rawValue;
      }
      debugPrint('album mlkit scan: ${barcodes.length} barcode(s)');
      if (!mounted) return;
      if (raw == null || raw.isEmpty) {
        AppToast.info(context, AppL10n.of(context).qrNotFound);
        return;
      }
      await handleSylphCode(context, ref, raw);
    } catch (e) {
      debugPrint('album mlkit scan failed: $e');
      if (mounted) {
        AppToast.error(
            context, AppL10n.of(context).imageScanFailedReason('$e'));
      }
    } finally {
      await scanner?.close();
      _busy = false;
    }
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_handled || _busy) return;
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    // 去重：2 秒内同一码值忽略
    final now = DateTime.now();
    if (_lastRaw == raw &&
        _lastTime != null &&
        now.difference(_lastTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRaw = raw;
    _lastTime = now;
    _handled = true;
    _busy = true;
    try {
      // 跳转目标页；返回后复位，允许连续扫描。
      await handleSylphCode(context, ref, raw);
    } finally {
      _busy = false;
      if (mounted) _handled = false;
    }
  }

  Future<void> _manualSubmit() async {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty || _busy) return;
    _busy = true;
    try {
      await handleSylphCode(context, ref, raw);
    } finally {
      _busy = false;
      if (mounted) _manualCtrl.clear();
    }
  }

  /// 是否挂载相机预览（widget 负责启动相机）。
  bool get _showCamera =>
      _controller != null &&
      (_status == _CameraStatus.initializing ||
          _status == _CameraStatus.ready);

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l.scanEntry, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // 闪光灯：仅在相机真正运行且设备支持时可点，避免 controllerUninitialized。
          if (_status == _CameraStatus.ready &&
              _running &&
              _torchSupported &&
              _isMobile)
            IconButton(
              tooltip: _torchOn ? l.torchOffTooltip : l.torchOnTooltip,
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off,
                  color: _torchOn ? Colors.amberAccent : Colors.white),
              onPressed: _busy ? null : _toggleTorch,
            ),
          IconButton(
            tooltip: l.galleryTooltip,
            icon: const Icon(Icons.photo_outlined, color: Colors.white),
            onPressed: _busy ? null : _pickFromAlbum,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_showCamera)
                  MobileScanner(
                    key: ValueKey('scanner_$_scannerKey'),
                    controller: _controller!,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) =>
                        _buildErrorPanel(error),
                  ),
                if (_status == _CameraStatus.initializing)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white70),
                  ),
                if (_status == _CameraStatus.permissionDenied)
                  _permissionPanel(),
                if (_status == _CameraStatus.startFailed) _startFailedPanel(),
                if (_status == _CameraStatus.unavailable)
                  _messagePanel(
                    icon: Icons.desktop_access_disabled_outlined,
                    text: l.cameraUnavailableManual,
                    actions: const [],
                  ),
                if (_status == _CameraStatus.ready && _running) _scanFrame(),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      l.scanHint,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: const Color(0xFF101010),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.go,
                      decoration: InputDecoration(
                        hintText: l.manualInputHint,
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 13),
                        prefixIcon: const Icon(Icons.keyboard_alt_outlined,
                            color: Colors.white54),
                      ),
                      onSubmitted: (_) => _manualSubmit(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _busy ? null : _manualSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(l.confirm),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 启动失败面板：展示原生错误简述 + 重试 + 打开系统设置。
  Widget _startFailedPanel() {
    final l = AppL10n.of(context);
    final detail =
        _lastError?.errorDetails?.message ?? _lastError?.toString();
    return _messagePanel(
      icon: Icons.no_photography_outlined,
      text: l.cameraStartFailed,
      detail:
          (detail == null || detail.isEmpty) ? null : l.reasonDetail(detail),
      actions: [
        _PanelButton(
          label: l.retry,
          icon: Icons.refresh,
          filled: true,
          onTap: _retryCamera,
        ),
        const SizedBox(height: 10),
        _PanelButton(
          label: l.openSystemSettings,
          icon: Icons.settings_outlined,
          onTap: () async {
            await openAppSettings();
          },
        ),
      ],
    );
  }

  /// 相机运行期错误（权限变更/设备占用/桌面无相机等）。
  Widget _buildErrorPanel(MobileScannerException error) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    if (denied) return _permissionPanel();
    if (_isDesktop) {
      return _messagePanel(
        icon: Icons.desktop_access_disabled_outlined,
        text: AppL10n.of(context).cameraUnavailableManual,
        actions: const [],
      );
    }
    return _startFailedPanel();
  }

  /// 权限被拒面板：重新授权 + 打开系统设置。
  Widget _permissionPanel() {
    final l = AppL10n.of(context);
    return _messagePanel(
      icon: Icons.camera_alt_outlined,
      text: l.cameraPermissionDenied,
      actions: [
        _PanelButton(
          label: l.reauthorize,
          icon: Icons.verified_user_outlined,
          filled: true,
          onTap: _retryCamera,
        ),
        const SizedBox(height: 10),
        _PanelButton(
          label: l.openSystemSettings,
          icon: Icons.settings_outlined,
          onTap: () async {
            await openAppSettings();
          },
        ),
      ],
    );
  }

  Widget _messagePanel({
    required IconData icon,
    required String text,
    String? detail,
    required List<Widget> actions,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 56),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75), fontSize: 13.5),
            ),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11.5),
              ),
            ],
            if (actions.isNotEmpty) const SizedBox(height: 20),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _scanFrame() {
    const box = 240.0;
    return IgnorePointer(
      child: SizedBox(
        width: box,
        height: box,
        child: CustomPaint(painter: _FramePainter()),
      ),
    );
  }
}

/// 错误/权限面板上的按钮。
class _PanelButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
    return filled
        ? FilledButton(onPressed: onTap, child: child)
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.45)),
            ),
            child: child,
          );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2EA6FF)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    final w = size.width;
    final h = size.height;
    // 四角
    canvas.drawLine(Offset.zero, const Offset(len, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, len), paint);
    canvas.drawLine(Offset(w, 0), Offset(w - len, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - len), paint);
    canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
