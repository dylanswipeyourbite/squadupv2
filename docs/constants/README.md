# Shared Constants

This directory contains constants that are shared between TypeScript (edge functions) and Dart (Flutter app) to ensure consistency across the codebase.

## Terra Data Types

We maintain two separate JSON files for Terra data:

### 1. Terra Enums (`terra-data-types.json`)

Contains all Terra API enum definitions:
- Activity Types (140 values)
- Activity Levels
- Heart Rate Zones
- Sleep Levels
- Upload Types
- Stress Levels
- Recovery Levels
- Menstruation Flow
- Meal Types
- And more...

### 2. Activity Mappings (`terra-activity-mapping.json`)

Maps Terra activity types to simplified SquadUp activity categories:
- Maps 140 Terra activity types to 14 SquadUp categories
- Provides display names, emojis, and groupings

### Architecture

```
terra-data-types.json + terra-activity-mapping.json
    ↓
    ├── scripts/generate_terra_constants.dart → Flutter Terra enums
    ├── scripts/generate_terra_sql.js → Database seed scripts
    └── Edge Functions load at runtime → TypeScript usage
```

### Usage

#### Generate Flutter Constants
```bash
# Generate Terra enum constants
dart scripts/generate_terra_constants.dart

# Generate activity mapping constants (if needed)
dart scripts/generate_activity_constants.dart
```

#### Generate SQL Seed Data
```bash
node scripts/generate_terra_sql.js
```
This generates `supabase/seed/terra_enums.sql`

### Adding New Terra Data

1. For new Terra enums: Update `terra-data-types.json`
2. For activity mappings: Update `terra-activity-mapping.json`
3. Run the appropriate generator scripts
4. Deploy changes as needed

### Terra API Reference

See Terra's official documentation for complete enum definitions:
https://docs.tryterra.co/reference/enums

## Command Types

The `command-types.json` file is the **single source of truth** for command type values used throughout the application:

```json
{
  "commandTypes": {
    "QUERY_PR": "queryPr",
    "QUERY_KNOWLEDGE": "queryKnowledge",
    "REMEMBER": "remember",
    "JOURNEY": "journey",
    "SETTINGS": "settings",
    "STATS": "stats",
    "HELP": "help",
    "UNKNOWN": "unknown"
  }
}
```

## Usage

### TypeScript (Edge Functions)
```typescript
// Load at runtime in Deno
const commandConstants = JSON.parse(await Deno.readTextFile("../../../shared/constants/command-types.json"))

// Use in code
const commandType = commandConstants.commandTypes.QUERY_PR; // "queryPr"
```

### Dart (Flutter)
```dart
import 'package:squadup/core/constants/command_types.dart';

// Use in code
final commandType = CommandTypeConstants.queryPr; // "queryPr"
```

**Note**: The Dart file is auto-generated from the JSON. Run this command to regenerate:
```bash
dart scripts/generate_constants.dart
```

## Key Points

1. **Single Source**: The JSON file is the only place where command types are defined
2. **Auto-Generation**: The Dart constants are generated from the JSON file
3. **Consistency**: All command types use camelCase format (e.g., `queryPr`)
4. **Type Safety**: Both TypeScript and Dart provide type-safe access

## Adding New Command Types

1. **Edit the JSON file**: Add the new type to `command-types.json`
2. **Regenerate Dart**: Run `dart scripts/generate_constants.dart`
3. **Update implementations**:
   - Add the corresponding enum value in `CommandType` enum
   - Update the edge function to handle the new type
   - Implement the handler in `VaultCommandProcessorImpl`

## Important

- **Never manually edit** the generated Dart file (`lib/core/constants/command_types.dart`)
- **Always edit** the JSON file first, then regenerate
- Consider adding the generation step to your build process