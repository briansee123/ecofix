import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosisService {
  static const String key = "diagnosis_history";

  // Save diagnosis results from Module A
  static Future<void> saveDiagnosis(String itemName, String issue) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];
    
    final newEntry = jsonEncode({
      "name": itemName,
      "issue": issue,
      "timestamp": DateTime.now().toIso8601String(),
    });

    history.insert(0, newEntry); // Put latest at the front
    if (history.length > 5) history = history.sublist(0, 5); // Keep only last 5 entries
    await prefs.setStringList(key, history);
  }

  // For Module C to read
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];
    return history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }
}