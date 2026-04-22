// ignore_for_file: avoid_print

class DateFormatter {
  static String formatSmart(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(messageDate).inDays;
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    if (difference == 0) {
      return time;
    } else if (difference == 1) {
      return 'Вчера $time';
    } else if (difference < 7) {
      const days = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
      return '${days[messageDate.weekday % 7]} $time';
    } else if (date.year == now.year) {
      const months = [
        '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
        'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'
      ];
      return '${messageDate.day} ${months[messageDate.month]} $time';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)} $time';
    }
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String formatFull(DateTime date) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    const days = ['воскресенье', 'понедельник', 'вторник', 'среду', 'четверг', 'пятницу', 'субботу'];
    
    return '${date.day} ${months[date.month]} ${date.year}, ${days[date.weekday % 7]}, ${formatTime(date)}';
  }
}