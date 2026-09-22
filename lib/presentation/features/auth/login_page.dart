import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';

/// Telegram 风格登录页：邮箱验证码登录（主流程）+ UID/密码登录（次级）。
/// 渐变背景 + 装饰光斑 + 入场动画 + 白色圆角卡片。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // 邮箱验证码表单
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  // UID 密码表单
  final _uidFormKey = GlobalKey<FormState>();
  final _uidCtrl = TextEditingController();
  final _uidPwdCtrl = TextEditingController();
  bool _obscureUidPwd = true;

  bool _uidMode = false;
  bool _busy = false;
  bool _sendingCode = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String? _error;
  String? _info;

  late final AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _uidCtrl.dispose();
    _uidPwdCtrl.dispose();
    _resendTimer?.cancel();
    _enterCtrl.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    setState(() {});
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) t.cancel();
    });
  }

  bool _isValidEmail(String v) {
    final re = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return re.hasMatch(v.trim());
  }

  Future<void> _sendCode() async {
    final l = AppL10n.of(context);
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _error = l.emailHint;
        _info = null;
      });
      return;
    }
    setState(() {
      _sendingCode = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).sendEmailCode(email);
      if (!mounted) return;
      setState(() {
        _info = l.codeSent;
      });
      _startResendCountdown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = l.loginByEmailFailed);
      }
    } finally {
      if (mounted && _sendingCode) setState(() => _sendingCode = false);
    }
  }

  Future<void> _loginByEmail() async {
    final l = AppL10n.of(context);
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).loginByEmail(
            _emailCtrl.text,
            _codeCtrl.text,
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.loginByEmailFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _loginByUid() async {
    final l = AppL10n.of(context);
    if (!_uidFormKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(sessionControllerProvider.notifier).loginByUid(
            _uidCtrl.text,
            _uidPwdCtrl.text,
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.loginByUidFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final headerAnim = CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic));
    final cardAnim = CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.25, 1, curve: Curves.easeOutCubic));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B6EF6), Color(0xFF2EA6FF), Color(0xFF56C2FF)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            // 装饰光斑
            Positioned(
              top: -size.width * 0.22,
              right: -size.width * 0.18,
              child: _blob(size.width * 0.6, Colors.white.withValues(alpha: 0.14)),
            ),
            Positioned(
              bottom: -size.width * 0.15,
              left: -size.width * 0.2,
              child: _blob(size.width * 0.55,
                  const Color(0xFF7B5CFF).withValues(alpha: 0.28)),
            ),
            Positioned(
              top: size.height * 0.18,
              left: -size.width * 0.12,
              child: _blob(size.width * 0.3,
                  Colors.white.withValues(alpha: 0.10)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, viewport) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 28),
                    child: ConstrainedBox(
                      // 内容不足一屏时也撑满视口：卡片居中、协议提示钉底，
                      // 避免底部出现大片纯背景空白；键盘弹出时自动压缩可滚动。
                      constraints: BoxConstraints(
                          minHeight:
                              (viewport.maxHeight - 56).clamp(0.0, double.infinity)),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeTransition(
                              opacity: headerAnim,
                              child: SlideTransition(
                                position: Tween(
                                        begin: const Offset(0, -0.12),
                                        end: Offset.zero)
                                    .animate(headerAnim),
                                child: _brandHeader(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Spacer(flex: 2),
                            FadeTransition(
                              opacity: cardAnim,
                              child: SlideTransition(
                                position: Tween(
                                        begin: const Offset(0, 0.14),
                                        end: Offset.zero)
                                    .animate(cardAnim),
                                child: _formCard(l, theme),
                              ),
                            ),
                            const Spacer(flex: 3),
                            FadeTransition(
                              opacity: cardAnim,
                              child: _bottomHint(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double d, Color c) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)]),
        ),
      );

  Widget _brandHeader() {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (_, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 88,
            height: 88,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B6EF6), Color(0xFF2EA6FF)],
              ).createShader(r),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sylph',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Text(
            '轻量 · 私密 · 畅快的即时通讯',
            style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.2),
          ),
        ),
      ],
    );
  }

  Widget _formCard(AppL10n l, ThemeData theme) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeSwitch(l),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              // 仅淡入淡出，避免 SizeTransition 导致浮动 label 被裁切；
              // 新旧子项顶部对齐叠放，高度直接切换到新表单。
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  ?currentChild,
                ],
              ),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _uidMode
                  ? _buildUidForm(l, theme, key: const ValueKey('uid'))
                  : _buildEmailForm(l, theme, key: const ValueKey('email')),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _noticeBar(_error!, theme.colorScheme.error, Icons.error_outline),
            ],
            if (_info != null) ...[
              const SizedBox(height: 12),
              _noticeBar(_info!, theme.colorScheme.primary,
                  Icons.check_circle_outline),
            ],
          ],
        ),
      ),
    );
  }

  /// 分段式登录方式切换。
  Widget _modeSwitch(AppL10n l) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _modeTab(!_uidMode, Icons.mail_outline_rounded, l.loginByEmail,
              () => setState(() {
                    _uidMode = false;
                    _error = null;
                    _info = null;
                  })),
          _modeTab(_uidMode, Icons.badge_outlined, l.uidFieldLabel,
              () => setState(() {
                    _uidMode = true;
                    _error = null;
                    _info = null;
                  })),
        ],
      ),
    );
  }

  Widget _modeTab(bool active, IconData icon, String text, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? sylphBlue : const Color(0xFF8A94A6)),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: active ? sylphBlue : const Color(0xFF8A94A6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noticeBar(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _bottomHint() {
    return Text(
      '继续即表示同意 Sylph 服务协议与隐私政策',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: 12,
      ),
    );
  }

  // ---------------- 邮箱验证码表单 ----------------

  Widget _buildEmailForm(AppL10n l, ThemeData theme, {Key? key}) {
    return KeyedSubtree(
      key: key!,
      child: Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.emailFieldLabel,
              hintText: l.emailHint,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return l.fieldRequired;
              if (!_isValidEmail(s)) return l.emailHint;
              return null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l.verificationCode,
                    hintText: l.codeHint,
                    prefixIcon: const Icon(Icons.sms_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fieldRequired
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                width: 140,
                child: _sendCodeButton(l, theme),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _loginButton(l.loginByEmail, _loginByEmail),
        ],
      ),
      ),
    );
  }

  Widget _sendCodeButton(AppL10n l, ThemeData theme) {
    if (_resendSeconds > 0) {
      return FilledButton.tonal(
        onPressed: null,
        child: Text(l.resendIn(_resendSeconds)),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: _sendingCode ? null : _sendCode,
      icon: _sendingCode
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.send_rounded, size: 18),
      label: Text(l.sendEmailCode),
    );
  }

  // ---------------- UID 密码表单 ----------------

  Widget _buildUidForm(AppL10n l, ThemeData theme, {Key? key}) {
    return KeyedSubtree(
      key: key!,
      child: Form(
      key: _uidFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _uidCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l.uidFieldLabel,
              hintText: l.uidHint,
              prefixIcon: const Icon(Icons.tag),
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return l.fieldRequired;
              if (!RegExp(r'^\d{8}$').hasMatch(s)) return l.uidHint;
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _uidPwdCtrl,
            obscureText: _obscureUidPwd,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _loginByUid(),
            decoration: InputDecoration(
              labelText: l.password,
              hintText: l.passwordHint,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureUidPwd
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () =>
                    setState(() => _obscureUidPwd = !_obscureUidPwd),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? l.passwordHint : null,
          ),
          const SizedBox(height: 22),
          _loginButton(l.loginSubmit, _loginByUid),
        ],
      ),
      ),
    );
  }

  Widget _loginButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [sylphBlue, Color(0xFF2EA6FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: sylphBlue.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: _busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text(text,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
        ),
      ),
    );
  }
}
