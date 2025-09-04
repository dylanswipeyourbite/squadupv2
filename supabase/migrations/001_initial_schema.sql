-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For compound indexes

-- ====================================
-- ENUMS
-- ====================================

-- User roles within a squad
CREATE TYPE squad_role AS ENUM ('captain', 'member');

-- Squad visibility (for future use)
CREATE TYPE squad_visibility AS ENUM ('private', 'public');

-- Activity types matching Terra's taxonomy
CREATE TYPE activity_type AS ENUM (
  'running',
  'cycling',
  'swimming',
  'strength_training',
  'crossfit',
  'hyrox',
  'walking',
  'hiking',
  'rowing',
  'other'
);

-- Message types for chat
CREATE TYPE message_type AS ENUM (
  'text',
  'activity_checkin',
  'image',
  'voice',
  'video',
  'poll',
  'system'
);

-- ====================================
-- TABLES
-- ====================================

-- User profiles (extends Firebase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  -- Running preferences
  preferred_units TEXT DEFAULT 'metric' CHECK (preferred_units IN ('metric', 'imperial')),
  -- Onboarding data
  onboarding_completed BOOLEAN DEFAULT false,
  onboarding_data JSONB DEFAULT '{}',
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ DEFAULT NOW()
);

-- Squads table
CREATE TABLE squads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  invite_code TEXT UNIQUE NOT NULL,
  -- Squad settings
  visibility squad_visibility DEFAULT 'private',
  max_members INTEGER DEFAULT 8 CHECK (max_members BETWEEN 2 AND 8),
  member_count INTEGER DEFAULT 0,
  -- Customization
  avatar_url TEXT,
  theme_color TEXT,
  -- Expert persona names (customizable)
  expert_names JSONB DEFAULT '{
    "sage": "Sage",
    "alex": "Alex",
    "nova": "Nova",
    "aria": "Aria",
    "pace": "Pace",
    "koa": "Koa"
  }',
  -- Stats
  total_distance_km NUMERIC DEFAULT 0,
  total_activities INTEGER DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Squad membership
CREATE TABLE squad_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role squad_role DEFAULT 'member',
  -- Member stats
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  total_activities INTEGER DEFAULT 0,
  total_distance_km NUMERIC DEFAULT 0,
  last_activity_at TIMESTAMPTZ,
  -- Notification preferences
  notifications_enabled BOOLEAN DEFAULT true,
  -- Unique constraint to prevent duplicate memberships
  UNIQUE(squad_id, profile_id)
);

-- Squad messages (chat)
CREATE TABLE squad_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Message content
  type message_type NOT NULL DEFAULT 'text',
  content TEXT,
  metadata JSONB DEFAULT '{}', -- For structured data (polls, checkins, etc)
  -- Reply threading
  reply_to_id UUID REFERENCES squad_messages(id) ON DELETE SET NULL,
  -- Edit history
  edited_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Message reactions
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES squad_messages(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- Prevent duplicate reactions
  UNIQUE(message_id, profile_id, emoji)
);

-- Message read receipts
CREATE TABLE message_read_receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES squad_messages(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  -- Prevent duplicate receipts
  UNIQUE(message_id, profile_id)
);

