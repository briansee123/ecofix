import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. Add this
import 'package:firebase_auth/firebase_auth.dart';

class CheckInService {
  static const String key = "checkin_history";

  static Future<void> addCheckIn(String location) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];

    String formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final data = {
      "location": location,
      "time": formattedTime,
      "userId": FirebaseAuth.instance.currentUser?.uid ?? "guest",
    };

    // --- NEW: SEND TO FIRESTORE ---
    try {
      await FirebaseFirestore.instance.collection('checkins').add(data);
    } catch (e) {
      print("Firestore Error: $e");
    }
    // ------------------------------

    history.add(jsonEncode(data));
    await prefs.setStringList(key, history);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(key) ?? [];
    return history.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }
}