## Activity Data Contract (Layers 1–3)

This contract defines the interface for activity storage and retrieval across three layers. Implementations SHOULD adhere to the shapes and required fields. Optional fields may be null unless otherwise stated.

### Layer 1 — Summary (UI/Lists/Quick Analytics)

Purpose: Compact record optimized for UI, ordering, and light analytics; directly powers check-ins and list views.

Schema (JSON):
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "activity_type_id": 8,
  "activity_type_label": "Running",
  "duration_minutes": 45,
  "distance_km": 10.05,
  "pace_min_per_km": 4.47,
  "elevation_gain_m": 120.0,
  "average_hr_bpm": 152,
  "rpe": 6,
  "upload_type_id": 1,
  "upload_type_label": "Automatic",
  "external_activity_id": "terra_<provider_id>",
  "device_source": "GARMIN|STRAVA|POLAR|FITBIT|MANUAL",
  "created_at": "2025-01-15T07:45:00Z",
  "updated_at": "2025-01-15T08:15:00Z"
}
```

Constraints:
- `id`, `user_id`, `activity_type_id`, `duration_minutes`, `created_at` are REQUIRED.
- `activity_type_id` MUST be the Terra-provided numeric code. Any Terra-supported type (e.g., Tennis 87) is accepted.
- `activity_type_label` is DERIVED from `shared/constants/terra-data-types.json` and SHOULD NOT be used as source of truth.
- `rpe` is OPTIONAL and user-provided (or estimated server-side).

### Layer 2 — Details (Structured Metrics)

Purpose: Rich metrics for analysis and Expert reasoning, including splits, cadence, and effort segments.

Schema (JSON):
```json
{
  "activity_id": "uuid",
  "splits": [
    { "index": 1, "distance_km": 1.0, "duration_minutes": 4.45, "avg_hr": 148, "elev_gain_m": 2.0 },
    { "index": 2, "distance_km": 1.0, "duration_minutes": 4.40, "avg_hr": 151, "elev_gain_m": 5.0 }
  ],
  "cadence": { "avg_spm": 172, "max_spm": 184 },
  "power": { "avg_watts": 260, "max_watts": 420 },
  "effort_segments": [
    { "label": "warmup", "minutes": 10 },
    { "label": "tempo", "minutes": 25 },
    { "label": "cooldown", "minutes": 10 }
  ],
  "heart_rate_series": {
    "sampling_hz": 1,
    "values": [150,152,153]
  },
  "notes": "Felt strong; headwind on last 2k"
}
```

Constraints:
- `activity_id` REQUIRED and must reference Layer 1 `id`.
- Arrays may be empty; missing blocks are treated as unknown, not zero.

### Layer 3 — Raw Archive (Compressed Provider Payload)

Purpose: Lossless archival of the original provider payload for provenance and future reprocessing. Not used directly by UI or Expert reasoning.

Schema (JSON):
```json
{
  "activity_id": "uuid",
  "provider": "GARMIN|STRAVA|POLAR|FITBIT",
  "ingested_at": "2025-01-15T08:00:00Z",
  "raw_data_compressed": "<base64 or byte array>"
}
```

Constraints:
- `activity_id`, `provider`, `raw_data_compressed` REQUIRED.
- Compression MUST be reversible; recommended gzip+base64 or bytea.

### Cross-Layer Invariants

- Layer 2 `activity_id` MUST equal Layer 1 `id`.
- Layer 3 `activity_id` MUST equal Layer 1 `id`.
- `external_activity_id` uniqueness per user is RECOMMENDED to prevent duplicates.
- Deletion cascade: Layer 3 → Layer 2 → Layer 1; UI must clear corresponding check-ins/messages.

### Example: Minimal Run (L1 + L2)

Layer 1:
```json
{
  "id": "3f9b...",
  "user_id": "a12c...",
  "activity_type_id": 8,
  "activity_type_label": "Running",
  "duration_minutes": 45,
  "distance_km": 10.0,
  "rpe": 6,
  "upload_type_id": 1,
  "upload_type_label": "Automatic",
  "external_activity_id": "terra_abc123",
  "device_source": "GARMIN",
  "created_at": "2025-01-15T07:45:00Z",
  "updated_at": "2025-01-15T08:15:00Z"
}
```

Layer 2:
```json
{
  "activity_id": "3f9b...",
  "splits": [
    { "index": 1, "distance_km": 1.0, "duration_minutes": 4.50 },
    { "index": 2, "distance_km": 1.0, "duration_minutes": 4.30 }
  ],
  "cadence": { "avg_spm": 174 },
  "effort_segments": [ { "label": "tempo", "minutes": 30 } ]
}
```

### Retrieval Guidelines for Expert Flow

- Prefer Layer 1 for cohort selection (date windows, types, intensity proxies like RPE) and top-level stats.
- Use Layer 2 for focused analysis (splits, cadence, segments) once relevance is established.
- Never pass Layer 3 to the model; use it only for reprocessing/backfills.

### Terra Field Mapping (Inbound → Layers 1/2/3)

Notes:
- Values may be missing per provider; when missing, omit the field rather than defaulting to zero unless specified.
- Enum handling uses Terra numeric IDs as the canonical value; human-readable labels are derived from `shared/constants/terra-data-types.json`.

Layer 1 mappings:
- `activity_type_id` ← `metadata.type` (integer Terra code)
- `activity_type_label` ← lookup `terra-data-types.enums.activityType[metadata.type]` (fallback `metadata.name` if missing)
- `duration_minutes` ← `active_durations_data.activity_seconds / 60` (fallback: `metadata.start_time` to `metadata.end_time` difference)
- `distance_km` ← `distance_data.summary.distance_meters / 1000`
- `elevation_gain_m` ← `distance_data.summary.elevation.gain_actual_meters`
- `average_hr_bpm` ← `heart_rate_data.summary.avg_hr_bpm`
- `pace_min_per_km` ← `duration_minutes / distance_km` (only if `distance_km > 0`)
- `rpe` ← user-provided or estimated server-side (if estimation is enabled)
- `upload_type_id` ← `metadata.upload_type`; `upload_type_label` ← lookup `terra-data-types.enums.uploadType[metadata.upload_type]`
- `external_activity_id` ← `metadata.summary_id` (fallback `metadata.session_id`) prefixed with `terra_`
- `device_source` ← provider associated with the Terra connection for the user (e.g., GARMIN/STRAVA)

Layer 2 mappings:
- `splits[]` ← provider lap/split data when present (distance/time/avg HR/elevation per split)
- `cadence` ← cadence summary (avg/max) when provided by device
- `power` ← power summary (avg/max) when provided by device
- `effort_segments[]` ← derived from intervals/structured workouts if available
- `heart_rate_series` ← downsampled HR series from provider data (state sampling Hz)

Layer 3 mappings:
- `raw_data_compressed` ← full Terra webhook payload (lossless)
- `provider` ← Terra provider string used for the import

### Mapping Pseudocode

```pseudo
L1.activity_type_id = terra.metadata.type
L1.activity_type_label = terra_data_types.enums.activityType[L1.activity_type_id] OR terra.metadata.name
L1.duration_minutes = terra.active_durations_data.activity_seconds/60
  IF null THEN (parse(terra.metadata.end_time) - parse(terra.metadata.start_time)).minutes
