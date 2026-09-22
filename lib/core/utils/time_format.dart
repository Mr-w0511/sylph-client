import 'package:intl/intl.dart';

/// 时间格式化（服务端时间为 UTC ISO 字符串，解析后转本地展示）。
class TimeFmt {
  /// 会话列表：HH:mm / 昨天 / MM-dd / yyyy/MM/dd。
  static String listLabel(DateTime? utc,
      {String today = '今天', String yesterday = '昨天'}) {
    if (utc == null) return '';
    final t = utc.toLocal();
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diffDays = today0.difference(that).inDays;
    if (diffDays == 0) return DateFormat('HH:mm').format(t);
    if (diffDays == 1) return yesterday;
    if (diffDays < 7) return DateFormat('EEEE').format(t);
    if (t.year == now.year) return DateFormat('MM-dd').format(t);
    return DateFormat('yyyy/MM/dd').format(t);
  }

  /// 气泡时间。
  static String bubble(DateTime utc) =>
      DateFormat('HH:mm').format(utc.toLocal());

  /// 时间分隔条：今天 / 昨天 / 具体日期。
  static String dayDivider(DateTime utc,
      {String today = '今天', String yesterday = '昨天'}) {
    final t = utc.toLocal();
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final that = DateTime(t.year, t.month, t.day);
    final diffDays = today0.difference(that).inDays;
    if (diffDays == 0) return today;
    if (diffDays == 1) return yesterday;
    if (t.year == now.year) return DateFormat('M月d日 EEEE').format(t);
    return DateFormat('yyyy年M月d日 EEEE').format(t);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    final x = a.toLocal();
    final y = b.toLocal();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }
}
