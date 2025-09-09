-- Ensure profiles table is fully migrated to Supabase Auth
-- This handles cases where previous migrations might not have applied correctly

-- Drop firebase_uid column and its dependencies
ALTER TABLE profiles DROP COLUMN IF EXISTS firebase_uid CASCADE;

-- Also drop the old index if it still exists
DROP INDEX IF EXISTS idx_profiles_firebase_uid;
