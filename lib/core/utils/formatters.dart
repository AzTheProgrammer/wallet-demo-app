import 'package:intl/intl.dart';

final _day = DateFormat('d MMM yyyy');
final _dayTime = DateFormat('d MMM yyyy, HH:mm');
final _monthYear = DateFormat('MMMM yyyy');

String formatDay(DateTime date) => _day.format(date);

String formatDayTime(DateTime date) => _dayTime.format(date);

String formatMonthYear(DateTime date) => _monthYear.format(date);

String groupToken(String token) {
  final buffer = StringBuffer();
  for (var i = 0; i < token.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(token[i]);
  }
  return buffer.toString();
}

String formatPoints(int points) =>
    NumberFormat('#,##0').format(points).replaceAll(',', ' ');
