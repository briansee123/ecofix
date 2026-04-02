import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CheckInService {
  static const String key = "checkin_history";

  /// Save check-in
  static Future<void> addCheckIn(String location) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(key) ?? [];

    String formattedTime =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final newEntry = jsonEncode({
      "location": location,
      "time": formattedTime,
    });

    history.add(newEntry);

    await prefs.setStringList(key, history);
  }

  /// Retrieve check-in history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> history = prefs.getStringList(key) ?? [];

    return history
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }
}