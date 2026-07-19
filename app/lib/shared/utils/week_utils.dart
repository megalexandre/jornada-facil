/// Helpers de semana civil (segunda a domingo), em hora local.
class WeekUtils {
  /// Segunda-feira 00:00 (local) da semana de [date].
  static DateTime mondayOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// true se [dateTime] cai em [weekStart, weekStart + 7 dias).
  static bool isInWeek(DateTime dateTime, DateTime weekStart) {
    return !dateTime.isBefore(weekStart) &&
        dateTime.isBefore(weekStart.add(const Duration(days: 7)));
  }
}
