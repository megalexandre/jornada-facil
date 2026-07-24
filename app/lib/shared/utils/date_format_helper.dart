class DateFormatHelper {
  static const List<String> monthNames = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const List<String> dayNames = [
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];

  /// Indexado por DateTime.weekday - 1 (segunda = 1).
  static const List<String> shortDayNames = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
    'DOM',
  ];

  static String formatDate(DateTime dateTime) {
    final dayName = dayNames[dateTime.weekday % 7];
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = monthNames[dateTime.month - 1];

    return '$dayName, $day de $month'.toUpperCase();
  }

  /// "06 a 12 de julho" (mesmo mês) ou "29 de junho a 05 de julho".
  static String formatWeekRange(DateTime start, DateTime end) {
    final startDay = start.day.toString().padLeft(2, '0');
    final endDay = end.day.toString().padLeft(2, '0');

    if (start.month == end.month) {
      return '$startDay a $endDay de ${monthNames[end.month - 1]}';
    }
    return '$startDay de ${monthNames[start.month - 1]} '
        'a $endDay de ${monthNames[end.month - 1]}';
  }

  /// "HH:MM:SS" de um instante (ex.: 09:07:03). Usado no relógio ao vivo.
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  /// "HH:MM" a partir de uma duração em minutos (ex.: 480 → "08:00",
  /// 2400 → "40:00"). Usado para totais de horas.
  static String hoursMinutes(int totalMinutes) {
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// dd/mm/aaaa hh:mm em hora local (a API envia timestamps em UTC).
  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/${local.year} $hour:$minute';
  }
}
