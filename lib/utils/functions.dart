//トップレベル関数

import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeAgo;

String createTimeAgoString(DateTime postDateTime) {
  //現在の端末のロケールを取得
  final currentLocale = Intl.getCurrentLocale();

  //現在の日時を取得
  final now = DateTime.now();

  //投稿日時と現在日時の差分を取得
  final difference = now.difference(postDateTime);
  return timeAgo.format(now.subtract(difference), locale: currentLocale);
}
