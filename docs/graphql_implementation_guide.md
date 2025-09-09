# SquadUp GraphQL Implementation Guide

**Note:** This GraphQL guide is deferred in favor of migrating security to Supabase Edge functions for better debugging and control. See `docs/edge_functions_security_migration.md` for the current approach. GraphQL may be revisited post-launch for type safety benefits.

## Why GraphQL Makes Sense for SquadUp

### Benefits for Your Development Style
1. **Self-Documenting Schema** - See all types, fields, and relationships in one place
2. **GraphQL Playground** - Explore and test queries interactively
3. **Type Generation** - Auto-generate Flutter models from GraphQL schema
4. **Field-Level RLS** - See exactly what permissions each field requires
5. **Relationship Navigation** - Discover connections between data naturally

## 1. Enable GraphQL in Supabase

### Step 1: Enable pg_graphql Extension

```sql
-- Enable GraphQL extension
CREATE EXTENSION IF NOT EXISTS pg_graphql;

-- Create GraphQL schema (if not exists)
CREATE SCHEMA IF NOT EXISTS graphql_public;

-- Grant usage to authenticated users
GRANT USAGE ON SCHEMA graphql_public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA graphql_public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA graphql_public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA graphql_public TO authenticated;
```

### Step 2: Configure Supabase for GraphQL

Update your `supabase/config.toml`:
```toml
[api]
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
```

## 2. Create GraphQL-Optimized Views

Instead of exposing raw tables, create views that handle the RLS complexity:

```sql
-- Create a GraphQL-friendly view for messages with user info 
CREATE OR REPLACE VIEW graphql_public.squad_messages AS
SELECT 
  m.id,
  m.squad_id,
  m.user_id,
  m.content,
  m.type,
  m.media_url,
  m.metadata,
  m.created_at,
  m.updated_at,
  -- Embed user info
  u.display_name as user_display_name,
  u.avatar_url as user_avatar_url,
  -- Include squad context
  s.name as squad_name
FROM public.messages m
JOIN public.profiles u ON u.id = m.user_id
JOIN public.squads s ON s.id = m.squad_id
WHERE EXISTS (
  SELECT 1 FROM public.squad_members sm
  WHERE sm.squad_id = m.squad_id 
  AND sm.user_id = auth.uid()
  AND sm.is_active = true
);

-- Create view for user's squads with member counts
CREATE OR REPLACE VIEW graphql_public.my_squads AS
SELECT 
  s.*,
  (SELECT COUNT(*) FROM squad_members WHERE squad_id = s.id) as member_count,
  (SELECT role FROM squad_members WHERE squad_id = s.id AND user_id = auth.uid()) as my_role,
  (SELECT joined_at FROM squad_members WHERE squad_id = s.id AND user_id = auth.uid()) as my_joined_at
FROM public.squads s
WHERE EXISTS (
  SELECT 1 FROM public.squad_members sm
  WHERE sm.squad_id = s.id 
  AND sm.user_id = auth.uid()
);

-- Create view for activities with squad context
CREATE OR REPLACE VIEW graphql_public.squad_activities_view AS
SELECT 
  a.*,
  sa.squad_id,
  sa.squad_suffer_score,
  sa.note as squad_note,
  u.display_name as user_display_name,
  s.name as squad_name
FROM public.activities a
LEFT JOIN public.squad_activities sa ON sa.activity_id = a.id
JOIN public.profiles u ON u.id = a.user_id
LEFT JOIN public.squads s ON s.id = sa.squad_id
WHERE a.user_id = auth.uid() 
   OR EXISTS (
     SELECT 1 FROM public.squad_members sm
     WHERE sm.squad_id = sa.squad_id 
     AND sm.user_id = auth.uid()
   );

-- Apply RLS to views
ALTER VIEW graphql_public.squad_messages OWNER TO authenticated;
ALTER VIEW graphql_public.my_squads OWNER TO authenticated;
ALTER VIEW graphql_public.squad_activities_view OWNER TO authenticated;
```

## 3. Add GraphQL Comments for Documentation

