import 'package:dio/dio.dart';

// TODO: Replace these with the actual imports if these classes are defined elsewhere
class NetworkClient {
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    // Dummy implementation
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {});
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Map<String, dynamic>? headers}) async {
    // Dummy implementation
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: {});
  }
}

class SecureStorage {
  Future<Map<String, dynamic>> getAuthTokens() async {
    // Dummy implementation
    return {'authToken': 'dummy_token'};
  }
}

class PaymentProcessor {
  final NetworkClient _networkClient;
  final SecureStorage _secureStorage;

  PaymentProcessor({
    required NetworkClient networkClient,
    required SecureStorage secureStorage,
  })  : _networkClient = networkClient,
        _secureStorage = secureStorage;

  Future<String> initiateMpesaPayment({
    required String phoneNumber,
    required double amount,
    required String reference,
  }) async {
    final authToken = await _secureStorage.getAuthTokens();
    final response = await _networkClient.post(
      '/payments/mpesa',
      data: {
        'phoneNumber': phoneNumber,
        'amount': amount,
        'reference': reference,
      },
      headers: {
        'Authorization': 'Bearer ${authToken['authToken']}',
      },
    );

    if (response.statusCode == 200) {
      return response.data['checkoutRequestId'];
    } else {
      throw Exception(response.data['message'] ?? 'Payment initiation failed');
    }
  }

  Future<bool> verifyPayment(String checkoutRequestId) async {
    final authToken = await _secureStorage.getAuthTokens();
    final response = await _networkClient.get(
      '/payments/verify',
      queryParameters: {'checkoutRequestId': checkoutRequestId},
      headers: {
        'Authorization': 'Bearer ${authToken['authToken']}',
      },
    );

    if (response.statusCode == 200) {
      return response.data['isPaid'] ?? false;
    } else {
      throw Exception(response.data['message'] ?? 'Payment verification failed');
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final authToken = await _secureStorage.getAuthTokens();
    final response = await _networkClient.get(
      '/payments/history',
      headers: {
        'Authorization': 'Bearer ${authToken['authToken']}',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(response.data['payments']);
    } else {
      throw Exception(response.data['message'] ?? 'Failed to fetch payment history');
    }
  }
}