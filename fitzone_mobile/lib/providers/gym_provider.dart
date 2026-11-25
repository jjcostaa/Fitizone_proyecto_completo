import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/gym_models.dart';
import '../models/ai_models.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';

class GymProvider extends ChangeNotifier {
  final ApiService api;
  final OfflineCacheService cache;

  GymProvider({required this.api, required this.cache});

  bool _loadingHome = false;
  bool _loadingClasses = false;
  bool _loadingChat = false;
  bool _loadingAi = false;
  bool _usingOfflineData = false;
  DateTime? _lastSync;
  String? _activeChatUserId;

  PagoModel? _ultimoPago;
  List<PagoModel> _pagos = [];
  List<AnuncioModel> _anuncios = [];
  List<ClaseModel> _todasClases = [];
  List<ClaseModel> _misClases = [];
  List<ClaseModel> _clasesEntrenador = [];
  List<UsuarioModel> _todosUsuarios = [];
  List<ChatMessageModel> _chatMessages = [];

  MlMetricsReport? _mlMetrics;
  MlPredictionModel? _individualPrediction;
  List<MlPredictionModel> _batchPredictions = [];
  Map<String, dynamic>? _batchSummary;
  Map<String, dynamic>? _adminStats;
  OptimizationResult? _optimizationResult;
  String? _aiError;

  bool get loadingHome => _loadingHome;
  bool get loadingClasses => _loadingClasses;
  bool get loadingChat => _loadingChat;
  bool get loadingAi => _loadingAi;
  bool get usingOfflineData => _usingOfflineData;
  DateTime? get lastSync => _lastSync;

  PagoModel? get ultimoPago => _ultimoPago;
  List<PagoModel> get pagos => _pagos;
  List<AnuncioModel> get anuncios => _anuncios;
  List<ClaseModel> get todasClases => _todasClases;
  List<ClaseModel> get misClases => _misClases;
  List<ClaseModel> get clasesEntrenador => _clasesEntrenador;
  List<UsuarioModel> get todosUsuarios => _todosUsuarios;
  List<ChatMessageModel> get chatMessages => _chatMessages;

  MlMetricsReport? get mlMetrics => _mlMetrics;
  MlPredictionModel? get individualPrediction => _individualPrediction;
  List<MlPredictionModel> get batchPredictions => _batchPredictions;
  Map<String, dynamic>? get batchSummary => _batchSummary;
  Map<String, dynamic>? get adminStats => _adminStats;
  OptimizationResult? get optimizationResult => _optimizationResult;
  String? get aiError => _aiError;

  bool isSubscribed(String claseId) => _misClases.any((c) => c.id == claseId);

  /// Limpia todo el estado en memoria al cerrar sesión o cambiar de cuenta
  void resetSessionState() {
    _activeChatUserId = null;
    _ultimoPago = null;
    _pagos = [];
    _misClases = [];
    _clasesEntrenador = [];
    _todosUsuarios = [];
    _chatMessages = [];
    _individualPrediction = null;
    _batchPredictions = [];
    _batchSummary = null;
    _adminStats = null;
    _optimizationResult = null;
    _aiError = null;
    _usingOfflineData = false;
    notifyListeners();
  }

