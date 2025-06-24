import 'package:afrimarket/core/services/api_service.dart';
import 'package:afrimarket/core/services/auth_service.dart';
import 'package:afrimarket/core/services/chat_service.dart';
import 'package:afrimarket/core/services/payment_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Services
  getIt.registerSingleton<AuthService>(AuthService());
  getIt.registerSingleton<ApiService>(ApiService());
  getIt.registerSingleton<ChatService>(ChatService());
  getIt.registerSingleton<PaymentService>(PaymentService());

  // Controllers (via Riverpod)
  // These will be registered in individual provider files
}
