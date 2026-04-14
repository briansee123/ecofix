import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Add this
import 'package:firebase_auth/firebase_auth.dart';

class DiagnosisService {
  static const String key = "diagnosis_history";

  static Future<void> saveDiagnosis(String itemName, String issue) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];
    
    final data = {
      "name": itemName,
      "issue": issue,
      "timestamp": DateTime.now().toIso8601String(),
      "userId": FirebaseAuth.instance.currentUser?.uid ?? "guest",
    };

    // --- NEW: SEND TO FIRESTORE ---
    try {
      await FirebaseFirestore.instance.collection('repairs').add(data);
    } catch (e) {
      print("Firestore Error: $e");
    }
    // ------------------------------

    final newEntry = jsonEncode(data);
    history.insert(0, newEntry);
    if (history.length > 5) history = history.sublist(0, 5);
    await prefs.setStringList(key, history);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];
    return history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }
}