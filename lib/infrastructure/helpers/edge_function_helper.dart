import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/service_locator.dart';
import 'package:squadupv2/infrastructure/services/logger_service.dart';

/// Helper for invoking Supabase Edge Functions with consistent error handling
Future<T> invokeEdgeFunction<T>({
  required String functionName,
  required Map<String, dynamic> body,
  required T Function(Map<String, dynamic>) parser,
}) async {
  final supabase = locator<SupabaseClient>();
  final logger = locator<LoggerService>();

  try {
    logger.debug('Invoking edge function: $functionName');

    final response = await supabase.functions.invoke(
      functionName,
      body: body,
      headers: {
        'Authorization':
            'Bearer ${supabase.auth.currentSession?.accessToken ?? ''}',
      },
    );

    // Check for function errors
    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Unknown error';
      logger.error('Edge function error: $error');
      throw Exception(error);
    }

    // Parse successful response
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }

    return parser(data);
  } catch (e, stack) {
    logger.error('Edge function invocation failed', e, stack);
    rethrow;
  }
}

/// Helper for invoking Edge Functions that return lists
Future<List<T>> invokeEdgeFunctionList<T>({
  required String functionName,
  required Map<String, dynamic> body,
  required T Function(Map<String, dynamic>) itemParser,
}) async {
  return invokeEdgeFunction(
    functionName: functionName,
    body: body,
    parser: (data) {
      final items = data['data'] as List<dynamic>? ?? [];
      return items
          .map((item) => itemParser(item as Map<String, dynamic>))
          .toList();
    },
  );
}
