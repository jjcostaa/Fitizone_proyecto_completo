import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/gym_models.dart';

class OfflineCacheService {
  static const _kToken = 'cache_jwt_token';
  static const _kUser = 'cache_user_profile';
  static const _kClases = 'cache_all_clases';
  static const _kMisClases = 'cache_my_clases';
  static const _kAnuncios = 'cache_anuncios';
  static const _kUltimoPago = 'cache_ultimo_pago';
  static const _kPagos = 'cache_pagos_list';
  static const _kChat = 'cache_fitbot_chat';
  static const _kMlMetrics = 'cache_ml_metrics';
  static const _kMlLastPred = 'cache_ml_last_prediction';
  static const _kLastSync = 'cache_last_sync_iso';

  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  Future<bool> hasNetwork() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  // --- Sesión y Token ---
  Future<void> saveSession(String token, UsuarioModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    await _touchSync(prefs);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  Future<UsuarioModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UsuarioModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UsuarioModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    await _touchSync(prefs);
  }

  // --- Clases ---
  Future<void> saveClases(List<ClaseModel> clases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kClases, jsonEncode(clases.map((c) => c.toJson()).toList()));
    await _touchSync(prefs);
  }

  Future<List<ClaseModel>> getCachedClases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kClases);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ClaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMisClases(List<ClaseModel> clases) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMisClases, jsonEncode(clases.map((c) => c.toJson()).toList()));
    await _touchSync(prefs);
  }

  Future<List<ClaseModel>> getCachedMisClases() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMisClases);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ClaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Anuncios ---
  Future<void> saveAnuncios(List<AnuncioModel> anuncios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAnuncios, jsonEncode(anuncios.map((a) => a.toJson()).toList()));
    await _touchSync(prefs);
  }

  Future<List<AnuncioModel>> getCachedAnuncios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAnuncios);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => AnuncioModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Pagos / Membresía ---
  Future<void> saveUltimoPago(PagoModel? pago) async {
    final prefs = await SharedPreferences.getInstance();
    if (pago == null) {
      await prefs.remove(_kUltimoPago);
    } else {
      await prefs.setString(_kUltimoPago, jsonEncode(pago.toJson()));
    }
    await _touchSync(prefs);
  }

  Future<PagoModel?> getCachedUltimoPago() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUltimoPago);
    if (raw == null) return null;
    try {
      return PagoModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePagos(List<PagoModel> pagos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPagos, jsonEncode(pagos.map((p) => p.toJson()).toList()));
  }

  Future<List<PagoModel>> getCachedPagos() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPagos);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => PagoModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- FitBot Chat Offline (aislado por cuenta de usuario) ---
  String _chatKeyFor(String userId) => '${_kChat}_$userId';

  Future<void> saveChatHistory(String userId, List<ChatMessageModel> messages) async {
    if (userId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final recent = messages.length > 50 ? messages.sublist(messages.length - 50) : messages;
    await prefs.setString(_chatKeyFor(userId), jsonEncode(recent.map((m) => m.toJson()).toList()));
  }

  Future<List<ChatMessageModel>> getCachedChatHistory(String userId) async {
    if (userId.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatKeyFor(userId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --- Resultados IA / ML ---
  Future<void> saveRawJson(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
    await _touchSync(prefs);
  }

  Future<Map<String, dynamic>?> getRawJson(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMlMetrics(Map<String, dynamic> data) => saveRawJson(_kMlMetrics, data);
  Future<Map<String, dynamic>?> getCachedMlMetrics() => getRawJson(_kMlMetrics);

  Future<void> saveLastMlPrediction(Map<String, dynamic> data) => saveRawJson(_kMlLastPred, data);
  Future<Map<String, dynamic>?> getCachedLastMlPrediction() => getRawJson(_kMlLastPred);

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kLastSync);
    return iso != null ? DateTime.tryParse(iso) : null;
  }

  Future<void> _touchSync(SharedPreferences prefs) async {
    await prefs.setString(_kLastSync, DateTime.now().toIso8601String());
  }

  Future<void> clearAllDataCacheOnly() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kClases, _kMisClases, _kAnuncios, _kUltimoPago, _kPagos, _kChat, _kMlMetrics, _kMlLastPred]) {
      await prefs.remove(k);
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    await clearAllDataCacheOnly();
  }
}
