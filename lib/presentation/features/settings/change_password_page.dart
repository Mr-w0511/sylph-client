import 'package:flutter/material.dart';
import 'package:sylph_client/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exceptions.dart';
import '../../state/providers.dart';
import '../../widgets/app_toast.dart';

/// 修改 / 设置初始密码页。
/// - [initialMode] = true：调用 POST /api/auth/set-password
/// - [initialMode] = false：调用 POST /api/auth/change-password
class ChangePasswordPage extends ConsumerStatefulWidget {
  final bool initialMode;
  const ChangePasswordPage({super.key, this.initialMode = false});

  @override
  ConsumerState<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _oldPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  String? _validatePwd(String v) {
    final l = AppL10n.of(context);
    if (v.isEmpty) return l.fieldRequired;
    if (v.length < 8) return l.newPasswordHint;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
    final hasDigit = RegExp(r'\d').hasMatch(v);
    if (!hasLetter || !hasDigit) return l.newPasswordHint;
    return null;
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_newPwd.text != _confirmPwd.text) {
      setState(() => _error = l.passwordMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notifier = ref.read(sessionControllerProvider.notifier);
      if (widget.initialMode) {
        await notifier.setInitialPassword(_newPwd.text);
      } else {
        await notifier.changePassword(_oldPwd.text, _newPwd.text);
      }
      if (!mounted) return;
      AppToast.success(
          context,
          widget.initialMode
              ? l.passwordSetSuccess
              : l.passwordChanged);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = l.operationFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialMode ? l.setInitialPassword : l.changePassword),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.initialMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(l.setInitialPasswordTip,
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 13)),
                  ),
                if (!widget.initialMode) ...[
                  TextFormField(
                    controller: _oldPwd,
                    obscureText: _obscureOld,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.oldPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureOld
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscureOld = !_obscureOld),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? l.fieldRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _newPwd,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.newPassword,
                    hintText: l.newPasswordHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) => _validatePwd(v ?? ''),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPwd,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: l.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l.fieldRequired
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white),
                        )
                      : Text(l.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
