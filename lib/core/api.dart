import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/branded_loading.dart';

class ApiException implements Exception {
  final String message;
  final int status;
  final String? code;
  final String? paymentUrl;
  ApiException(this.message, this.status, {this.code, this.paymentUrl});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.baseUrl);

  String baseUrl;
  final storage = const FlutterSecureStorage();
  String? token;
  Future<void> Function(ApiException error)? onPaymentRequired;

  String get apiRoot {
    var root = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (root.endsWith('/api/v1')) return root;
    if (root.endsWith('/api')) return '$root/v1';
    return '$root/api/v1';
  }

  Uri _uri(String route, [Map<String, dynamic>? query]) {
    final cleanRoute = route.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$apiRoot/$cleanRoute').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<void> loadToken() async {
    try {
      token = await storage.read(key: 'api_token');
    } catch (_) {
      // Bazı Android cihazlarında eski/geri yüklenmiş şifreli preference
      // anahtarı okunamazsa açılışın çökmesini engelle.
      token = null;
    }
  }

  Future<void> saveToken(String? value) async {
    token = value;
    if (value == null) {
      await storage.delete(key: 'api_token');
    } else {
      await storage.write(key: 'api_token', value: value);
    }
  }

  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    MleyLoadingController.instance.begin(
      method == 'GET' ? 'Veriler yükleniyor...' : 'İşleminiz gerçekleştiriliyor...',
    );

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final uri = _uri(route, query);
      final body = data == null ? null : jsonEncode(data);
      http.Response response;

      switch (method) {
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body);
          break;
        default:
          response = await http.get(uri, headers: headers);
      }

      Map<String, dynamic> json = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          json = decoded;
        } else {
          throw const FormatException();
        }
      } catch (_) {
        throw ApiException(
          'Sunucudan geçersiz yanıt alındı. HTTP ${response.statusCode}',
          response.statusCode,
        );
      }

      if (response.statusCode == 401) {
        await saveToken(null);
        throw ApiException(
          json['message']?.toString() ?? 'Oturum süresi doldu.',
          401,
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          json['ok'] != true) {
        final message = json['message']?.toString() ?? 'İşlem tamamlanamadı.';
        final debugRoute = json['data'] is Map
            ? (json['data']['route']?.toString() ?? '')
            : '';
        final error = ApiException(
          debugRoute.isNotEmpty ? '$message ($debugRoute)' : message,
          response.statusCode,
          code: json['code']?.toString(),
          paymentUrl: json['payment_url']?.toString(),
        );
        if (response.statusCode == 402 &&
            (error.code == 'PAYMENT_REQUIRED_EMPLOYEE' ||
             error.code == 'PAYMENT_REQUIRED_MANAGER' ||
             error.code == 'PAYMENT_REQUIRED')) {
          await onPaymentRequired?.call(error);
        }
        throw error;
      }

      return json;
    } finally {
      MleyLoadingController.instance.end();
    }
  }
}
