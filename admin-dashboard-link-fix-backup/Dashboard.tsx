import React, { useState, useEffect } from 'react';
import { signOut } from 'firebase/auth';
import { collection, query, where, onSnapshot, addDoc, serverTimestamp, deleteDoc, doc, updateDoc, arrayUnion, arrayRemove } from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import { useAuth } from '../hooks/useAuth';
import { Stream } from '../types';
import { Video, Plus, Clock, Camera, AlertTriangle, Trash2, Star } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { v4 as uuidv4 } from 'uuid';
import { ReelsManagement } from '../components/dashboard/ReelsManagement';
import { DashboardOverview } from '../components/dashboard/DashboardOverview';
import { ArticlesManagement } from '../components/dashboard/ArticlesManagement';
import { Analytics } from '../components/dashboard/Analytics';

export function Dashboard({ initialTab = 'overview' }: { initialTab?: 'overview' | 'streams' | 'reels' | 'articles' | 'analytics' }) {
  const { appUser } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate('/');
    } catch (error) {
      console.error("Failed to log out", error);
    }
  };

  const [activeStream, setActiveStream] = useState<Stream | null>(null);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [creating, setCreating] = useState(false);
  const [rulesError, setRulesError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'streams' | 'reels' | 'articles' | 'analytics'>(initialTab);
  
  useEffect(() => {
    setActiveTab(initialTab);
  }, [initialTab]);

  useEffect(() => {
    if (!appUser) return;
    
    // Listen for streams that are scheduled or live
    const q = query(
      collection(db, 'liveStreams'), 
      where('status', 'in', ['scheduled', 'live'])
    );
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      if (!snapshot.empty) {
        // Just take the first active stream for this simple dashboard
        const doc = snapshot.docs[0];
        setActiveStream({ id: doc.id, ...doc.data() } as Stream);
      } else {
        setActiveStream(null);
      }
      setRulesError(null);
      setLoading(false);
    }, (error: any) => {
      if (error?.code !== 'permission-denied') console.error("Firestore error:", error);
      if (error?.code === 'permission-denied') {
        setRulesError("Firestore Permission Denied. Please ensure your Firebase Security Rules allow access to the 'liveStreams' collection.");
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, [appUser]);

  const handleCreateStream = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!appUser || !title.trim()) return;
    
    setCreating(true);
    const roomName = uuidv4();
    
    try {
      await addDoc(collection(db, 'liveStreams'), {
        title,
        description,
        roomName,
        presenterId: appUser.uid,
        status: 'scheduled',
        createdAt: serverTimestamp(),
      });
      setShowCreateModal(false);
      setTitle('');
      setDescription('');
    } catch (error) {
      console.error("Error creating stream:", error);
      alert("Failed to create stream");
    } finally {
      setCreating(false);
    }
  };

  const handleDeleteStream = async () => {
    if (!activeStream || !confirm("Are you sure you want to delete this stream?")) return;
    try {
      await deleteDoc(doc(db, 'liveStreams', activeStream.id));
    } catch (error) {
      console.error("Error deleting stream:", error);
    }
  };

  const handleStarStream = async () => {
     if (!activeStream || !appUser) return;
     try {
       const isStarred = activeStream.starredBy?.includes(appUser.uid);
       await updateDoc(doc(db, 'liveStreams', activeStream.id), {
         starredBy: isStarred ? arrayRemove(appUser.uid) : arrayUnion(appUser.uid)
       });
     } catch(err) {
       console.error("Failed to star stream", err);
     }
  };

  const renderContent = () => {
    switch (activeTab) {
      case 'overview':
        return <DashboardOverview onNavigate={setActiveTab} />;
      case 'reels':
        return <ReelsManagement />;
      case 'articles':
        return <ArticlesManagement />;
      case 'analytics':
        return <Analytics />;
      case 'streams':
      default:
        return renderStreams();
    }
  };

  const renderStreams = () => (
    <div className="space-y-6 pb-12">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Live Streams</h2>
          <p className="text-[#8B8B98] text-sm mt-1">Manage your active and scheduled broadcasts.</p>
        </div>
        {!activeStream && (
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Plus className="w-4 h-4" /> Start New Stream
          </button>
        )}
      </div>

      {rulesError && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 flex gap-4 text-red-400">
          <AlertTriangle className="w-5 h-5 flex-shrink-0" />
          <p className="text-sm leading-relaxed">{rulesError}</p>
        </div>
      )}

      {!activeStream ? (
        <div className="bg-[#15151C] rounded-xl border border-white/5 p-12 flex flex-col items-center justify-center text-center">
          <div className="w-16 h-16 bg-white/5 rounded-full flex items-center justify-center mb-4">
            <Camera className="w-8 h-8 text-[#8B8B98]" />
          </div>
          <h3 className="text-xl font-bold text-white mb-2">No Active Stream</h3>
          <p className="text-[#8B8B98] text-sm max-w-md mb-6">
            You don't have any scheduled or live streams at the moment.
          </p>
          <button 
            onClick={() => setShowCreateModal(true)}
            className="flex items-center gap-2 px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg font-medium transition-colors"
          >
            <Plus className="w-4 h-4" /> Start Broadcasting
          </button>
        </div>
      ) : (
        <div className="bg-[#15151C] rounded-xl border border-white/5 overflow-hidden">
          <div className="aspect-[21/9] bg-[#0B0B0F] relative flex flex-col items-center justify-center border-b border-white/5">
             <div className="absolute top-4 left-4 flex items-center gap-2">
                {activeStream.status === 'live' ? (
                  <span className="flex items-center gap-2 px-3 py-1 bg-red-500/10 text-red-500 rounded-full text-xs font-semibold border border-red-500/20">
                    <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"></span>
                    LIVE NOW
                  </span>
                ) : (
                  <span className="flex items-center gap-2 px-3 py-1 bg-blue-500/10 text-blue-400 rounded-full text-xs font-semibold border border-blue-500/20">
                    <Clock className="w-3 h-3" />
                    SCHEDULED
                  </span>
                )}
             </div>
             
             <div className="text-center">
               <Video className="w-12 h-12 text-white/10 mx-auto mb-4" />
               <h3 className="text-2xl font-bold text-white mb-2">{activeStream.title}</h3>
               <p className="text-[#8B8B98] max-w-md mx-auto text-sm">{activeStream.description}</p>
             </div>
          </div>
          
          <div className="p-6">
             <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex gap-6">
                   <div>
                     <p className="text-[#8B8B98] text-xs font-medium uppercase tracking-wider mb-1">Status</p>
                     <p className="text-white font-medium capitalize">{activeStream.status}</p>
                   </div>
                   <div>
                     <p className="text-[#8B8B98] text-xs font-medium uppercase tracking-wider mb-1">Room ID</p>
                     <p className="text-white font-medium font-mono text-sm">{activeStream.roomName}</p>
                   </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <button 
                    onClick={() => navigate(`/studio/${activeStream.id}`)}
                    className="px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white font-medium rounded-lg transition-colors flex items-center gap-2 text-sm"
                  >
                    {activeStream.status === 'live' ? 'Resume Broadcast' : 'Enter Studio'}
                  </button>
                  <div className="h-8 w-px bg-white/10 mx-2"></div>
                  <button 
                    onClick={handleDeleteStream}
                    className="p-2.5 text-[#8B8B98] hover:text-red-500 hover:bg-white/5 rounded-lg transition-colors"
                    title="Delete Stream"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
             </div>
          </div>
        </div>
      )}

      {showCreateModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#15151C] border border-white/10 rounded-2xl p-8 w-full max-w-md shadow-2xl">
            <h2 className="text-xl font-bold text-white mb-6">Create Live Stream</h2>
            <form onSubmit={handleCreateStream} className="space-y-5">
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Stream Title</label>
                <input 
                  type="text" 
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-red-500 text-sm transition-colors"
                  placeholder="e.g. Weekly Q&A Session"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Description (Optional)</label>
                <textarea 
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-red-500 text-sm transition-colors resize-none h-24"
                  placeholder="What will you be discussing?"
                />
              </div>
              <div className="flex gap-3 mt-8">
                <button 
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  disabled={creating}
                  className="flex-1 px-4 py-2.5 bg-red-500 hover:bg-red-600 disabled:bg-red-500/50 text-white rounded-lg text-sm font-medium transition-colors"
                >
                  {creating ? 'Creating...' : 'Create Stream'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <div className="max-w-[1400px] mx-auto h-full flex flex-col">
      {/* Secondary Navigation */}
      <div className="flex border-b border-white/5 mb-8 overflow-x-auto hide-scrollbar shrink-0">
        {[
          { id: 'overview', label: 'Overview' },
          { id: 'streams', label: 'Live Streams' },
          { id: 'reels', label: 'Reels Management' },
          { id: 'articles', label: 'Articles Management' },
          { id: 'analytics', label: 'App Analytics' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => navigate(tab.id === 'overview' ? '/' : `/${tab.id}`)}
            className={`px-6 py-4 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${
              activeTab === tab.id 
                ? 'border-red-500 text-white' 
                : 'border-transparent text-[#8B8B98] hover:text-white hover:border-white/20'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Main Content Area */}
      <div className="flex-1 min-w-0">
        {renderContent()}
      </div>
    </div>
  );
}
