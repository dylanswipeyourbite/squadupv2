-- Ensure profiles has user_id column for Supabase Auth linkage
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS user_id UUID;
CREATE UNIQUE INDEX IF NOT EXISTS profiles_user_id_key ON profiles(user_id);
