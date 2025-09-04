-- ====================================
-- ROW LEVEL SECURITY POLICIES
-- ====================================

-- Enable RLS on all tables
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

-- ====================================
-- HELPER FUNCTIONS
-- ====================================

-- Get current user's Firebase UID
CREATE OR REPLACE FUNCTION get_current_user_uid()
RETURNS TEXT AS $$
  SELECT auth.jwt() ->> 'sub'
$$ LANGUAGE sql STABLE;

-- Get user's profile ID from Firebase UID
CREATE OR REPLACE FUNCTION get_profile_id(firebase_uid TEXT)
RETURNS UUID AS $$
  SELECT id FROM profiles WHERE profiles.firebase_uid = $1
$$ LANGUAGE sql STABLE;

-- Check if user is member of a squad
CREATE OR REPLACE FUNCTION is_squad_member(squad_id UUID, profile_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM squad_members 
    WHERE squad_members.squad_id = $1 
    AND squad_members.profile_id = $2
  )
$$ LANGUAGE sql STABLE;

-- Check if user is captain of a squad
CREATE OR REPLACE FUNCTION is_squad_captain(squad_id UUID, profile_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM squad_members 
    WHERE squad_members.squad_id = $1 
    AND squad_members.profile_id = $2
    AND squad_members.role = 'captain'
  )
$$ LANGUAGE sql STABLE;

-- ====================================
-- PROFILES POLICIES
-- ====================================

-- Users can view any profile (needed for squad member lists)
CREATE POLICY "Profiles are viewable by authenticated users"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (firebase_uid = get_current_user_uid())
  WITH CHECK (firebase_uid = get_current_user_uid());

-- Service role can insert profiles (via Edge Function)
CREATE POLICY "Service role can manage profiles"
  ON profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ====================================
-- SQUADS POLICIES
-- ====================================

-- Anyone can view squad info if they know the ID or invite code
CREATE POLICY "Squads viewable by authenticated users"
  ON squads FOR SELECT
  TO authenticated
  USING (true);

-- Only squad members can update squad info
CREATE POLICY "Squad members can update squad"
  ON squads FOR UPDATE
  TO authenticated
  USING (
    is_squad_member(id, get_profile_id(get_current_user_uid()))
  )
  WITH CHECK (
    is_squad_member(id, get_profile_id(get_current_user_uid()))
  );

-- Only captains can delete squads
CREATE POLICY "Captains can delete squads"
  ON squads FOR DELETE
  TO authenticated
  USING (
    is_squad_captain(id, get_profile_id(get_current_user_uid()))
  );

-- Service role can create squads (via Edge Function)
CREATE POLICY "Service role can create squads"
  ON squads FOR INSERT
  TO service_role
  WITH CHECK (true);

-- ====================================
-- SQUAD MEMBERS POLICIES
-- ====================================

-- Members can view their squad's member list
CREATE POLICY "Squad members can view member list"
  ON squad_members FOR SELECT
  TO authenticated
  USING (
    is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Service role manages membership (via Edge Functions)
CREATE POLICY "Service role can manage membership"
  ON squad_members FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Members can leave squads (delete their own membership)
CREATE POLICY "Members can leave squads"
  ON squad_members FOR DELETE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
    AND role = 'member' -- Captains need special handling
  );

-- ====================================
-- SQUAD MESSAGES POLICIES
-- ====================================

-- Squad members can view all messages in their squads
CREATE POLICY "Squad members can view messages"
  ON squad_messages FOR SELECT
  TO authenticated
  USING (
    is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Squad members can send messages
CREATE POLICY "Squad members can send messages"
  ON squad_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
    AND profile_id = get_profile_id(get_current_user_uid())
  );

-- Users can edit their own messages
CREATE POLICY "Users can edit own messages"
  ON squad_messages FOR UPDATE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  )
  WITH CHECK (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- Users can soft-delete their own messages
CREATE POLICY "Users can delete own messages"
  ON squad_messages FOR DELETE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- ====================================
-- MESSAGE REACTIONS POLICIES
-- ====================================

-- Squad members can view reactions
CREATE POLICY "Squad members can view reactions"
  ON message_reactions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM squad_messages 
      WHERE squad_messages.id = message_reactions.message_id
      AND is_squad_member(squad_messages.squad_id, get_profile_id(get_current_user_uid()))
    )
  );

-- Squad members can add reactions
CREATE POLICY "Squad members can add reactions"
  ON message_reactions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM squad_messages 
      WHERE squad_messages.id = message_id
      AND is_squad_member(squad_messages.squad_id, get_profile_id(get_current_user_uid()))
    )
    AND profile_id = get_profile_id(get_current_user_uid())
  );

-- Users can remove their own reactions
CREATE POLICY "Users can remove own reactions"
  ON message_reactions FOR DELETE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- ====================================
-- MESSAGE READ RECEIPTS POLICIES
-- ====================================

