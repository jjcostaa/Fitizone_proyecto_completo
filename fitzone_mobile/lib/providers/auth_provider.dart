import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/offline_cache_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  final OfflineCacheService cache;

  AuthProvider({required this.api, required this.cache});

  UsuarioModel? _user;
  String? _token;
  UsuarioModel? _pendingUser;
  String? _pendingToken;
  bool _isInitializing = true;
  bool _isLoading = false;
  bool _isOnline = true;
  bool _serverReachable = true;
  String? _error;
  StreamSubscription<bool>? _connSub;

  UsuarioModel? get user => _user;
  UsuarioModel? get pendingUser => _pendingUser;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline && _serverReachable;
  bool get hasDeviceNetwork => _isOnline;
  String? get error => _error;

  Future<void> init() async {
    _isInitializing = true;
    notifyListeners();

    final savedToken = await cache.getToken();
    final cachedUser = await cache.getCachedUser();

    if (savedToken != null && cachedUser != null) {
      _token = savedToken;
      _user = cachedUser;
      api.setToken(savedToken);
    }

    // Mostrar la interfaz al instante sin bloquear esperando red
    _isInitializing = false;
    notifyListeners();

    // Verificar red y refrescar perfil en segundo plano
    _isOnline = await cache.hasNetwork();
    _connSub?.cancel();
    _connSub = cache.onConnectivityChanged.listen((online) async {
      _isOnline = online;
      _serverReachable = online ? await api.checkServerHealth() : false;
      notifyListeners();
    });

    if (_isOnline && _user != null && !_user!.isAdmin) {
      unawaited(refreshProfile());
    }
  }

  Future<bool> login(String correo, String contrasena, {bool deferNavigation = false}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await api.login(correo, contrasena);
      final jwt = (res['token'] ?? '').toString();
      api.setToken(jwt);

      final loggedUser = UsuarioModel.fromJson(res);
      _serverReachable = true;
      await cache.saveSession(jwt, loggedUser);

      if (deferNavigation) {
        _pendingToken = jwt;
        _pendingUser = loggedUser;
      } else {
        _token = jwt;
        _user = loggedUser;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> payload, {bool deferNavigation = false}) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await api.register(payload);
      final jwt = (res['token'] ?? '').toString();
      api.setToken(jwt);

      final registeredUser = UsuarioModel.fromJson(res);
      _serverReachable = true;
      await cache.saveSession(jwt, registeredUser);

      if (deferNavigation) {
        _pendingToken = jwt;
        _pendingUser = registeredUser;
      } else {
        _token = jwt;
        _user = registeredUser;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void commitPendingSession() {
    if (_pendingUser != null && _pendingToken != null) {
      _user = _pendingUser;
      _token = _pendingToken;
      _pendingUser = null;
      _pendingToken = null;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (_user == null || _user!.isAdmin) return;
    try {
      final fresh = await api.getUsuarioById(_user!.id);
      _user = fresh;
      _serverReachable = true;
      await cache.saveUser(fresh);
      notifyListeners();
    } catch (_) {
      _serverReachable = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return false;
    try {
      final updated = await api.actualizarPerfil(_user!.id, updates);
      _user = updated;
      await cache.saveUser(updated);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> checkConnectionNow() async {
    _isOnline = await cache.hasNetwork();
    _serverReachable = _isOnline ? await api.checkServerHealth() : false;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    api.setToken(null);
    await cache.clearSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }
}
