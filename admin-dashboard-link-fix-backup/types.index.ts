export interface Stream {
  id: string;
  title: string;
  description: string;
  roomName: string;
  presenterId: string;
  status: 'scheduled' | 'live' | 'ended';
  startedAt: any; // Firestore Timestamp
  endedAt: any;
  createdAt: any;
  starredBy?: string[];
}

export interface Comment {
  id: string;
  userId: string;
  username: string;
  message: string;
  createdAt: any;
  starredBy?: string[]; // Firestore Timestamp
  isDeleted: boolean;
}

export interface AppUser {
  uid: string;
  name: string;
  email: string;
  role: string;
}

export interface Reel {
  id: string;
  title: string;
  description?: string;
  videoUrl: string;
  thumbnailUrl?: string;
  imageUrl?: string;
  creatorId?: string;
  authorId?: string;
  createdAt: any;
  starredBy?: string[]; // Firestore Timestamp
  views?: number;
  likes?: number;
  likesCount?: number;
  watchTimeSeconds?: number;
}

export interface NormalizedFacts {
  mainEvent: string;
  companies: string[];
  people: string[];
  numbers: { value: string; label: string }[];
  dates: { date: string; event: string }[];
  locations: string[];
  products: string[];
  investors: string[];
  quotes: { text: string; speaker: string }[];
  timelineEvents: { date: string; event: string }[];
  implications: string[];
}

export interface QuickBriefContent {
  category: string;
  headline: string;
  quick_summary: string;
  three_things_to_know: string[];
  key_number: { value: string; label: string } | null;
}

export interface FullArticleContent {
  headline?: string;
  hook?: string;
  whatHappened?: string;
  what_happened?: string;
  key_numbers?: { value: string; label: string }[];
  keyNumbers?: { value: string; label: string }[];
  whyThisMatters?: string;
  why_this_matters?: string;
  biggerPicture?: string;
  bigger_picture?: string;
  takeaways?: string[];
  keySections?: { heading: string; content: string }[];
  key_sections?: { heading: string; content: string }[];
  explore_sections?: any[];
  exploreSections?: any[];
  quote?: { text: string; author?: string; speaker?: string } | null;
}

export interface Article {
  id: string;
  title?: string;
  description?: string;
  coverImage?: string;
  thumbnailUrl?: string;
  imageUrl?: string;
  mediaUrls?: string[];
  authorId?: string;
  authorName?: string;
  readTime?: number;
  status: 'draft' | 'processing' | 'review' | 'approved' | 'published' | 'scheduled';
  createdAt: any;
  updatedAt?: any;
  publishedAt?: any;
  views?: number;
  likes?: number;
  saves?: number;
  commentsCount?: number;
  
  isFeatured?: boolean;
  isTodaysDrop?: boolean;
  deckPriority?: number;
  
  facts?: NormalizedFacts;
  quick_brief?: QuickBriefContent;
  full_article?: FullArticleContent;
  explore_sections?: any[];

  // Legacy fields to not break existing data immediately
  category?: string;
  headline?: string;
  hook?: string;
  whatHappened?: string;
  whyThisMatters?: string;
  keySections?: { heading: string; content: string }[];
  numbersThatMatter?: { value: string; label: string }[];
  biggerPicture?: string;
  youNowKnow?: string[];
}