```sql
-- Add comments that appear in GraphQL schema documentation
COMMENT ON VIEW graphql_public.squad_messages IS 
  'Messages in squads you belong to, with user and squad context';

COMMENT ON COLUMN graphql_public.squad_messages.id IS 
  'Unique message identifier';

COMMENT ON COLUMN graphql_public.squad_messages.content IS 
  'Message text content (null for media-only messages)';

COMMENT ON COLUMN graphql_public.squad_messages.type IS 
  'Message type: text, photo, voice, status, suffer';

COMMENT ON VIEW graphql_public.my_squads IS 
  'All squads you are a member of, with your role and member count';

COMMENT ON VIEW graphql_public.squad_activities_view IS 
  'Your activities and activities shared with your squads';
```

## 4. Flutter GraphQL Client Setup

### Install Dependencies

```yaml
# pubspec.yaml
dependencies:
  graphql_flutter: ^5.1.2
  graphql_codegen: ^0.13.0
  build_runner: ^2.4.0
```

### Configure GraphQL Client

```dart
// lib/infrastructure/graphql/graphql_client_config.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GraphQLConfig {
  static GraphQLClient getClient() {
    final supabase = Supabase.instance.client;
    
    // Get the GraphQL endpoint from Supabase
    final httpLink = HttpLink(
      '${supabase.supabaseUrl}/graphql/v1',
      defaultHeaders: {
        'apikey': supabase.anonKey,
        'Content-Type': 'application/json',
      },
    );

    // Add auth link for authenticated requests
    final authLink = AuthLink(
      getToken: () async {
        final session = supabase.auth.currentSession;
        return session?.accessToken != null 
          ? 'Bearer ${session!.accessToken}'
          : null;
      },
    );

    final link = authLink.concat(httpLink);

    return GraphQLClient(
      link: link,
      cache: GraphQLCache(store: HiveStore()),
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
    );
  }
}
```

## 5. Define GraphQL Queries and Mutations

Create `.graphql` files that can be used for code generation:

```graphql
# lib/infrastructure/graphql/queries/squad_messages.graphql

query GetSquadMessages($squadId: UUID!, $limit: Int = 50) {
  squadMessages(
    filter: { squad_id: { eq: $squadId } }
    orderBy: { created_at: DescNullsLast }
    first: $limit
  ) {
    edges {
      node {
        id
        content
        type
        mediaUrl
        metadata
        createdAt
        userDisplayName
        userAvatarUrl
      }
    }
  }
}

query GetMySquads {
  mySquads {
    edges {
      node {
        id
        name
        description
        memberCount
        myRole
        myJoinedAt
        createdAt
      }
    }
  }
}

mutation SendMessage(
  $squadId: UUID!
  $content: String!
  $type: String = "text"
) {
  insertIntoMessages(
    objects: {
      squad_id: $squadId
      content: $content
      type: $type
      user_id: auth.uid()
    }
  ) {
    affectedCount
    records {
      id
      createdAt
    }
  }
}
```

## 6. Generate Flutter Types from GraphQL

### Setup Code Generation

```yaml
# build.yaml
targets:
  $default:
    builders:
      graphql_codegen:
        options:
          schema: lib/infrastructure/graphql/schema.graphql
          queries_glob: lib/infrastructure/graphql/**/*.graphql
          output: lib/infrastructure/graphql/generated/
```

### Run Code Generation

```bash
# Download schema from Supabase
curl -X POST \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { types { name } } }"}' \
  https://YOUR_PROJECT.supabase.co/graphql/v1 \
  > lib/infrastructure/graphql/schema.graphql

# Generate Dart types
flutter pub run build_runner build --delete-conflicting-outputs
```

## 7. Create GraphQL Repository

```dart
// lib/infrastructure/graphql/graphql_message_repository.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:squadup/infrastructure/graphql/generated/squad_messages.dart';

class GraphQLMessageRepository {
  final GraphQLClient _client;
  
  GraphQLMessageRepository(this._client);
  
  Stream<List<SquadMessage>> watchSquadMessages(String squadId) {
    return _client
      .watchQuery(
        WatchQueryOptions(
          document: GET_SQUAD_MESSAGES_QUERY,
          variables: {'squadId': squadId, 'limit': 50},
          pollInterval: const Duration(seconds: 10),
        ),
      )
      .map((result) {
        if (result.hasException) throw result.exception!;
        
        return GetSquadMessages$Query
          .fromJson(result.data!)
          .squadMessages
          .edges
          .map((edge) => edge.node)
          .toList();
      });
  }
  
  Future<void> sendMessage({
    required String squadId,
    required String content,
    String type = 'text',
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: SEND_MESSAGE_MUTATION,
        variables: {
          'squadId': squadId,
          'content': content,
          'type': type,
        },
      ),
    );
    
    if (result.hasException) throw result.exception!;
  }
}
```

