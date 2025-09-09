# SquadUp Edge Functions Security Migration Guide

## Overview

This document outlines our decision to migrate security logic from Supabase Row Level Security (RLS) to Edge functions. This approach addresses debugging challenges with RLS while maintaining a clean separation of concerns. It aligns with the SquadUp Development Directive (see `docs/squadup_directive.md`) by isolating changes to the infrastructure layer, ensuring the presentation, application, and domain layers remain unchanged.

The goal is to enable easier debugging and control without impacting the frontend. All data access will be routed through Edge functions, which perform validation and DB operations securely.

## Benefits

- **Easier Debugging:** Edge functions allow local testing with logs and unit tests, avoiding opaque RLS errors.
- **Control and Flexibility:** Procedural code in Deno/TS for custom logic, while keeping RLS as an optional safety net.
- **Minimal Impact:** Only infrastructure/repositories change; aligns with directive's clean architecture and repository pattern.
- **Sustainability:** Builds on existing Supabase Edge functions (e.g., for squad creation and AI), scalable for future needs.
- **Quick Launch:** Allows disabling RLS temporarily for stability, with functions providing security.

## Implementation Approach

### Flutter Side (Infrastructure Layer Only)
- Use repositories to proxy calls to Edge functions via `supabase.functions.invoke()`.
- Add a helper for common invoke logic to handle auth tokens and parsing.
- Example helper:
  ```dart
  // lib/infrastructure/helpers/edge_function_helper.dart
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:squadupv2/core/service_locator.dart';

  Future<T> invokeEdgeFunction<T>(
    String functionName,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final supabase = locator<SupabaseClient>();
    
    final response = await supabase.functions.invoke(
      functionName,
      body: body,
      headers: {
        'Authorization': 'Bearer ${supabase.auth.currentSession?.accessToken ?? ''}',
      },
    );
    
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    
    return parser(response.data as Map<String, dynamic>);
  }
  ```

- Update repository impls, e.g., for messages:
  ```dart
  // lib/infrastructure/repositories/message_repository_impl.dart
  // Use invokeEdgeFunction for fetch/send methods, mapping to domain models.
  ```

### Supabase Side
- Create functions in `supabase/functions/` that validate auth, check permissions (e.g., squad membership), and perform DB ops with service-role keys.
- Example: `fetch-messages` function in Deno/TS.

## Migration Steps

1. **Disable RLS Temporarily:** Run relevant migration to disable RLS on key tables for testing/launch.
2. **Create Helper and Update Repos:** Add edge_function_helper.dart and update 2-3 key repositories (e.g., squads, messages, activities).
3. **Develop Edge Functions:** Implement and deploy functions for each repo method.
4. **Test:** Local function serving, unit tests for repos, e2e flows from SRS.
5. **Deploy and Monitor:** Gradually re-enable minimal RLS as a backup.

## Alignment with Directive

This follows the SquadUp Development Directive (`docs/squadup_directive.md`):
- **Clean Layering:** Changes isolated to infrastructure; domain services remain pure.
- **No Direct Calls:** UI/presentation never touches Supabase directly—repos handle it.
- **Security:** Moves RLS-like checks to functions, maintaining least-privilege.
- **Long-Term Focus:** Avoids quick fixes; builds a debuggable, scalable backend layer.