-- Squad members can view read receipts
CREATE POLICY "Squad members can view read receipts"
  ON message_read_receipts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM squad_messages 
      WHERE squad_messages.id = message_read_receipts.message_id
      AND is_squad_member(squad_messages.squad_id, get_profile_id(get_current_user_uid()))
    )
  );

-- Users can mark messages as read
CREATE POLICY "Users can mark messages as read"
  ON message_read_receipts FOR INSERT
  TO authenticated
  WITH CHECK (
    profile_id = get_profile_id(get_current_user_uid())
    AND EXISTS (
      SELECT 1 FROM squad_messages 
      WHERE squad_messages.id = message_id
      AND is_squad_member(squad_messages.squad_id, get_profile_id(get_current_user_uid()))
    )
  );

-- ====================================
-- ACTIVITIES POLICIES
-- ====================================

-- Users can view their own activities
CREATE POLICY "Users can view own activities"
  ON activities FOR SELECT
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- Squad members can view activities shared in their squads
CREATE POLICY "Squad members can view shared activities"
  ON activities FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM activity_checkins
      JOIN squad_members ON squad_members.squad_id = activity_checkins.squad_id
      WHERE activity_checkins.activity_id = activities.id
      AND squad_members.profile_id = get_profile_id(get_current_user_uid())
    )
  );

-- Users can create their own activities
CREATE POLICY "Users can create own activities"
  ON activities FOR INSERT
  TO authenticated
  WITH CHECK (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- Users can update their own activities
CREATE POLICY "Users can update own activities"
  ON activities FOR UPDATE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  )
  WITH CHECK (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- Users can delete their own activities
CREATE POLICY "Users can delete own activities"
  ON activities FOR DELETE
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- ====================================
-- ACTIVITY DETAILS POLICIES
-- ====================================

-- Same access as activities table
CREATE POLICY "Activity details follow activity access"
  ON activity_details FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = activity_details.activity_id
      AND (
        activities.profile_id = get_profile_id(get_current_user_uid())
        OR EXISTS (
          SELECT 1 FROM activity_checkins
          JOIN squad_members ON squad_members.squad_id = activity_checkins.squad_id
          WHERE activity_checkins.activity_id = activities.id
          AND squad_members.profile_id = get_profile_id(get_current_user_uid())
        )
      )
    )
  );

-- Users can manage details for their own activities
CREATE POLICY "Users can manage own activity details"
  ON activity_details FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = activity_details.activity_id
      AND activities.profile_id = get_profile_id(get_current_user_uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = activity_details.activity_id
      AND activities.profile_id = get_profile_id(get_current_user_uid())
    )
  );

-- ====================================
-- ACTIVITY CHECKINS POLICIES
-- ====================================

-- Squad members can view checkins in their squads
CREATE POLICY "Squad members can view checkins"
  ON activity_checkins FOR SELECT
  TO authenticated
  USING (
    is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Users can create checkins for their own activities in their squads
CREATE POLICY "Users can create checkins"
  ON activity_checkins FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = activity_id
      AND activities.profile_id = get_profile_id(get_current_user_uid())
    )
    AND is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Users can delete their own checkins
CREATE POLICY "Users can delete own checkins"
  ON activity_checkins FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM activities
      WHERE activities.id = activity_id
      AND activities.profile_id = get_profile_id(get_current_user_uid())
    )
  );

-- ====================================
-- RACES POLICIES
-- ====================================

-- Users can view their own races
CREATE POLICY "Users can view own races"
  ON races FOR SELECT
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- Squad members can view races shared with their squads
CREATE POLICY "Squad members can view shared races"
  ON races FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM race_squads
      JOIN squad_members ON squad_members.squad_id = race_squads.squad_id
      WHERE race_squads.race_id = races.id
      AND squad_members.profile_id = get_profile_id(get_current_user_uid())
    )
  );

-- Users can manage their own races
CREATE POLICY "Users can manage own races"
  ON races FOR ALL
  TO authenticated
  USING (
    profile_id = get_profile_id(get_current_user_uid())
  )
  WITH CHECK (
    profile_id = get_profile_id(get_current_user_uid())
  );

-- ====================================
-- RACE SQUADS POLICIES
-- ====================================

-- Squad members can view race associations
CREATE POLICY "Squad members can view race associations"
  ON race_squads FOR SELECT
  TO authenticated
  USING (
    is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Users can share their races with their squads
CREATE POLICY "Users can share races with squads"
  ON race_squads FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM races
      WHERE races.id = race_id
      AND races.profile_id = get_profile_id(get_current_user_uid())
    )
    AND is_squad_member(squad_id, get_profile_id(get_current_user_uid()))
  );

-- Users can unshare their races
CREATE POLICY "Users can unshare races"
  ON race_squads FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM races
      WHERE races.id = race_id
      AND races.profile_id = get_profile_id(get_current_user_uid())
    )
  );
