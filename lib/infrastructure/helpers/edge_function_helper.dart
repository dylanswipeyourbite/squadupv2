import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:squadupv2/core/service_locator.dart';

/// Helper for invoking Supabase Edge Functions with proper auth
Future<T> invokeEdgeFunction<T>({
  required String functionName,
  required Map<String, dynamic> body,
  required T Function(Map<String, dynamic>) parser,
}) async {
  final supabase = locator<SupabaseClient>();

  final response = await supabase.functions.invoke(
    functionName,
    body: body,
    headers: {
      'Authorization':
          'Bearer ${supabase.auth.currentSession?.accessToken ?? ''}',
    },
  );

  if (response.data == null) {
    throw Exception('No response data from edge function');
  }

  // Check for error in response
  final data = response.data as Map<String, dynamic>;
  if (data['error'] != null) {
    throw Exception(data['error']);
  }

  return parser(data);
}

/// Helper for invoking Edge Functions that return lists
Future<List<T>> invokeEdgeFunctionList<T>({
  required String functionName,
  required Map<String, dynamic> body,
  required T Function(Map<String, dynamic>) itemParser,
}) async {
  final supabase = locator<SupabaseClient>();

  final response = await supabase.functions.invoke(
    functionName,
    body: body,
    headers: {
      'Authorization':
          'Bearer ${supabase.auth.currentSession?.accessToken ?? ''}',
    },
  );

  if (response.data == null) {
    throw Exception('No response data from edge function');
  }

  // Check for error in response
  final data = response.data;
  if (data is Map<String, dynamic> && data['error'] != null) {
    throw Exception(data['error']);
  }

  // Handle list response
  if (data is Map<String, dynamic> && data['data'] is List) {
    return (data['data'] as List)
        .map((item) => itemParser(item as Map<String, dynamic>))
        .toList();
  }

  throw Exception('Invalid response format from edge function');
}