L1.distance_km = terra.distance_data.summary.distance_meters / 1000
L1.elevation_gain_m = terra.distance_data.summary.elevation.gain_actual_meters
L1.average_hr_bpm = terra.heart_rate_data.summary.avg_hr_bpm
IF distance_km > 0 THEN L1.pace_min_per_km = duration_minutes / distance_km
L1.rpe = request.rpe_input OR estimate_rpe(duration_minutes, average_hr_bpm, distance_km, elevation_gain_m)
L1.upload_type_id = terra.metadata.upload_type
L1.upload_type_label = terra_data_types.enums.uploadType[L1.upload_type_id]
L1.external_activity_id = 'terra_' + (terra.metadata.summary_id OR terra.metadata.session_id)
L1.device_source = request.provider OR connection.provider

// L2 population is conditional based on provider data presence
L2.splits = map_splits(terra)
L2.cadence = map_cadence(terra)
L2.power = map_power(terra)
L2.heart_rate_series = downsample_hr_series(terra)

// L3 stores the original payload
L3.raw_data_compressed = compress(terra_raw_json)
```

### Compact Enum Reference (Terra → IDs)

Source of truth: `shared/constants/terra-data-types.json`. Below are quick samples; consult the JSON for complete lists.

ActivityType (samples)

| ID | Label               |
|----|---------------------|
| 8  | Running             |
| 56 | Jogging             |
| 58 | Treadmill Running   |
| 1  | Biking              |
| 15 | Mountain Biking     |
| 82 | Swimming            |
| 35 | Hiking              |
| 87 | Tennis              |
| 113| Crossfit            |
| 108| Other               |

UploadType (samples)

| ID | Label       |
|----|-------------|
| 0  | Unknown     |
| 1  | Automatic   |
| 2  | Manual      |
| 3  | Update      |
| 6  | Third party upload |

ActivityLevel (samples)

| ID | Label            |
|----|------------------|
| 0  | Unknown          |
| 1  | Rest             |
| 3  | Low Intensity    |
| 4  | Medium Intensity |
| 5  | High Intensity   |

HeartRateZone (samples)

| ID | Label  |
|----|--------|
| 0  | Zone 0 |
| 1  | Zone 1 |
| 2  | Zone 2 |
| 3  | Zone 3 |
| 4  | Zone 4 |
| 5  | Zone 5 |

Notes
- For any enum field, store the numeric ID as canonical and derive the label via `terra-data-types.json` at read time or in views.
- If a provider emits a new ID not yet present locally, persist the ID and treat the label as "Unknown" until dictionaries are updated.

