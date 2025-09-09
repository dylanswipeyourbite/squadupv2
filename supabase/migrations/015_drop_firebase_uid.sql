-- Drop deprecated firebase_uid column now that we use Supabase Auth
ALTER TABLE profiles DROP COLUMN IF EXISTS firebase_uid;