-- Activities (Layer 1 - Summary)
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  -- Activity basics
  type activity_type NOT NULL,
  name TEXT,
  -- Core metrics
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  duration_seconds INTEGER NOT NULL,
  distance_meters NUMERIC,
  elevation_gain_meters NUMERIC,
  -- Effort and performance
  average_heart_rate INTEGER,
  max_heart_rate INTEGER,
  suffer_score INTEGER CHECK (suffer_score BETWEEN 1 AND 10),
  average_pace_seconds_per_km NUMERIC,
  -- Source
  source TEXT, -- 'manual', 'garmin', 'strava', etc.
  external_id TEXT, -- ID from source system
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity details (Layer 2 - Structured data)
CREATE TABLE activity_details (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  -- Detailed metrics
  splits JSONB, -- Array of split data
  laps JSONB, -- Array of lap data
  heart_rate_zones JSONB, -- Time in zones
  power_zones JSONB, -- For cycling
  cadence_avg INTEGER,
  -- Weather conditions
  weather_temp_celsius NUMERIC,
  weather_conditions TEXT,
  -- Notes and classification
  notes TEXT,
  workout_type TEXT, -- 'easy', 'tempo', 'intervals', etc.
  -- AI analysis
  ai_summary TEXT,
  ai_detected_structure TEXT,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity raw archive (Layer 3 - Compressed raw data)
CREATE TABLE activity_raw_archive (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  -- Compressed raw data from provider
  raw_data BYTEA, -- Compressed JSON
  provider TEXT NOT NULL,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity check-ins (linking activities to squad messages)
CREATE TABLE activity_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  activity_id UUID NOT NULL REFERENCES activities(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES squad_messages(id) ON DELETE CASCADE,
  squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
  -- Quick access to key metrics for display
  summary JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  -- Prevent duplicate checkins
  UNIQUE(activity_id, squad_id)
);

-- Races
CREATE TABLE races (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  date DATE NOT NULL,
  distance_km NUMERIC NOT NULL,
  -- Race details
  location TEXT,
  goal_time_seconds INTEGER,
  actual_time_seconds INTEGER,
  -- Squad associations
  primary_squad_id UUID REFERENCES squads(id) ON DELETE SET NULL,
  -- Race phase calculations (will be calculated via view or function)
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Race squad associations (many-to-many)
CREATE TABLE race_squads (
  race_id UUID NOT NULL REFERENCES races(id) ON DELETE CASCADE,
  squad_id UUID NOT NULL REFERENCES squads(id) ON DELETE CASCADE,
  PRIMARY KEY (race_id, squad_id)
);

-- ====================================
-- INDEXES
-- ====================================

-- Profile indexes
CREATE INDEX idx_profiles_firebase_uid ON profiles(firebase_uid);
CREATE INDEX idx_profiles_email ON profiles(email);

-- Squad indexes
CREATE INDEX idx_squads_invite_code ON squads(invite_code);

-- Squad member indexes
CREATE INDEX idx_squad_members_squad_id ON squad_members(squad_id);
CREATE INDEX idx_squad_members_profile_id ON squad_members(profile_id);

-- Message indexes
CREATE INDEX idx_squad_messages_squad_id ON squad_messages(squad_id);
CREATE INDEX idx_squad_messages_profile_id ON squad_messages(profile_id);
CREATE INDEX idx_squad_messages_created_at ON squad_messages(created_at DESC);
CREATE INDEX idx_squad_messages_reply_to_id ON squad_messages(reply_to_id);

-- Activity indexes
CREATE INDEX idx_activities_profile_id ON activities(profile_id);
CREATE INDEX idx_activities_started_at ON activities(started_at DESC);
CREATE INDEX idx_activities_external_id ON activities(external_id);

-- Activity checkin indexes
CREATE INDEX idx_activity_checkins_squad_id ON activity_checkins(squad_id);
CREATE INDEX idx_activity_checkins_activity_id ON activity_checkins(activity_id);

-- Race indexes
CREATE INDEX idx_races_profile_id ON races(profile_id);
CREATE INDEX idx_races_date ON races(date);
CREATE INDEX idx_races_primary_squad_id ON races(primary_squad_id);

-- ====================================
-- HELPER FUNCTIONS
-- ====================================

-- Generate unique invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ====================================
-- TRIGGERS
-- ====================================

-- Auto-update updated_at timestamps
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_squads_updated_at BEFORE UPDATE ON squads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_activities_updated_at BEFORE UPDATE ON activities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_races_updated_at BEFORE UPDATE ON races
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate invite codes for new squads
CREATE OR REPLACE FUNCTION set_squad_invite_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invite_code IS NULL THEN
    NEW.invite_code := generate_invite_code();
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM squads WHERE invite_code = NEW.invite_code) LOOP
      NEW.invite_code := generate_invite_code();
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_squad_invite_code_trigger BEFORE INSERT ON squads
  FOR EACH ROW EXECUTE FUNCTION set_squad_invite_code();

-- Update squad member count
CREATE OR REPLACE FUNCTION update_squad_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE squads SET member_count = member_count + 1 WHERE id = NEW.squad_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE squads SET member_count = member_count - 1 WHERE id = OLD.squad_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_squad_member_count_trigger
AFTER INSERT OR DELETE ON squad_members
  FOR EACH ROW EXECUTE FUNCTION update_squad_member_count();