  Future<void> initChatForUser(UsuarioModel user) async {
    _activeChatUserId = user.id;
    _chatMessages = await cache.getCachedChatHistory(user.id);
    if (_chatMessages.isEmpty) {
      _chatMessages = [
        ChatMessageModel(
          text:
              'Hola ${user.nombre}, soy FitBot. Pregúntame sobre planes, horarios o clases disponibles en FitZone.',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    }
    notifyListeners();
  }

  Future<void> loadInitialData(UsuarioModel user) async {
    if (_activeChatUserId != null && _activeChatUserId != user.id) {
      resetSessionState();
    }
    _loadingHome = true;
    notifyListeners();

    // 1. Cargar caché local + chat exclusivo de esta cuenta
    _anuncios = await cache.getCachedAnuncios();
    _ultimoPago = await cache.getCachedUltimoPago();
    _pagos = await cache.getCachedPagos();
    _todasClases = await cache.getCachedClases();
    _misClases = await cache.getCachedMisClases();
    _lastSync = await cache.getLastSync();
    await initChatForUser(user);

    final cachedMetrics = await cache.getCachedMlMetrics();
    if (cachedMetrics != null) {
      _mlMetrics = MlMetricsReport.fromJson(cachedMetrics);
    }
    final cachedPred = await cache.getCachedLastMlPrediction();
    if (cachedPred != null) {
      _individualPrediction = MlPredictionModel.fromJson(cachedPred);
    }
    notifyListeners();

    // 2. Intentar sincronizar en vivo desde el backend Spring Boot
    try {
      final results = await Future.wait([
        api.getAnuncios(),
        api.getTodasLasClases(),
        api.getClasesSuscritas(user.id),
        api.getEstadoPago(user.id),
        api.getPagosUsuario(user.id),
      ]);

      _anuncios = results[0] as List<AnuncioModel>;
      _todasClases = results[1] as List<ClaseModel>;
      _misClases = results[2] as List<ClaseModel>;
      _ultimoPago = results[3] as PagoModel?;
      _pagos = results[4] as List<PagoModel>;
      _usingOfflineData = false;

      await cache.saveAnuncios(_anuncios);
      await cache.saveClases(_todasClases);
      await cache.saveMisClases(_misClases);
      await cache.saveUltimoPago(_ultimoPago);
      await cache.savePagos(_pagos);
      _lastSync = await cache.getLastSync();
    } catch (_) {
      _usingOfflineData = true;
    }

    _loadingHome = false;
    notifyListeners();
  }

  Future<void> refreshClasses(String usuarioId) async {
    _loadingClasses = true;
    notifyListeners();
    try {
      _todasClases = await api.getTodasLasClases();
      _misClases = await api.getClasesSuscritas(usuarioId);
      _usingOfflineData = false;
      await cache.saveClases(_todasClases);
      await cache.saveMisClases(_misClases);
      _lastSync = await cache.getLastSync();
    } catch (_) {
      _usingOfflineData = true;
    }
    _loadingClasses = false;
    notifyListeners();
  }

  Future<String?> toggleSuscripcion(String usuarioId, ClaseModel clase) async {
    try {
      if (isSubscribed(clase.id)) {
        await api.desuscribirseDeClase(usuarioId, clase.id);
        _misClases.removeWhere((c) => c.id == clase.id);
      } else {
        await api.suscribirseAClase(usuarioId, clase.id);
        _misClases.add(clase);
      }
      await cache.saveMisClases(_misClases);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> crearClase(String usuarioId, String nombre, String descripcion) async {
    try {
      await api.crearClase(nombre, descripcion);
      await refreshClasses(usuarioId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registrarPagoSimulado({
    required UsuarioModel user,
    required String membresia,
    required double monto,
  }) async {
    try {
      final pago = await api.registrarPago(
        usuarioId: user.id,
        nombre: user.nombreCompleto,
        membresia: membresia,
        monto: monto,
      );
      _ultimoPago = pago;
      _pagos.insert(0, pago);
      await cache.saveUltimoPago(pago);
      await cache.savePagos(_pagos);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registrarImc(String usuarioId, double peso, double alturaCm) async {
    if (peso <= 0 || alturaCm <= 0) return 'Ingresa valores válidos de peso y altura.';
    final alturaM = alturaCm / 100.0;
    final imc = double.parse((peso / (alturaM * alturaM)).toStringAsFixed(2));
    String categoria = 'Normal';
    if (imc < 18.5) {
      categoria = 'Bajo peso';
    } else if (imc < 25) {
      categoria = 'Peso normal';
    } else if (imc < 30) {
      categoria = 'Sobrepeso';
    } else {
      categoria = 'Obesidad';
    }

    final registro = ImcRegistroModel(
      peso: peso,
      altura: alturaCm,
      imc: imc,
      categoria: categoria,
      fecha: DateTime.now(),
    );
    try {
      await api.registrarImc(usuarioId, registro);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> sendChatMessage(String text, {String? userId}) async {
    if (text.trim().isEmpty) return;
    final uid = userId ?? _activeChatUserId ?? '';
    _chatMessages.add(ChatMessageModel(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _loadingChat = true;
    notifyListeners();

    try {
      final reply = await api.sendChatMessage(text.trim());
      _chatMessages.add(ChatMessageModel(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _usingOfflineData = false;
    } catch (_) {
      _usingOfflineData = true;
      _chatMessages.add(ChatMessageModel(
        text:
            'No tienes conexión en este momento. Puedes seguir consultando nuestro historial guardado y volver a intentar cuando recuperes señal.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    if (uid.isNotEmpty) {
      await cache.saveChatHistory(uid, _chatMessages);
    }
    _loadingChat = false;
    notifyListeners();
  }

  Future<void> clearChat(String userId, String nombre) async {
    _activeChatUserId = userId;
    _chatMessages = [
      ChatMessageModel(
        text: 'Hola $nombre, conversación reiniciada. ¿En qué te ayudo hoy en FitZone?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
    if (userId.isNotEmpty) {
      await cache.saveChatHistory(userId, _chatMessages);
    }
    notifyListeners();
  }

  Future<void> loadMlMetrics({bool loadAdminBundle = false}) async {
    _loadingAi = true;
    _aiError = null;
    notifyListeners();

    try {
      final rawMetrics = await api.getMlMetricsRaw();
      _mlMetrics = MlMetricsReport.fromJson(rawMetrics);
      await cache.saveMlMetrics(rawMetrics);

      if (loadAdminBundle) {
        final rawBatch = await api.predictAllRaw();
        final list = rawBatch['predicciones'] as List? ?? [];
        _batchSummary = rawBatch['resumen_riesgo'] as Map<String, dynamic>?;
        _batchPredictions = list
            .map((e) => MlPredictionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _adminStats = await api.getAdminStats();
      }
      _usingOfflineData = false;
    } catch (_) {
      _usingOfflineData = true;
      _aiError = null;
    }

    _loadingAi = false;
    notifyListeners();
  }

  Future<void> loadAdminDashboard() async {
    _loadingHome = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.getAdminStats(),
        api.getTodosUsuarios(limit: 60),
        api.getAnuncios(),
        api.getTodasLasClases(),
      ]);
      _adminStats = results[0] as Map<String, dynamic>;
      _todosUsuarios = results[1] as List<UsuarioModel>;
      _anuncios = results[2] as List<AnuncioModel>;
      _todasClases = results[3] as List<ClaseModel>;
      _usingOfflineData = false;
      await cache.saveAnuncios(_anuncios);
      await cache.saveClases(_todasClases);
      _lastSync = await cache.getLastSync();
    } catch (_) {
      _usingOfflineData = true;
    }
    _loadingHome = false;
    notifyListeners();
  }

  Future<void> loadTrainerDashboard(UsuarioModel trainer) async {
    if (_activeChatUserId != null && _activeChatUserId != trainer.id) {
      resetSessionState();
    }
    _loadingHome = true;
    notifyListeners();
    await initChatForUser(trainer);
    try {
      final results = await Future.wait([
        api.getClasesDeEntrenador(trainer.id),
        api.getTodasLasClases(),
        api.getTodosUsuarios(rol: 'USUARIO', limit: 60),
        api.getAnuncios(),
      ]);
      _clasesEntrenador = results[0] as List<ClaseModel>;
      _todasClases = results[1] as List<ClaseModel>;
      _todosUsuarios = results[2] as List<UsuarioModel>;
      _anuncios = results[3] as List<AnuncioModel>;
      _usingOfflineData = false;
      await cache.saveClases(_todasClases);
      await cache.saveAnuncios(_anuncios);
      _lastSync = await cache.getLastSync();
    } catch (_) {
      _usingOfflineData = true;
    }
    _loadingHome = false;
    notifyListeners();
  }

  Future<String?> eliminarClaseEntrenador(String entrenadorId, String claseId) async {
    try {
      await api.eliminarClase(claseId);
      _clasesEntrenador.removeWhere((c) => c.id == claseId);
      _todasClases.removeWhere((c) => c.id == claseId);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> crearClaseEntrenador(String entrenadorId, String nombre, String descripcion) async {
    try {
      final nueva = await api.crearClase(nombre, descripcion);
      _clasesEntrenador.add(nueva);
      _todasClases.add(nueva);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> crearUsuarioDesdeAdmin(Map<String, dynamic> payload) async {
    try {
      final nuevo = await api.crearUsuarioAdmin(payload);
      _todosUsuarios.insert(0, nuevo);
      _adminStats = await api.getAdminStats();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> crearAnuncioAdmin({
    required String titulo,
    required String descripcion,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    try {
      final nuevo = await api.crearAnuncio(
        titulo: titulo,
        descripcion: descripcion,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
      _anuncios.insert(0, nuevo);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> eliminarAnuncioAdmin(String id) async {
    try {
      await api.eliminarAnuncio(id);
      _anuncios.removeWhere((a) => a.id == id);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> runIndividualPrediction(Map<String, dynamic> profile) async {
    _loadingAi = true;
    _aiError = null;
    notifyListeners();

    try {
      final raw = await api.predictIndividualRaw(profile);
      _individualPrediction = MlPredictionModel.fromJson(raw);
      await cache.saveLastMlPrediction(raw);
      _usingOfflineData = false;
    } catch (_) {
      _aiError = 'No pudimos actualizar tu evaluación en este momento. Intenta nuevamente.';
    }

    _loadingAi = false;
    notifyListeners();
  }

  Future<void> runOptimization() async {
    _loadingAi = true;
    _aiError = null;
    notifyListeners();

    try {
      _optimizationResult = await api.runOptimization();
      _usingOfflineData = false;
    } catch (_) {
      _aiError = 'No pudimos generar el plan en este momento. Intenta nuevamente.';
    }

    _loadingAi = false;
    notifyListeners();
  }
}