## 8. GraphQL Explorer for Development

### Use GraphQL Playground

Access at: `https://YOUR_PROJECT.supabase.co/graphql/v1`

With headers:
```json
{
  "apikey": "YOUR_ANON_KEY",
  "Authorization": "Bearer YOUR_ACCESS_TOKEN"
}
```

### Example Exploration Queries

```graphql
# Discover available types
{
  __schema {
    types {
      name
      description
      fields {
        name
        description
        type {
          name
        }
      }
    }
  }
}

# Explore a specific type
{
  __type(name: "SquadMessages") {
    fields {
      name
      description
      args {
        name
        type {
          name
        }
      }
    }
  }
}
```

## 9. Implement Smart Caching

```dart
// lib/infrastructure/graphql/graphql_cache_manager.dart
class GraphQLCacheManager {
  final GraphQLClient _client;
  
  // Cache squad members for 5 minutes
  Future<List<SquadMember>> getSquadMembers(String squadId) async {
    final cacheKey = 'squad_members_$squadId';
    
    // Try to read from cache first
    final cached = _client.cache.readQuery(
      Request(
        operation: Operation(
          document: GET_SQUAD_MEMBERS_QUERY,
          variables: {'squadId': squadId},
        ),
      ),
    );
    
    if (cached != null) {
      final cacheTime = _getCacheTime(cacheKey);
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < Duration(minutes: 5)) {
        return _parseSquadMembers(cached);
      }
    }
    
    // Fetch fresh data
    final result = await _client.query(
      QueryOptions(
        document: GET_SQUAD_MEMBERS_QUERY,
        variables: {'squadId': squadId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    
    _setCacheTime(cacheKey);
    return _parseSquadMembers(result.data!);
  }
}
```

## 10. Migration Strategy

### Phase 1: Parallel Implementation (Week 1)
- [ ] Enable pg_graphql extension
- [ ] Create GraphQL views alongside existing REST
- [ ] Set up GraphQL client in Flutter
- [ ] Test with one feature (e.g., squad messages)

### Phase 2: Gradual Migration (Week 2-3)
- [ ] Migrate read operations to GraphQL
- [ ] Keep writes on REST initially
- [ ] Generate TypeScript types for edge functions
- [ ] Monitor performance differences

### Phase 3: Full Migration (Week 4)
- [ ] Move write operations to GraphQL
- [ ] Deprecate REST endpoints
- [ ] Update all repositories to use GraphQL
- [ ] Remove old Supabase client code

## Benefits You'll Get

1. **Instant Documentation**: Open GraphQL playground and see everything
2. **Type Safety**: Auto-generated types from schema
3. **Better DX**: Autocomplete for all queries and mutations
4. **Simplified RLS**: Views handle the complexity, GraphQL just exposes them
5. **Relationship Loading**: Request exactly what you need in one query
6. **Real-time Subscriptions**: GraphQL subscriptions for live updates

## Example: Before vs After

### Before (REST + Manual Checks)
```dart
// Multiple queries, manual RLS checks, no clear schema
final squad = await supabase.from('squads').select().eq('id', squadId);
final members = await supabase.from('squad_members').select().eq('squad_id', squadId);
final messages = await supabase.from('messages').select().eq('squad_id', squadId);
// Hope the RLS doesn't fail...
```

### After (GraphQL)
```graphql
query GetSquadDetails($squadId: UUID!) {
  squad(id: $squadId) {
    id
    name
    members {
      user {
        displayName
        avatarUrl
      }
      role
    }
    messages(last: 50) {
      content
      user {
        displayName
      }
    }
  }
}
```

The schema tells you exactly what's available, and the view handles all RLS complexity!