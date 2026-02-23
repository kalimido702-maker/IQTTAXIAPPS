import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Custom Dio interceptor for logging all API requests and responses
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: true,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.i(
      '┌─── REQUEST ───\n'
      '│ ${options.method} ${options.uri}\n'
      '│ Headers: ${options.headers}\n'
      '│ Data: ${options.data}\n'
      '└───────────────',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      '┌─── RESPONSE ───\n'
      '│ ${response.statusCode} ${response.requestOptions.uri}\n'
      '│ Data: ${response.data}\n'
      '└────────────────',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '┌─── ERROR ───\n'
      '│ ${err.response?.statusCode} ${err.requestOptions.uri}\n'
      '│ Message: ${err.message}\n'
      '│ Data: ${err.response?.data}\n'
      '└──────────────',
    );
    handler.next(err);
  }
}
