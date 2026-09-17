import React, { useState, useEffect } from 'react';
import { collection, query, onSnapshot, deleteDoc, doc, updateDoc, addDoc, serverTimestamp, where } from 'firebase/firestore';
import { db, storage } from '../../lib/firebase';
import { ref,  } from 'firebase/storage';
import { Reel } from '../../types';
import { Trash2, Edit2, Play, Eye, Heart, Clock, AlertTriangle, Plus, Upload, Film } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';

export function ReelsManagement() {
  const [reels, setReels] = useState<Reel[]>([]);
  const [loading, setLoading] = useState(true);
  const [rulesError, setRulesError] = useState<string | null>(null);
  const [editingReel, setEditingReel] = useState<Reel | null>(null);
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [newReelTitle, setNewReelTitle] = useState('');
  const [newReelDesc, setNewReelDesc] = useState('');
  const [newReelVideoUrl, setNewReelVideoUrl] = useState('');
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [isUploading, setIsUploading] = useState(false);
  const { appUser } = useAuth();

  useEffect(() => {
    const q = query(collection(db, 'posts'), where('category', '==', 'Reel'), where('status', '==', 'approved'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetchedReels = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          ...data,
          likes: data.likesCount || 0,
          views: data.views || 0,
          watchTimeSeconds: data.watchTimeSeconds || 0
        };
      }) as Reel[];
      setReels(fetchedReels);
      setLoading(false);
    }, (error: any) => {
      if (error?.code !== 'permission-denied') console.error("Error fetching reels:", error);
      if (error?.code === 'unavailable') {
        setRulesError("Could not connect to Firebase (Network Unavailable). This usually means either your ad-blocker/VPN is blocking the connection, your Firebase Project ID is incorrect, or you haven't clicked 'Create Database' for Firestore in your Firebase Console yet.");
      } else if (error?.code === 'permission-denied') {
        setRulesError("Firestore Permission Denied. Please ensure your Firebase Security Rules allow access to the 'posts' collection. To fix this quickly for testing, go to the Firebase Console -> Firestore Database -> Rules and set: `allow read, write: if true;`");
      }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

    const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!appUser) return;
    
    if (!videoFile && !newReelVideoUrl) {
      alert("Please select a video file or provide a URL.");
      return;
    }
    
    setIsUploading(true);
    try {
      let finalVideoUrl = newReelVideoUrl;
      
      if (videoFile) {
        await new Promise<void>((resolve, reject) => {
          const xhr = new XMLHttpRequest();
          xhr.open('POST', 'https://api.cloudinary.com/v1_1/esz1cz8a/video/upload');
          
          xhr.upload.onprogress = (e) => {
            if (e.lengthComputable) {
              setUploadProgress((e.loaded / e.total) * 100);
            }
          };
          
          xhr.onload = () => {
            if (xhr.status >= 200 && xhr.status < 300) {
              const data = JSON.parse(xhr.responseText);
              finalVideoUrl = data.secure_url;
              resolve();
            } else {
              reject(new Error('Upload failed with status: ' + xhr.status));
            }
          };
          
          xhr.onerror = () => reject(new Error('Upload failed'));
          
          const formData = new FormData();
          formData.append('file', videoFile);
          formData.append('upload_preset', 'x7abc123');
          
          xhr.send(formData);
        });
      }
    
      await addDoc(collection(db, 'posts'), {
        title: newReelTitle,
        description: newReelDesc || "",
        videoUrl: finalVideoUrl || 'https://www.w3schools.com/html/mov_bbb.mp4',
        imageUrl: '',
        authorId: appUser.uid,
        category: 'Reel',
        status: 'approved',
        createdAt: serverTimestamp(),
        likesCount: 0,
        views: 0,
        watchTimeSeconds: 0,
        commentsCount: 0,
        likedBy: [],
        bookmarkedBy: []
      });
      
      setShowUploadModal(false);
      setNewReelTitle('');
      setNewReelDesc('');
      setNewReelVideoUrl('');
      setVideoFile(null);
      setUploadProgress(0);
    } catch (err: any) {
      console.error("Failed to upload reel", err);
      alert("Failed to upload reel: " + (err.message || err));
    } finally {
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  const handleFileDrop = (e: React.DragEvent) => {
    e.preventDefault();
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      if (file.type.startsWith('video/')) {
        setVideoFile(file);
      } else {
        alert('Please drop a valid video file.');
      }
    }
  };
  
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
  };

  
  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this reel?')) {
      await deleteDoc(doc(db, 'posts', id));
    }
  };

  return (
    <div className="space-y-6 pb-12">
      <div className="flex justify-between items-end mb-6">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Reels Management</h2>
          <p className="text-[#8B8B98] text-sm mt-1">Manage and track your short-form video content.</p>
        </div>
        <button 
          onClick={() => setShowUploadModal(true)}
          className="flex items-center gap-2 px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
        >
          <Plus className="w-4 h-4" /> Add Reel
        </button>
      </div>

      <div className="flex gap-4 items-center">
        <div className="flex bg-[#15151C] border border-white/5 rounded-lg p-1">
           <button className="px-4 py-1.5 rounded-md bg-white/10 text-white text-sm font-medium">Published</button>
           <button className="px-4 py-1.5 rounded-md text-[#8B8B98] hover:text-white text-sm font-medium transition-colors">Draft</button>
           <button className="px-4 py-1.5 rounded-md text-[#8B8B98] hover:text-white text-sm font-medium transition-colors">Scheduled</button>
        </div>
      </div>

      {rulesError && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 flex gap-4 text-red-400">
          <AlertTriangle className="w-5 h-5 flex-shrink-0" />
          <p className="text-sm leading-relaxed">{rulesError}</p>
        </div>
      )}

      {loading ? (
        <div className="text-[#8B8B98]">Loading reels...</div>
      ) : reels.length === 0 ? (
        <div className="bg-[#15151C] rounded-2xl border border-white/5 p-12 flex flex-col items-center justify-center text-center">
          <div className="w-16 h-16 bg-white/5 rounded-full flex items-center justify-center mb-4">
            <Film className="w-8 h-8 text-[#8B8B98]" />
          </div>
          <h3 className="text-xl font-bold text-white mb-2">No reels yet</h3>
          <p className="text-[#8B8B98] text-sm max-w-md mb-6">
            Upload your first reel to start tracking performance.
          </p>
          <button 
            onClick={() => setShowUploadModal(true)}
            className="flex items-center gap-2 px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
          >
            <Plus className="w-4 h-4" /> Add Reel
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
          {reels.map(reel => (
            <div key={reel.id} className="bg-[#15151C] border border-white/5 rounded-xl overflow-hidden group hover:border-white/10 transition-all hover:-translate-y-1 hover:shadow-2xl flex flex-col relative">
              <div className="aspect-[9/16] bg-[#0B0B0F] relative overflow-hidden">
                 {reel.thumbnailUrl || reel.imageUrl ? (
                   <img src={reel.thumbnailUrl || reel.imageUrl} alt={reel.title} className="w-full h-full object-cover" />
                 ) : reel.videoUrl ? (
                   <video src={reel.videoUrl} className="w-full h-full object-cover" preload="metadata" />
                 ) : (
                   <div className="w-full h-full flex items-center justify-center"><Film className="w-8 h-8 text-white/10" /></div>
                 )}
                 <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col justify-center items-center gap-3 backdrop-blur-sm">
                    <button className="px-4 py-2 bg-white/20 hover:bg-white/30 text-white rounded-lg text-sm font-medium transition-colors w-28 text-center backdrop-blur-md">Preview</button>
                    <button onClick={() => setEditingReel(reel)} className="px-4 py-2 bg-white/20 hover:bg-white/30 text-white rounded-lg text-sm font-medium transition-colors w-28 text-center backdrop-blur-md">Edit</button>
                    <button onClick={() => handleDelete(reel.id)} className="px-4 py-2 bg-red-500/80 hover:bg-red-500 text-white rounded-lg text-sm font-medium transition-colors w-28 text-center backdrop-blur-md">Delete</button>
                 </div>
                 <div className="absolute top-2 right-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded bg-emerald-500/90 text-white">
                      Published
                    </span>
                 </div>
              </div>
              <div className="p-4 flex flex-col flex-1">
                 <h3 className="text-white font-bold text-sm leading-tight mb-1 line-clamp-1">{reel.title || 'Untitled Reel'}</h3>
                 <div className="text-[#8B8B98] text-xs flex items-center gap-1 mb-3">
                    <span>{new Date(reel.createdAt?.toMillis?.() || Date.now()).toLocaleDateString()}</span>
                 </div>
                 
                 <div className="mt-auto flex items-center justify-between text-[#8B8B98] text-xs">
                    <span className="flex items-center gap-1"><Eye className="w-3.5 h-3.5"/> {reel.views || 0}</span>
                    <span className="flex items-center gap-1"><Heart className="w-3.5 h-3.5"/> {reel.likes || 0}</span>
                    <span className="flex items-center gap-1"><Clock className="w-3.5 h-3.5"/> {Math.round((reel.watchTimeSeconds || 0)/60)}m</span>
                 </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Editing Modal */}
      {editingReel && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#15151C] border border-white/10 rounded-xl p-6 w-full max-w-lg shadow-2xl">
            <h2 className="text-xl font-bold text-white mb-6">Edit Reel</h2>
            <form onSubmit={(e) => { e.preventDefault(); }} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Title</label>
                <input 
                  type="text" 
                  value={editingReel.title}
                  onChange={(e) => setEditingReel({...editingReel, title: e.target.value})}
                  className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:border-red-500 text-sm transition-colors"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Description</label>
                <textarea 
                  value={editingReel.description || ''}
                  onChange={(e) => setEditingReel({...editingReel, description: e.target.value})}
                  className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:border-red-500 text-sm transition-colors resize-none h-24"
                />
              </div>
              <div className="flex gap-3 mt-6">
                <button 
                  type="button"
                  onClick={() => setEditingReel(null)}
                  className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  className="flex-1 px-4 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Upload Modal */}
      {showUploadModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#15151C] border border-white/10 rounded-xl p-6 w-full max-w-lg shadow-2xl">
            <h2 className="text-xl font-bold text-white mb-6">Upload New Reel</h2>
            <form onSubmit={handleUpload} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Title</label>
                <input 
                  type="text" 
                  value={newReelTitle}
                  onChange={(e) => setNewReelTitle(e.target.value)}
                  className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:border-red-500 text-sm transition-colors"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">Video File (9:16)</label>
                <div className="w-full border-2 border-dashed border-white/20 rounded-xl bg-[#0B0B0F] hover:bg-white/5 transition-colors p-6 text-center cursor-pointer" onClick={() => document.getElementById('video-upload')?.click()}>
                  <input id="video-upload" type="file" accept="video/mp4,video/webm" className="hidden" onChange={(e) => { if (e.target.files && e.target.files[0]) setVideoFile(e.target.files[0]); }} />
                  {videoFile ? (
                    <div className="text-white text-sm">{videoFile.name}</div>
                  ) : (
                    <div>
                      <Upload className="w-8 h-8 text-[#8B8B98] mx-auto mb-2" />
                      <p className="text-white text-sm">Click to upload video</p>
                      <p className="text-[#8B8B98] text-xs mt-1">MP4 or WebM (Max 50MB)</p>
                    </div>
                  )}
                  {uploadProgress > 0 && <div className="mt-4 h-1 bg-[#252533] rounded-full overflow-hidden"><div className="h-full bg-red-500" style={{width: `${uploadProgress}%`}}></div></div>}
                </div>
              </div>
              <div className="mt-2 text-center text-xs text-[#8B8B98]">OR</div>
              <div>
                <label className="block text-sm font-medium text-[#8B8B98] mb-1.5">External Video URL</label>
                <input type="url" value={newReelVideoUrl} onChange={(e) => setNewReelVideoUrl(e.target.value)} className="w-full bg-[#0B0B0F] border border-white/10 rounded-lg px-4 py-2.5 text-white focus:outline-none focus:border-red-500 text-sm transition-colors" disabled={!!videoFile} />
              </div>
              <div className="flex gap-3 mt-6">
                <button type="button" onClick={() => setShowUploadModal(false)} className="flex-1 px-4 py-2.5 bg-white/5 hover:bg-white/10 text-white rounded-lg text-sm font-medium transition-colors">Cancel</button>
                <button type="submit" disabled={isUploading} className="flex-1 px-4 py-2.5 bg-red-500 hover:bg-red-600 disabled:opacity-50 text-white rounded-lg text-sm font-medium transition-colors">
                  {isUploading ? 'Uploading...' : 'Upload Reel'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );

}