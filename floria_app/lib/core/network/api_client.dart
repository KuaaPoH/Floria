import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Dio get dio => _dio;
}
