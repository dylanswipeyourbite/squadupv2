-- Remove Firebase-specific helper and indexes
DROP FUNCTION IF EXISTS get_profile_id(TEXT);
DROP INDEX IF EXISTS idx_profiles_firebase_uid;
-- Optionally drop column if not needed anymore (kept for data history):
-- ALTER TABLE profiles DROP COLUMN IF EXISTS firebase_uid;
