import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/supabase_config.dart';
import '../models/biopsy_result.dart';
import '../models/clinical_record.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final String _baseUrl = '${SupabaseConfig.url}/rest/v1';
  final String _apiKey = SupabaseConfig.anonKey;

  Map<String, String> get _headers => {
        'apikey': _apiKey,
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

  /// Check connectivity to Supabase
  Future<bool> isConnected() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/users?select=id&limit=1'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 1. Users Synchronization ─────────────────────────

  Future<void> syncUser(UserProfile user) async {
    try {
      final url = Uri.parse('$_baseUrl/users');
      final payload = {
        'username': user.name,
        'email': user.email,
        'is_admin': user.isAdmin ? 1 : 0,
        'age': user.age,
        'gender': user.gender,
        'medical_notes': user.medicalNotes,
      };

      // Upsert by checking existing
      final checkUrl = Uri.parse('$_baseUrl/users?email=eq.${user.email}');
      final checkRes = await http.get(checkUrl, headers: _headers);

      if (checkRes.statusCode == 200) {
        final data = json.decode(checkRes.body) as List;
        if (data.isNotEmpty) {
          await http.patch(
            checkUrl,
            headers: _headers,
            body: json.encode(payload),
          );
        } else {
          await http.post(
            url,
            headers: _headers,
            body: json.encode(payload),
          );
        }
      }
    } catch (_) {}
  }

  Future<List<UserProfile>> fetchRemoteUsers() async {
    try {
      final url = Uri.parse('$_baseUrl/users?select=*&order=created_at.desc');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((jsonItem) => UserProfile.fromJson(jsonItem)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── 2. Biopsy Reports Synchronization ────────────────

  Future<void> syncBiopsyResult(BiopsyResult result, {String? userId}) async {
    try {
      final url = Uri.parse('$_baseUrl/biopsy_reports');
      final payload = {
        'filename': result.imageName,
        'image_path': result.imagePath,
        'predictions_json': json.encode(result.metrics.map((k, v) => MapEntry(k, v.toJson()))),
        'raw_probs_json': json.encode(result.metrics.map((k, v) => MapEntry(k, v.probability))),
        'mode': 'offline_onnx',
        'created_at': result.timestamp.toIso8601String(),
      };

      await http.post(
        url,
        headers: _headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<List<BiopsyResult>> fetchRemoteBiopsies() async {
    try {
      final url = Uri.parse('$_baseUrl/biopsy_reports?select=*&order=created_at.desc&limit=50');
      final res = await http.get(url, headers: _headers).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as List;
        return data.map((item) {
          final id = item['id']?.toString() ?? 'bp_${DateTime.now().millisecondsSinceEpoch}';
          final filename = item['filename'] ?? 'Biopsy Scan';
          final imagePath = item['image_path'];
          final rawJson = item['predictions_json'];
          Map<String, dynamic> metricsMap = {};
          if (rawJson is String) {
            try {
              metricsMap = json.decode(rawJson);
            } catch (_) {}
          } else if (rawJson is Map<String, dynamic>) {
            metricsMap = rawJson;
          }

          final metrics = <String, BiopsyMetric>{};
          metricsMap.forEach((k, v) {
            if (v is Map<String, dynamic>) {
              metrics[k] = BiopsyMetric.fromJson(v);
            }
          });

          return BiopsyResult(
            id: id,
            imageName: filename,
            imagePath: imagePath,
            timestamp: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
            metrics: metrics,
            overallSeverity: item['overall_severity'] ?? 'Moderate',
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── 3. Clinical Records Synchronization ──────────────

  Future<void> syncClinicalRecord(ClinicalRecord record) async {
    try {
      final url = Uri.parse('$_baseUrl/clinical_records');
      final payload = {
        'age': record.age,
        'gender': record.gender,
        'total_bilirubin': record.totalBilirubin,
        'direct_bilirubin': record.directBilirubin,
        'alkphos': record.alkalinePhosphotase,
        'sgpt': record.sgpt,
        'sgot': record.sgot,
        'total_proteins': record.totalProteins,
        'albumin': record.albumin,
        'ag_ratio': record.agRatio,
        'risk_level': record.riskLevel,
        'created_at': record.timestamp.toIso8601String(),
      };

      await http.post(
        url,
        headers: _headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // ── 4. Chat History Synchronization ──────────────────

  Future<void> syncChatMessage(ChatMessage message, {String? userId}) async {
    try {
      final url = Uri.parse('$_baseUrl/chat_history');
      final payload = {
        'session_id': 'flutter_mobile_session',
        'role': message.isUser ? 'user' : 'assistant',
        'message': message.text,
        'created_at': message.timestamp.toIso8601String(),
      };

      await http.post(
        url,
        headers: _headers,
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
