import React, { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { Article } from '../../types';
import { FileText, Plus, MoreVertical, Search, Filter, Clock, Eye, MessageSquare, Heart, Trash2, GripVertical, Bookmark } from 'lucide-react';
import { ArticleEditorFlow } from './articles/ArticleEditorFlow';

export function ArticlesManagement() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [showEditor, setShowEditor] = useState(false);
  const [search, setSearch] = useState('');
  const [activeFilter, setActiveFilter] = useState('All');

  useEffect(() => {
    // Subscribe to all posts and filter out reels client-side to prevent Firestore inequality index issues
    const q = collection(db, 'posts');
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const fetched = snapshot.docs
        .map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            ...data,
            category: data.category || data.quick_brief?.category || 'Article',
            headline: data.headline || data.title || data.quick_brief?.headline || data.full_article?.headline || 'Untitled Article',
            hook: data.hook || data.description || data.quick_brief?.quick_summary || data.full_article?.hook || data.whatHappened || '',
            coverImage: data.coverImage || data.thumbnailUrl || data.imageUrl || (data.mediaUrls && data.mediaUrls[0]) || '',
            status: data.status || 'approved', // default to published for legacy
          };
        })
        .filter(item => item.category !== 'Reel') as Article[];

      // Client-side sort by createdAt descending
      const sorted = fetched.sort((a, b) => {
        const timeA = a.createdAt?.toMillis?.() || (a.createdAt?.seconds ? a.createdAt.seconds * 1000 : 0) || 0;
        const timeB = b.createdAt?.toMillis?.() || (b.createdAt?.seconds ? b.createdAt.seconds * 1000 : 0) || 0;
        return timeB - timeA;
      });

      setArticles(sorted);
      setLoading(false);
    }, (err) => {
      console.error("Error fetching articles:", err);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure you want to delete this article?')) {
      await deleteDoc(doc(db, 'posts', id));
    }
  };

  const filtered = articles.filter(a => {
    const matchesSearch = (a.headline?.toLowerCase().includes(search.toLowerCase()) || a.authorName?.toLowerCase().includes(search.toLowerCase()));
    
    let matchesFilter = true;
    if (activeFilter !== 'All') {
      if (activeFilter === 'Featured') matchesFilter = !!a.isFeatured;
      else if (activeFilter === 'Published') matchesFilter = a.status === 'approved';
      else matchesFilter = a.status.toLowerCase() === activeFilter.toLowerCase();
    }
    
    return matchesSearch && matchesFilter;
  });

  const featuredArticles = articles.filter(a => a.isFeatured && a.status === 'approved').slice(0, 5);

  return (
    <div className="space-y-8 pb-12">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Articles Management</h2>
          <p className="text-[#8B8B98] text-sm mt-1">Create, review and publish structured stories.</p>
        </div>
        <button 
          onClick={() => setShowEditor(true)}
          className="flex items-center gap-2 px-6 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors"
        >
          <Plus className="w-4 h-4" /> New Article
        </button>
      </div>

      <div className="flex flex-col lg:flex-row gap-8">
         <div className="flex-1 space-y-6">
            <div className="flex gap-4 items-center">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-[#8B8B98]" />
                <input 
                  type="text" 
                  placeholder="Search articles..." 
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full bg-[#15151C] border border-white/5 rounded-lg pl-10 pr-4 py-2.5 text-sm text-white focus:outline-none focus:border-red-500 transition-colors"
                />
              </div>
              <div className="flex bg-[#15151C] border border-white/5 rounded-lg overflow-x-auto hide-scrollbar">
                 {['All', 'Draft', 'Processing', 'Review', 'Published', 'Scheduled', 'Featured'].map(f => (
                    <button 
                      key={f}
                      onClick={() => setActiveFilter(f)}
                      className={`px-4 py-2.5 text-sm font-medium whitespace-nowrap transition-colors ${activeFilter === f ? 'bg-white/10 text-white' : 'text-[#8B8B98] hover:text-white'}`}
                    >
                      {f}
                    </button>
                 ))}
              </div>
            </div>

            {loading ? (
              <div className="text-[#8B8B98]">Loading articles...</div>
            ) : filtered.length === 0 ? (
              <div className="bg-[#15151C] rounded-2xl border border-white/5 p-12 flex flex-col items-center justify-center text-center">
                <div className="w-16 h-16 bg-white/5 rounded-full flex items-center justify-center mb-4">
                  <FileText className="w-8 h-8 text-[#8B8B98]" />
                </div>
                <h3 className="text-xl font-bold text-white mb-2">No articles found.</h3>
                <p className="text-[#8B8B98] text-sm max-w-md">
                  Create your first article or try a different filter.
                </p>
              </div>
            ) : (
              <div className="space-y-3">
                {filtered.map(article => (
                  <div key={article.id} className="bg-[#15151C] border border-white/5 rounded-xl p-4 flex gap-5 group hover:border-white/10 transition-colors">
                     <div className="w-48 aspect-video bg-[#0B0B0F] rounded-lg relative overflow-hidden shrink-0">
                       {article.coverImage ? (
                         <img src={article.coverImage} className="w-full h-full object-cover" />
                       ) : (
                         <div className="w-full h-full flex items-center justify-center"><FileText className="w-6 h-6 text-white/10" /></div>
                       )}
                       {article.isFeatured && (
                         <div className="absolute top-2 right-2 px-2 py-0.5 bg-red-500 text-white text-[10px] font-bold uppercase rounded shadow-sm flex items-center gap-1">
                           <Bookmark className="w-3 h-3" /> Featured
                         </div>
                       )}
                     </div>
                     <div className="flex-1 min-w-0 flex flex-col">
                        <div className="flex justify-between items-start mb-1">
                           <span className="text-red-500 font-bold text-[10px] uppercase tracking-widest">{article.category || article.quick_brief?.category || 'ARTICLE'}</span>
                           <div className="flex items-center gap-3 text-xs text-[#8B8B98]">
                              <span className={`px-2 py-1 rounded capitalize font-medium ${
                                article.status === 'approved' ? 'bg-emerald-500/10 text-emerald-400' :
                                article.status === 'review' ? 'bg-amber-500/10 text-amber-400' :
                                'bg-white/10 text-white'
                              }`}>
                                {article.status === 'approved' ? 'Published' : article.status}
                              </span>
                              <button className="hover:text-white"><MoreVertical className="w-4 h-4" /></button>
                           </div>
                        </div>
                        <h3 className="text-white font-bold text-lg leading-tight mb-2 truncate">
                           {article.headline || article.quick_brief?.headline || article.full_article?.headline || 'Untitled'}
                        </h3>
                        <p className="text-[#8B8B98] text-sm line-clamp-2 mb-3">
                           {article.hook || article.quick_brief?.quick_summary || article.full_article?.hook || ''}
                        </p>
                        <div className="mt-auto flex items-center justify-between text-xs text-[#8B8B98]">
                           <div className="flex items-center gap-3">
                             <span>{article.authorName || 'Admin'}</span>
                             <span>•</span>
                             <span>{new Date(article.createdAt?.toMillis?.() || Date.now()).toLocaleDateString()}</span>
                           </div>
                           <div className="flex gap-4">
                              <span className="flex items-center gap-1"><Eye className="w-3.5 h-3.5"/> {article.views || 0}</span>
                              <span className="flex items-center gap-1"><MessageSquare className="w-3.5 h-3.5"/> {article.commentsCount || 0}</span>
                              <button onClick={() => handleDelete(article.id)} className="hover:text-red-500 transition-colors opacity-0 group-hover:opacity-100 ml-2">
                                <Trash2 className="w-4 h-4" />
                              </button>
                           </div>
                        </div>
                     </div>
                  </div>
                ))}
              </div>
            )}
         </div>

         {/* Featured Briefs Management */}
         <div className="w-full lg:w-80 shrink-0">
            <div className="bg-[#15151C] border border-white/5 rounded-xl p-5 sticky top-24">
               <h3 className="text-white font-bold mb-1 flex items-center gap-2">
                  <Bookmark className="w-4 h-4 text-red-500" /> Featured Briefs
               </h3>
               <p className="text-[#8B8B98] text-xs mb-4">Drag to reorder Discover swipe deck (Max 5 active).</p>
               
               <div className="space-y-2">
                  {featuredArticles.map((fa, i) => (
                     <div key={fa.id} className="bg-[#0B0B0F] border border-white/5 rounded-lg p-3 flex gap-3 items-center group cursor-grab">
                        <GripVertical className="w-4 h-4 text-[#8B8B98] opacity-50 group-hover:opacity-100" />
                        <span className="text-white/30 text-xs font-mono">{i + 1}</span>
                        <div className="flex-1 min-w-0">
                           <div className="text-white text-xs font-medium truncate">{fa.quick_brief?.headline || fa.headline}</div>
                        </div>
                     </div>
                  ))}
                  {featuredArticles.length === 0 && (
                     <div className="text-[#8B8B98] text-xs text-center py-4 border border-dashed border-white/10 rounded-lg">
                       No featured articles.
                     </div>
                  )}
               </div>
            </div>
         </div>
      </div>

      {showEditor && (
        <ArticleEditorFlow 
          onClose={() => setShowEditor(false)} 
          onSaved={() => setShowEditor(false)}
        />
      )}
    </div>
  );
}
