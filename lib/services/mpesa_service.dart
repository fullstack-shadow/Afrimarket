import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:afrimarket/core/config.dart';
// Ensure that the Config class is defined and exported from config.dart

class MpesaService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://sandbox.safaricom.co.ke';
  final String consumerKey = Config.mpesaConsumerKey;
  final String consumerSecret = Config.mpesaConsumerSecret;
  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<void> _authenticate() async {
    if (_accessToken != null && 
        _tokenExpiry != null && 
        _tokenExpiry!.isAfter(DateTime.now())) {
      return;
    }

    final credentials = base64.encode(
      utf8.encode('$consumerKey:$consumerSecret')
    );

    final response = await _dio.get(
      '$_baseUrl/oauth/v1/generate?grant_type=client_credentials',
      options: Options(headers: {
        'Authorization': 'Basic $credentials',
      }),
    );

    _accessToken = response.data['access_token'];
    _tokenExpiry = DateTime.now().add(
      Duration(seconds: response.data['expires_in']),
    );
  }

  Future<String> initiatePayment({
    required String phone,
    required double amount,
    required String accountRef,
  }) async {
    await _authenticate();

    final timestamp = DateTime.now().toUtc().format('yyyyMMddHHmmss');
    final password = _generatePassword(timestamp);

    final response = await _dio.post(
      '$_baseUrl/mpesa/stkpush/v1/processrequest',
      data: {
        'BusinessShortCode': Config.businessShortCode,
        'Password': password,
        'Timestamp': timestamp,
        'TransactionType': 'CustomerPayBillOnline',
        'Amount': amount.toStringAsFixed(0),
        'PartyA': phone,
        'PartyB': Config.businessShortCode,
        'PhoneNumber': phone,
        'CallBackURL': '${Config.baseUrl}/mpesa-callback',
        'AccountReference': accountRef,
        'TransactionDesc': 'AfriMarket Payment',
      },
      options: Options(headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      }),
    );

    return response.data['ResponseDescription'];
  }

  String _generatePassword(String timestamp) {
    final stringToEncode = 
      '${Config.businessShortCode}${Config.mpesaPassKey}$timestamp';
    final bytes = utf8.encode(stringToEncode);
    return base64.encode(bytes);
  }
}

extension on DateTime {
  String format(String format) {
    return format
        .replaceAll('yyyy', year.toString())
        .replaceAll('MM', month.toString().padLeft(2, '0'))
        .replaceAll('dd', day.toString().padLeft(2, '0'))
        .replaceAll('HH', hour.toString().padLeft(2, '0'))
        .replaceAll('mm', minute.toString().padLeft(2, '0'))
        .replaceAll('ss', second.toString().padLeft(2, '0'));
  }
}