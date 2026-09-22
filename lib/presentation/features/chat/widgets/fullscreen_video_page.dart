// #12 视频消息全屏播放页：竖屏沉浸、点击切换控制条、底部进度条可拖动。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/config/env.dart';

class FullscreenVideoPage extends StatefulWidget {
  final String url;

  const FullscreenVideoPage({super.key, required this.url});

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  VideoPlayerController? _c;
  Object? _error;
  bool _controls = true;
  bool _seeking = false;
  double _seekValue = 0;

  /// 防止退出流程重复恢复系统栏（系统返回手势 + 关闭按钮 + dispose 兜底竞态）。
  bool _restored = false;

  /// 恢复系统状态栏/导航栏。
  /// 必须在路由 pop **之前** await 完成：放在 dispose 里时页面视图正在
  /// detach，平台消息可能被系统丢弃（国产 ROM 高发），导致返回聊天页后
  /// 状态栏仍保持 immersiveSticky 隐藏态，用户只能下滑临时看到时间。
  Future<void> _restoreSystemUi() async {
    if (_restored) return;
    _restored = true;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // 恢复失败不阻塞退出，dispose 还会再兜底一次。
    }
  }

  /// 统一退出入口：先恢复系统栏，再 pop 页面。
  Future<void> _exit() async {
    await _restoreSystemUi();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(Env.mediaUrl(widget.url)),
    );
    _c = c;
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {});
      await c.play();
      c.addListener(_onTick);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onTick() {
    if (mounted && !_seeking) setState(() {});
  }

  @override
  void dispose() {
    // 兜底：正常退出已在 pop 前恢复；若走了异常销毁路径（进程切换等），
    // 这里再尝试一次，避免沉浸式标志泄漏到其他页面。
    if (!_restored) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    // 拦截系统返回手势/返回键：先恢复系统栏再放行 pop，
    // 避免沉浸式状态泄漏回聊天页（状态栏被隐藏、只能下滑看到时间）。
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _error != null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        '视频加载失败',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : c == null || !c.value.isInitialized
                  ? const CircularProgressIndicator(color: Colors.white70)
                  : AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
            ),
            // 点击层：播放/暂停 + 控制条显隐。
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (c == null || !c.value.isInitialized) return;
                  setState(() {
                    _controls = !_controls;
                    if (c.value.isPlaying) {
                      c.pause();
                    } else {
                      c.play();
                    }
                  });
                },
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _exit,
              ),
            ),
            if (c != null && c.value.isInitialized && _controls)
              Positioned(
                left: 12,
                right: 12,
                bottom: 8,
                child: Row(
                  children: [
                    Text(
                      _fmt(c.value.position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: _seeking
                              ? _seekValue
                              : c.value.position.inMilliseconds
                                    .clamp(
                                      0,
                                      c.value.duration.inMilliseconds,
                                    )
                                    .toDouble(),
                          max: c.value.duration.inMilliseconds.toDouble(),
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChangeStart: (v) {
                            _seeking = true;
                            _seekValue = v;
                          },
                          onChanged: (v) => setState(() => _seekValue = v),
                          onChangeEnd: (v) async {
                            await c.seekTo(
                              Duration(milliseconds: v.round()),
                            );
                            _seeking = false;
                            if (!c.value.isPlaying) await c.play();
                          },
                        ),
                      ),
                    ),
                    Text(
                      _fmt(c.value.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
