import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'crypto_helper.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ApiService get api => _api;

  static String encryptPassword(String password) {
    return CryptoHelper.sha256Hash(password);
  }

  Future<bool> register({
    required String username,
    required String email,
    required String fullName,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _api.register(
        username: username,
        email: email,
        fullName: fullName,
        password: password,
      );
      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await _api.login(
        username: username,
        password: password,
      );
      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> addBalance(double amount) async {
    if (_currentUser == null || amount <= 0) return false;
    _setLoading(true);
    try {
      final newBalance = await _api.addBalance(_currentUser!.id, amount);
      _currentUser = _currentUser!.copyWith(balance: newBalance);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? newPassword,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);
    try {
      final updated = await _api.updateProfile(
        traderId: _currentUser!.id,
        fullName: fullName,
        email: email,
        password: newPassword,
      );
      _currentUser = updated;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_currentUser == null) return;
    try {
      final updated = await _api.getProfile(_currentUser!.id);
      _currentUser = updated;
      notifyListeners();
    } catch (_) {}
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
