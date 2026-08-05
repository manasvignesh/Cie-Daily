-- Create ENUMs
CREATE TYPE user_role AS ENUM ('super_admin', 'content_manager', 'publisher', 'space_host', 'moderator', 'student');
CREATE TYPE post_category AS ENUM ('brain', 'technology', 'startup', 'event', 'campus', 'hackathon', 'announcement', 'tool', 'achievement');
CREATE TYPE reaction_type AS ENUM ('heart', 'fire', 'mindblown', 'clap');
CREATE TYPE bookmark_type AS ENUM ('post', 'space');
CREATE TYPE space_role AS ENUM ('host', 'speaker', 'listener');

-- Table: admin_users (Defines who gets routed to the Admin Dashboard)
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: users
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    department TEXT,
    year INTEGER,
    bio TEXT,
    avatar_url TEXT,
    role user_role DEFAULT 'student',
    is_verified BOOLEAN DEFAULT FALSE,
    is_banned BOOLEAN DEFAULT FALSE,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: posts
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category post_category NOT NULL,
    is_todays_drop BOOLEAN DEFAULT FALSE,
    author_id UUID REFERENCES users(id) ON DELETE CASCADE,
    headline TEXT NOT NULL,
    summary TEXT,
    blocks JSONB NOT NULL, -- Array of content blocks: { "type": "image", "url": "..." }, { "type": "quiz", ... }
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: post_reactions
CREATE TABLE post_reactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    reaction_type reaction_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Table: comments
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: bookmarks
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bookmark_type bookmark_type NOT NULL,
    item_id UUID NOT NULL, -- Generic ID, could be post_id or space_id
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(bookmark_type, item_id, user_id)
);

-- Table: conversations
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: participants
CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- Table: messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: spaces
CREATE TABLE spaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    thumbnail TEXT,
    host_id UUID REFERENCES users(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    max_participants INTEGER DEFAULT 100,
    livekit_room TEXT UNIQUE,
    is_live BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: space_participants
CREATE TABLE space_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    space_id UUID REFERENCES spaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    left_at TIMESTAMP WITH TIME ZONE,
    role space_role DEFAULT 'listener'
);

-- Table: notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL,
    related_id UUID, -- E.g., post_id, space_id
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: post_views
CREATE TABLE post_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    view_duration INTERVAL,
    scroll_depth INTEGER, -- E.g., percentage 0-100
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table: feature_flags
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    is_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert initial feature flags
INSERT INTO feature_flags (name, is_enabled) VALUES
('brain_enabled', TRUE),
('spaces_enabled', TRUE),
('comments_enabled', TRUE),
('todays_drop_enabled', TRUE);
