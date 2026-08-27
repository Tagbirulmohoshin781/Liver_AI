import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/biopsy_result.dart';
import '../models/clinical_record.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyProfile = 'liver_profile';
  static const String _keyBiopsyHistory = 'liver_biopsy_history';
  static const String _keyClinicalHistory = 'liver_clinical_history';
  static const String _keyChatHistory = 'liver_chat_history';

  final SupabaseService _supabase = SupabaseService();
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  // ── Profile ──────────────────────────────────────────
  Future<UserProfile> loadProfile() async {
    await initialize();
    final jsonStr = _prefs!.getString(_keyProfile);
    if (jsonStr != null) {
      try {
        return UserProfile.fromJson(json.decode(jsonStr));
      } catch (e) {
        // Return default on error
      }
    }
    return UserProfile.defaultProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await initialize();
    await _prefs!.setString(_keyProfile, json.encode(profile.toJson()));
    // Sync to Supabase PostgreSQL in background
    _supabase.syncUser(profile);
  }

  // ── Biopsy Scan History ──────────────────────────────
  Future<List<BiopsyResult>> loadBiopsyHistory() async {
    await initialize();
    final jsonList = _prefs!.getStringList(_keyBiopsyHistory);
    final localList = <BiopsyResult>[];

    if (jsonList != null) {
      for (final item in jsonList) {
        try {
          localList.add(BiopsyResult.fromJson(json.decode(item)));
        } catch (_) {}
      }
    }

    // Try merging remote Supabase biopsies in background if available
    Future.microtask(() async {
      try {
        final remote = await _supabase.fetchRemoteBiopsies();
        if (remote.isNotEmpty) {
          final existingIds = localList.map((e) => e.id).toSet();
          bool updated = false;
          for (final r in remote) {
            if (!existingIds.contains(r.id)) {
              localList.add(r);
              updated = true;
            }
          }
          if (updated) {
            final jsonList = localList.map((r) => json.encode(r.toJson())).toList();
            await _prefs!.setStringList(_keyBiopsyHistory, jsonList);
          }
        }
      } catch (_) {}
    });

    return localList;
  }

  Future<void> saveBiopsyResult(BiopsyResult result) async {
    await initialize();
    final current = await loadBiopsyHistory();
    current.insert(0, result);
    final jsonList = current.map((r) => json.encode(r.toJson())).toList();
    await _prefs!.setStringList(_keyBiopsyHistory, jsonList);

    // Sync to Supabase PostgreSQL database
    _supabase.syncBiopsyResult(result);
  }

  Future<void> deleteBiopsyResult(String id) async {
    await initialize();
    final current = await loadBiopsyHistory();
    current.removeWhere((r) => r.id == id);
    final jsonList = current.map((r) => json.encode(r.toJson())).toList();
    await _prefs!.setStringList(_keyBiopsyHistory, jsonList);
  }

  // ── Clinical Records History ──────────────────────────
  Future<List<ClinicalRecord>> loadClinicalHistory() async {
    await initialize();
    final jsonList = _prefs!.getStringList(_keyClinicalHistory);
    final list = <ClinicalRecord>[];
    if (jsonList != null) {
      for (final item in jsonList) {
        try {
          list.add(ClinicalRecord.fromJson(json.decode(item)));
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveClinicalRecord(ClinicalRecord record) async {
    await initialize();
    final current = await loadClinicalHistory();
    current.insert(0, record);
    final jsonList = current.map((r) => json.encode(r.toJson())).toList();
    await _prefs!.setStringList(_keyClinicalHistory, jsonList);

    // Sync to Supabase PostgreSQL database
    _supabase.syncClinicalRecord(record);
  }

  Future<void> deleteClinicalRecord(String id) async {
    await initialize();
    final current = await loadClinicalHistory();
    current.removeWhere((r) => r.id == id);
    final jsonList = current.map((r) => json.encode(r.toJson())).toList();
    await _prefs!.setStringList(_keyClinicalHistory, jsonList);
  }

  // ── Chat History ──────────────────────────────────────
  Future<List<ChatMessage>> loadChatHistory() async {
    await initialize();
    final jsonList = _prefs!.getStringList(_keyChatHistory);
    final list = <ChatMessage>[];
    if (jsonList != null) {
      for (final item in jsonList) {
        try {
          list.add(ChatMessage.fromJson(json.decode(item)));
        } catch (_) {}
      }
    }
    return list;
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    await initialize();
    final jsonList = messages.map((m) => json.encode(m.toJson())).toList();
    await _prefs!.setStringList(_keyChatHistory, jsonList);

    // Sync latest message to Supabase
    if (messages.isNotEmpty) {
      _supabase.syncChatMessage(messages.last);
    }
  }

  // ── Wipe All ──────────────────────────────────────────
  Future<void> clearAllData() async {
    await initialize();
    await _prefs!.remove(_keyBiopsyHistory);
    await _prefs!.remove(_keyClinicalHistory);
    await _prefs!.remove(_keyChatHistory);
  }
}
