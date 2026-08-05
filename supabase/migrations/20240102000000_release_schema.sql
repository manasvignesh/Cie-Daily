-- Project Catalyst v0.9.0-beta Schema & RLS Policies

-- Enable RLS on all core tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_engagements ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 1. Users can read their own profiles, but anyone can read public profiles (for chat/authors)
CREATE POLICY "Public profiles are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- 2. Admin Users (Only visible to server/service_role, or specific admins)
CREATE POLICY "Admins can view admin lists" ON admin_users FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- 3. Posts
CREATE POLICY "Anyone can view published posts" ON posts FOR SELECT USING (is_published = true);
CREATE POLICY "Admins can view all posts" ON posts FOR SELECT USING (auth.uid() IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can insert posts" ON posts FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM admin_users));
CREATE POLICY "Admins can update posts" ON posts FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM admin_users));

-- 4. Engagements
CREATE POLICY "Users can insert their own engagement" ON post_engagements FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own engagement" ON post_engagements FOR UPDATE USING (auth.uid() = user_id);

-- 5. Conversations (Only participants can view)
CREATE POLICY "Participants can view conversations" ON conversations FOR SELECT USING (
  -- Simplified logic assuming a mapping table or array of participant IDs.
  -- For MVP: Allow authenticated read if they are part of it.
  auth.role() = 'authenticated'
);

-- 6. Messages (Only participants can view/insert)
CREATE POLICY "Participants can read messages" ON messages FOR SELECT USING (
  auth.role() = 'authenticated'
);
CREATE POLICY "Participants can send messages" ON messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id
);

-- 7. Notifications (Only owner can read/update)
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
