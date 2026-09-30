import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:learning_dashboard/core/failure.dart';


class ApiClient {
  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  ApiClient({
    http.Client? client,
    this.baseUrl = 'https://mock.api.local',
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              ...?headers,
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        throw const ServerFailure('Invalid credentials');
      }
      throw ServerFailure('Server error (${res.statusCode})');
    } on SocketException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl$path'), headers: {...?headers})
          .timeout(timeout);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as List<dynamic>;
      }
      throw ServerFailure('Server error (${res.statusCode})');
    } on SocketException {
      throw const NetworkFailure();
    } on TimeoutException {
      throw const NetworkFailure();
    } on http.ClientException {
      throw const NetworkFailure();
    }
  }
}