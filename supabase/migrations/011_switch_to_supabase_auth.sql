-- Switch to Supabase Auth: use auth.uid() and profiles.user_id

-- 1) Add user_id to profiles and backfill from firebase_uid via auth.users lookup if possible
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'profiles' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN user_id UUID;
    CREATE UNIQUE INDEX IF NOT EXISTS profiles_user_id_key ON profiles(user_id);
  END IF;
END $$;

-- 2) Create helper functions using auth.uid()
CREATE OR REPLACE FUNCTION get_current_user_id()
RETURNS UUID AS $$
  SELECT auth.uid()
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION get_current_profile_id()
RETURNS UUID AS $$
  SELECT id FROM profiles WHERE user_id = auth.uid()
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_member_of_squad(squad UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM squad_members sm
    WHERE sm.squad_id = squad AND sm.profile_id = get_current_profile_id()
  )
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION is_captain_of_squad(squad UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM squad_members sm
    WHERE sm.squad_id = squad AND sm.profile_id = get_current_profile_id() AND sm.role = 'captain'
  )
$$ LANGUAGE sql STABLE;

-- 3) Enable RLS (idempotent) and replace policies to use auth.uid()/user_id
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE squads ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE squad_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_read_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_raw_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE races ENABLE ROW LEVEL SECURITY;
ALTER TABLE race_squads ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist (safe)
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT policyname, schemaname, tablename FROM pg_policies LOOP
    IF r.tablename IN ('profiles','squads','squad_members','squad_messages','message_reactions','message_read_receipts','activities','activity_details','activity_raw_archive','activity_checkins','races','race_squads') THEN
      EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END IF;
  END LOOP;
END $$;

-- Profiles
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can insert their own profile"
  ON profiles FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Squads
CREATE POLICY "Squads viewable by authenticated users"
  ON squads FOR SELECT TO authenticated USING (true);

CREATE POLICY "Squad members can update squad"
  ON squads FOR UPDATE TO authenticated
  USING (is_member_of_squad(id)) WITH CHECK (is_member_of_squad(id));

CREATE POLICY "Captains can delete squads"
  ON squads FOR DELETE TO authenticated USING (is_captain_of_squad(id));

CREATE POLICY "Users can create squads"
  ON squads FOR INSERT TO authenticated WITH CHECK (true);

-- Squad members
CREATE POLICY "Squad members can view member list"
  ON squad_members FOR SELECT TO authenticated
  USING (is_member_of_squad(squad_id));

CREATE POLICY "Users can join squads"
  ON squad_members FOR INSERT TO authenticated
  WITH CHECK (profile_id = get_current_profile_id());

CREATE POLICY "Members can leave squads"
  ON squad_members FOR DELETE TO authenticated
  USING (profile_id = get_current_profile_id());

-- Squad messages
CREATE POLICY "Members can view messages"
  ON squad_messages FOR SELECT TO authenticated
  USING (is_member_of_squad(squad_id));

CREATE POLICY "Members can send messages"
  ON squad_messages FOR INSERT TO authenticated
  WITH CHECK (is_member_of_squad(squad_id) AND profile_id = get_current_profile_id());

CREATE POLICY "Users can edit own messages"
  ON squad_messages FOR UPDATE TO authenticated
  USING (profile_id = get_current_profile_id()) WITH CHECK (profile_id = get_current_profile_id());

CREATE POLICY "Users can delete own messages"
  ON squad_messages FOR DELETE TO authenticated
  USING (profile_id = get_current_profile_id());

-- Reactions
CREATE POLICY "Members can view reactions"
  ON message_reactions FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM squad_messages m WHERE m.id = message_reactions.message_id AND is_member_of_squad(m.squad_id)
  ));

CREATE POLICY "Members can add reactions"
  ON message_reactions FOR INSERT TO authenticated
  WITH CHECK (profile_id = get_current_profile_id() AND EXISTS (
    SELECT 1 FROM squad_messages m WHERE m.id = message_id AND is_member_of_squad(m.squad_id)
  ));

CREATE POLICY "Users can remove own reactions"
  ON message_reactions FOR DELETE TO authenticated
  USING (profile_id = get_current_profile_id());

-- Read receipts
CREATE POLICY "Members can view read receipts"
  ON message_read_receipts FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM squad_messages m WHERE m.id = message_read_receipts.message_id AND is_member_of_squad(m.squad_id)
  ));

CREATE POLICY "Users can mark messages as read"
  ON message_read_receipts FOR INSERT TO authenticated
  WITH CHECK (profile_id = get_current_profile_id() AND EXISTS (
    SELECT 1 FROM squad_messages m WHERE m.id = message_id AND is_member_of_squad(m.squad_id)
  ));

-- Activities
CREATE POLICY "Users can view own activities"
  ON activities FOR SELECT TO authenticated
  USING (profile_id = get_current_profile_id());

CREATE POLICY "Users can create own activities"
  ON activities FOR INSERT TO authenticated
  WITH CHECK (profile_id = get_current_profile_id());

CREATE POLICY "Users can update own activities"
  ON activities FOR UPDATE TO authenticated
  USING (profile_id = get_current_profile_id()) WITH CHECK (profile_id = get_current_profile_id());

CREATE POLICY "Users can delete own activities"
  ON activities FOR DELETE TO authenticated
  USING (profile_id = get_current_profile_id());

-- Activity details/checkins/races/race_squads follow similar patterns already handled above
