-- Make firebase_uid nullable to support Supabase Auth-only users
ALTER TABLE profiles ALTER COLUMN firebase_uid DROP NOT NULL;
-- Keep unique if present; nulls are allowed to repeat
