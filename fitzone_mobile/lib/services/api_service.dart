import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/gym_models.dart';
import '../models/ai_models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  // Timeout amplio para soportar reactivación (cold start) del plan gratuito de Render
  static const Duration _timeout = Duration(seconds: 45);
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<bool> checkServerHealth() async {
    try {
      final res = await http.get(_uri('/api/health')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    final res = await http
        .post(
          _uri('/api/auth/login'),
          headers: _headers,
          body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
        )
        .timeout(_timeout);

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res, 'Correo o contraseña incorrectos'), res.statusCode);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          _uri('/api/auth/register'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res, 'No se pudo completar el registro'), res.statusCode);
  }

  Future<UsuarioModel> getUsuarioById(String usuarioId) async {
    final res = await http.get(_uri('/api/usuarios/$usuarioId'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'No se pudo cargar el perfil'), res.statusCode);
  }

  Future<UsuarioModel> actualizarPerfil(String usuarioId, Map<String, dynamic> updates) async {
    final res = await http
        .put(
          _uri('/api/usuarios/$usuarioId/perfil'),
          headers: _headers,
          body: jsonEncode(updates),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'Error al actualizar el perfil'), res.statusCode);
  }

  Future<List<UsuarioModel>> getTodosUsuarios({String? rol, String? query, int limit = 60}) async {
    final params = <String, String>{'limit': '$limit'};
    if (rol != null && rol.isNotEmpty && rol != 'TODOS') params['rol'] = rol;
    if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
    final uri = _uri('/api/usuarios/resumen').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => UsuarioModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('No se pudo cargar la lista de usuarios', res.statusCode);
  }

  Future<UsuarioModel> crearUsuarioAdmin(Map<String, dynamic> payload) async {
    final res = await http
        .post(
          _uri('/api/usuarios/agregar'),
          headers: _headers,
          body: jsonEncode(payload),
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return UsuarioModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'No se pudo crear el usuario'), res.statusCode);
  }

  // ==================== IMC ====================

  Future<void> registrarImc(String usuarioId, ImcRegistroModel registro) async {
    final res = await http
        .put(
          _uri('/api/usuarios/$usuarioId/imc'),
          headers: _headers,
          body: jsonEncode(registro.toJson()),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException(_extractError(res, 'No se pudo registrar el IMC'), res.statusCode);
    }
  }

  // ==================== CLASES & SUSCRIPCIONES ====================

  Future<List<ClaseModel>> getTodasLasClases() async {
    final res = await http.get(_uri('/api/clases/todas'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => ClaseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('No se pudieron cargar las clases', res.statusCode);
  }

  Future<List<ClaseModel>> getClasesSuscritas(String usuarioId) async {
    final res = await http.get(_uri('/api/suscripciones/usuario/$usuarioId'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => ClaseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('No se pudieron cargar tus clases', res.statusCode);
  }

  Future<void> suscribirseAClase(String usuarioId, String claseId) async {
    final res = await http
        .post(
          _uri('/api/suscripciones'),
          headers: _headers,
          body: jsonEncode({'usuarioId': usuarioId, 'claseId': claseId}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException(_extractError(res, 'No fue posible suscribirse'), res.statusCode);
    }
  }

  Future<void> desuscribirseDeClase(String usuarioId, String claseId) async {
    final res = await http
        .delete(_uri('/api/suscripciones/$usuarioId/$claseId'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException(_extractError(res, 'No fue posible cancelar suscripción'), res.statusCode);
    }
  }

  Future<ClaseModel> crearClase(String nombreClase, String descripcion) async {
    final res = await http
        .post(
          _uri('/api/clases'),
          headers: _headers,
          body: jsonEncode({'nombreClase': nombreClase, 'descripcion': descripcion}),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return ClaseModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'Error al crear la clase'), res.statusCode);
  }

  Future<List<ClaseModel>> getClasesDeEntrenador(String entrenadorId) async {
    final res = await http
        .get(_uri('/api/clases/entrenador/$entrenadorId'), headers: _headers)
        .timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => ClaseModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('No se pudieron cargar tus clases creadas', res.statusCode);
  }

  Future<void> eliminarClase(String claseId) async {
    final res = await http.delete(_uri('/api/clases/$claseId'), headers: _headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('No se pudo eliminar la clase', res.statusCode);
    }
  }

  // ==================== PAGOS & ANUNCIOS ====================

  Future<PagoModel?> getEstadoPago(String usuarioId) async {
    final res = await http.get(_uri('/api/pagos/estado/$usuarioId'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      return PagoModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    if (res.statusCode == 404) return null;
    throw ApiException('No se pudo consultar la membresía', res.statusCode);
  }

  Future<List<PagoModel>> getPagosUsuario(String usuarioId) async {
    final res = await http.get(_uri('/api/pagos/usuario/$usuarioId'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => PagoModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<PagoModel> registrarPago({
    required String usuarioId,
    required String nombre,
    required String membresia,
    required double monto,
  }) async {
    final res = await http
        .post(
          _uri('/api/pagos'),
          headers: _headers,
          body: jsonEncode({
            'usuarioId': usuarioId,
            'nombre': nombre,
            'membresia': membresia,
            'monto': monto,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 200) {
      return PagoModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException('No se pudo registrar el pago', res.statusCode);
  }

  Future<List<AnuncioModel>> getAnuncios() async {
    final res = await http.get(_uri('/api/anuncios/listar'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => AnuncioModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw ApiException('No se pudieron cargar los anuncios', res.statusCode);
  }

  Future<AnuncioModel> crearAnuncio({
    required String titulo,
    required String descripcion,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    final res = await http
        .post(
          _uri('/api/anuncios/crear'),
          headers: _headers,
          body: jsonEncode({
            'titulo': titulo,
            'descripcion': descripcion,
            'fechaInicio': fechaInicio,
            'fechaFin': fechaFin,
          }),
        )
        .timeout(_timeout);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AnuncioModel.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException('No se pudo publicar el anuncio', res.statusCode);
  }

  Future<void> eliminarAnuncio(String id) async {
    final res = await http.delete(_uri('/api/anuncios/eliminar/$id'), headers: _headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw ApiException('No se pudo eliminar el anuncio', res.statusCode);
    }
  }

  // ==================== FITBOT (GROQ LLM) ====================

  Future<String> sendChatMessage(String message) async {
    final res = await http
        .post(
          _uri('/api/chatbot/message'),
          headers: _headers,
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 25));

    if (res.statusCode == 200) {
      final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (map['reply'] ?? 'Sin respuesta del asistente.').toString();
    }
    throw ApiException(_extractError(res, 'FitBot no pudo responder ahora'), res.statusCode);
  }

  // ==================== MINERÍA DE DATOS II (ML) ====================

  Future<Map<String, dynamic>> getMlMetricsRaw() async {
    final res = await http.get(_uri('/api/ml/metrics'), headers: _headers).timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Error obteniendo métricas ML', res.statusCode);
  }

  Future<Map<String, dynamic>> predictIndividualRaw(Map<String, dynamic> profile) async {
    final res = await http
        .post(
          _uri('/api/ml/predict/individual'),
          headers: _headers,
          body: jsonEncode(profile),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Error ejecutando predicción individual', res.statusCode);
  }

  Future<Map<String, dynamic>> predictAllRaw() async {
    final res = await http.get(_uri('/api/ml/predict/all'), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Error ejecutando predicción masiva', res.statusCode);
  }

  // ==================== ADMIN: ESTADÍSTICAS & OPTIMIZACIÓN ====================

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(_uri('/api/admin/estadisticas'), headers: _headers).timeout(_timeout);
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw ApiException('Error cargando estadísticas', res.statusCode);
  }

  Future<OptimizationResult> runOptimization() async {
    final res = await http.get(_uri('/api/admin/optimize'), headers: _headers).timeout(const Duration(seconds: 25));
    if (res.statusCode == 200) {
      return OptimizationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'Error ejecutando optimización'), res.statusCode);
  }

  String _extractError(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      if (decoded is String && decoded.isNotEmpty) return decoded;
    } catch (_) {
      final body = utf8.decode(res.bodyBytes).trim();
      if (body.isNotEmpty && body.length < 180) return body;
    }
    return fallback;
  }
}
