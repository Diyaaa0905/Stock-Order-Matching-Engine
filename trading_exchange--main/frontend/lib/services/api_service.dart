import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/stock_model.dart';
import '../models/order_model.dart';
import '../models/position_model.dart';
import '../models/order_book_model.dart';
import '../models/chart_point_model.dart';

class ApiService {
  // Use localhost for Web/Desktop/iOS, 10.0.2.2 for Android emulator
  static String defaultBaseUrl = kIsWeb
      ? 'http://localhost:8080'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080');

  String baseUrl;

  ApiService({String? url}) : baseUrl = url ?? defaultBaseUrl;

  Future<UserModel> register({
    required String username,
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'fullName': fullName,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      throw Exception(data['message'] ?? 'Registration failed.');
    }
  }

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      throw Exception(data['message'] ?? 'Invalid username or password.');
    }
  }

  Future<UserModel> getProfile(String traderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/profile?traderId=$traderId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } else {
      throw Exception('Could not fetch user profile.');
    }
  }

  Future<UserModel> updateProfile({
    required String traderId,
    String? fullName,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{'traderId': traderId};
    if (fullName != null && fullName.isNotEmpty) body['fullName'] = fullName;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile.');
    }
  }

  Future<List<StockModel>> getStocks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/stocks'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => StockModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load stocks.');
    }
  }

  Future<OrderBookModel> getOrderBook(String ticker) async {
    final response = await http.get(Uri.parse('$baseUrl/api/stocks/$ticker/book'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return OrderBookModel.fromJson(data);
    } else {
      throw Exception('Failed to load order book for $ticker.');
    }
  }

  Future<List<ChartPointModel>> getChartData(String ticker, String timeframe) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/stocks/$ticker/chart?timeframe=$timeframe'),
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load chart data for $ticker.');
    }
  }

  Future<List<OrderModel>> getOrders(String traderId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/orders?traderId=$traderId'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load orders.');
    }
  }

  Future<Map<String, dynamic>> placeOrder({
    required String traderId,
    required String ticker,
    required String side,
    required String type,
    required double price,
    required int quantity,
    double? stopThreshold,
  }) async {
    final body = <String, dynamic>{
      'traderId': traderId,
      'ticker': ticker,
      'side': side,
      'type': type,
      'price': price,
      'quantity': quantity,
    };
    if (stopThreshold != null) {
      body['stopThreshold'] = stopThreshold;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to place order.');
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/orders/$orderId'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return response.statusCode == 200 && data['success'] == true;
  }

  Future<List<PositionModel>> getPortfolio(String traderId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/portfolio?traderId=$traderId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final positionsList = (data['positions'] as List<dynamic>? ?? []);
      return positionsList.map((e) => PositionModel.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load portfolio.');
    }
  }

  Future<double> getBalance(String traderId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/account?traderId=$traderId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['balance'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception('Failed to fetch account balance.');
    }
  }

  Future<double> addBalance(String traderId, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'traderId': traderId,
        'amount': amount,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['balance'] as num?)?.toDouble() ?? 0.0;
    } else {
      throw Exception(data['message'] ?? 'Failed to add balance.');
    }
  }

  // ── Admin API ────────────────────────────────────────────────────────────────

  Future<bool> adminLogin(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/dashboard'),
      headers: {'X-Admin-Key': 'ADMIN'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load dashboard');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAdminUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users'),
      headers: {'X-Admin-Key': 'ADMIN'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load users');
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<List<dynamic>> getAdminOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/orders'),
      headers: {'X-Admin-Key': 'ADMIN'},
    );
    if (response.statusCode != 200) throw Exception('Failed to load orders');
    return jsonDecode(response.body) as List<dynamic>;
  }
}

