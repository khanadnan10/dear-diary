class DateFormatter {
  static final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  /// Formats a UTC DateTime into local format: "Monday, May 11, 2026"
  static String formatDate(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final weekday = _weekdays[local.weekday - 1];
    final month = _months[local.month - 1];
    return '$weekday, $month ${local.day}, ${local.year}';
  }

  /// Formats a UTC DateTime into local format with time: "May 11, 2026 at 10:21 PM"
  static String formatDateWithTime(DateTime utcDateTime) {
    final local = utcDateTime.toLocal();
    final month = _months[local.month - 1].substring(0, 3);
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} at $hour:$minute $amPm';
  }

  /// Formats a duration into a playback string: "05:14" or "01:12:30"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }
}
