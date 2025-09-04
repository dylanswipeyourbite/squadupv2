-- ====================================
-- REALTIME SUBSCRIPTIONS
-- ====================================

-- Enable realtime for squad messages
ALTER PUBLICATION supabase_realtime ADD TABLE squad_messages;

-- Enable realtime for message reactions
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;

-- Enable realtime for read receipts
ALTER PUBLICATION supabase_realtime ADD TABLE message_read_receipts;

-- Enable realtime for squad members (for presence)
ALTER PUBLICATION supabase_realtime ADD TABLE squad_members;

-- Enable realtime for activity checkins
ALTER PUBLICATION supabase_realtime ADD TABLE activity_checkins;
