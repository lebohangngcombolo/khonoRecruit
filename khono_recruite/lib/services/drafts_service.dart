import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftsService {
  static const String _draftsKey = 'offline_drafts';

  // Draft shape suggestion:
  // {
  //   'id': String (uuid or timestamp),
  //   'saved_at': String ISO time,
  //   'job': { id, title, company, location, ... },
  //   'form': { full_name, phone, portfolio, cover_letter }
  // }

  static Future<List<Map<String, dynamic>>> getDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDraft({
    required Map<String, dynamic> job,
    required Map<String, dynamic> form,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();

    final draft = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'saved_at': DateTime.now().toIso8601String(),
      'job': job,
      'form': form,
    };

    drafts.add(draft);
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  static Future<void> deleteDraft(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await getDrafts();
    drafts.removeWhere((d) => d['id'] == id);
    await prefs.setString(_draftsKey, jsonEncode(drafts));
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftsKey);
  }
}
