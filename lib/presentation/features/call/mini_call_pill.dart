import 'package:flutter/material.dart';

import '../../widgets/user_avatar.dart';

/// 最小化后的全局悬浮通话胶囊（单聊语音/视频与群聊语音共用）：
/// 初始位于右上半区，可任意拖动，点击（位移 <8px）回到全屏通话页。
class DraggableMiniCallPill extends StatefulWidget {
  final String name;
  final String? avatarUrl;

  /// 状态文案：通话中时长 / 来电中… / 等待接听…
  final String status;

  /// 尾部圆形小图标（语音=电话，视频=摄像头，群聊=群语音）。
  final IconData icon;

  final VoidCallback onTap;

  const DraggableMiniCallPill({
    super.key,
    required this.name,
    required this.status,
    required this.onTap,
    this.avatarUrl,
    this.icon = Icons.call_rounded,
  });

  @override
  State<DraggableMiniCallPill> createState() => _DraggableMiniCallPillState();
}

class _DraggableMiniCallPillState extends State<DraggableMiniCallPill> {
  final _pillKey = GlobalKey();
  // null = 使用右上半区初始锚点；开始拖动后转换为显式 left/top。
  Offset? _pos;
  double _moved = 0;

  void _clampPosition(Size screen, EdgeInsets padding) {
    final p = _pos;
    if (p == null) return;
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    final w = box?.size.width ?? 200;
    final h = box?.size.height ?? 56;
    final minX = 8.0;
    final maxX = screen.width - w - 8;
    final minY = padding.top + 8;
    final maxY = screen.height - padding.bottom - h - 8;
    _pos = Offset(
      p.dx.clamp(minX, maxX < minX ? minX : maxX),
      p.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double? left = _pos?.dx;
    final double? top = _pos?.dy;
    final double? right = _pos == null ? 16 : null;
    return Positioned(
      left: left,
      top: top ?? (_pos == null ? mq.padding.top + 96 : null),
      right: right,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          key: _pillKey,
          onPanStart: (_) {
            _moved = 0;
            if (_pos == null) {
              final box =
                  _pillKey.currentContext?.findRenderObject() as RenderBox?;
              final tl = box?.localToGlobal(Offset.zero);
              if (tl != null) _pos = tl;
            }
          },
          onPanUpdate: (d) {
            final p = _pos;
            if (p == null) return;
            _moved += d.delta.distance;
            setState(() {
              _pos = p + d.delta;
              _clampPosition(mq.size, mq.padding);
            });
          },
          onPanEnd: (_) {
            if (_moved < 8) widget.onTap();
          },
          child: _pillContent(),
        ),
      ),
    );
  }

  Widget _pillContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2A44),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(
            name: widget.name,
            avatarUrl: widget.avatarUrl,
            size: 40,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(widget.icon, color: const Color(0xFF34D399), size: 22),
        ],
      ),
    );
  }
}
