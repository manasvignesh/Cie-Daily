-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE space_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('super_admin', 'content_manager')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is publisher or admin
CREATE OR REPLACE FUNCTION can_publish() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('super_admin', 'content_manager', 'publisher')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users
CREATE POLICY "Users are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Posts
CREATE POLICY "Posts are viewable by everyone" ON posts FOR SELECT USING (true);
CREATE POLICY "Only admins/publishers can insert posts" ON posts FOR INSERT WITH CHECK (can_publish());
CREATE POLICY "Only admins/publishers can update posts" ON posts FOR UPDATE USING (can_publish());

-- Post Reactions
CREATE POLICY "Reactions are viewable by everyone" ON post_reactions FOR SELECT USING (true);
CREATE POLICY "Users can insert their own reactions" ON post_reactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own reactions" ON post_reactions FOR DELETE USING (auth.uid() = user_id);

-- Comments
CREATE POLICY "Comments are viewable by everyone" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can insert their own comments" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own comments" ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own comments" ON comments FOR DELETE USING (auth.uid() = user_id);

-- Bookmarks
CREATE POLICY "Bookmarks viewable by owner" ON bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own bookmarks" ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own bookmarks" ON bookmarks FOR DELETE USING (auth.uid() = user_id);

-- Conversations
CREATE POLICY "Conversations viewable by participants" ON conversations FOR SELECT USING (
    EXISTS (SELECT 1 FROM participants WHERE conversation_id = id AND user_id = auth.uid())
);
CREATE POLICY "Any authenticated user can create a conversation" ON conversations FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Participants
CREATE POLICY "Participants viewable by conversation members" ON participants FOR SELECT USING (
    EXISTS (SELECT 1 FROM participants p2 WHERE p2.conversation_id = conversation_id AND p2.user_id = auth.uid())
);
CREATE POLICY "Users can add participants to conversations they are in, or themselves" ON participants FOR INSERT WITH CHECK (
    auth.uid() = user_id OR 
    EXISTS (SELECT 1 FROM participants p2 WHERE p2.conversation_id = conversation_id AND p2.user_id = auth.uid())
);

-- Messages
CREATE POLICY "Messages viewable by participants" ON messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM participants WHERE conversation_id = messages.conversation_id AND user_id = auth.uid())
);
CREATE POLICY "Participants can send messages" ON messages FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (SELECT 1 FROM participants WHERE conversation_id = messages.conversation_id AND user_id = auth.uid())
);

-- Spaces
CREATE POLICY "Spaces are viewable by everyone" ON spaces FOR SELECT USING (true);
CREATE POLICY "Only admins/publishers can create spaces" ON spaces FOR INSERT WITH CHECK (can_publish());
CREATE POLICY "Hosts can update their spaces" ON spaces FOR UPDATE USING (auth.uid() = host_id OR is_admin());

-- Space Participants
CREATE POLICY "Space participants viewable by everyone" ON space_participants FOR SELECT USING (true);
CREATE POLICY "Users can join spaces" ON space_participants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own participation" ON space_participants FOR UPDATE USING (auth.uid() = user_id);

-- Notifications
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System inserts notifications (bypasses RLS)" ON notifications FOR INSERT WITH CHECK (false); -- Handled by triggers/functions
CREATE POLICY "Users can update their own notifications (read)" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- Post Views (Analytics)
CREATE POLICY "Users can insert their own views" ON post_views FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Only admins can read all views" ON post_views FOR SELECT USING (is_admin());

-- Feature Flags
CREATE POLICY "Feature flags are viewable by everyone" ON feature_flags FOR SELECT USING (true);
CREATE POLICY "Only admins can manage feature flags" ON feature_flags FOR ALL USING (is_admin());
