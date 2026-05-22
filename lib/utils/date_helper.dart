import 'package:intl/intl.dart';

class DateHelper {
  static String formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      // Convert to UTC, then apply IST offset (+5:30)
      final DateTime dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final DateTime dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  static String formatMessageDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final DateTime dateTime = DateTime.parse(dateStr).toUtc().add(const Duration(hours: 5, minutes: 30));
      final DateTime now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime yesterday = today.subtract(const Duration(days: 1));
      final DateTime msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (msgDate == today) {
        return "Today";
      } else if (msgDate == yesterday) {
        return "Yesterday";
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } catch (e) {
      return dateStr;
    }
  }
}
