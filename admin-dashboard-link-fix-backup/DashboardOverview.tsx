import React, { useState, useEffect } from 'react';
import { collection, query, where, getDocs, limit, orderBy } from 'firebase/firestore';
import { db } from '../../lib/firebase';
import { Eye, FileText, Film, Users, TrendingUp, Clock, Plus, PlayCircle, Activity } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, ResponsiveContainer, Tooltip as RechartsTooltip } from 'recharts';

export function DashboardOverview({ onNavigate }: { onNavigate: (tab: string) => void }) {
  const [stats, setStats] = useState({
    views: 0, articles: 0, reels: 0, live: 0, engagement: 0, watchTime: 0
  });

  const chartData = [
    { name: 'Mon', views: 4000, engagement: 2400 },
    { name: 'Tue', views: 3000, engagement: 1398 },
    { name: 'Wed', views: 2000, engagement: 9800 },
    { name: 'Thu', views: 2780, engagement: 3908 },
    { name: 'Fri', views: 1890, engagement: 4800 },
    { name: 'Sat', views: 2390, engagement: 3800 },
    { name: 'Sun', views: 3490, engagement: 4300 },
  ];

  return (
    <div className="space-y-6 pb-12">
      <div className="flex justify-between items-center mb-2">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Dashboard Overview</h2>
          <p className="text-[#8B8B98] text-sm mt-1">Your media operations at a glance.</p>
        </div>
        <div className="flex gap-3">
          <button onClick={() => onNavigate('articles')} className="flex items-center gap-2 px-4 py-2 bg-[#15151C] hover:bg-[#1C1C24] text-white rounded-lg text-sm font-medium border border-white/5 transition-colors">
            <FileText className="w-4 h-4" /> New Article
          </button>
          <button onClick={() => onNavigate('reels')} className="flex items-center gap-2 px-4 py-2 bg-[#15151C] hover:bg-[#1C1C24] text-white rounded-lg text-sm font-medium border border-white/5 transition-colors">
            <Film className="w-4 h-4" /> Add Reel
          </button>
          <button onClick={() => onNavigate('streams')} className="flex items-center gap-2 px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg text-sm font-medium transition-colors">
            <PlayCircle className="w-4 h-4" /> Start Stream
          </button>
        </div>
      </div>

      {/* Top KPIs */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {[
          { label: 'Total Views', value: '1.2M', icon: Eye, color: 'text-blue-400', bg: 'bg-blue-400/10' },
          { label: 'Articles', value: '342', icon: FileText, color: 'text-emerald-400', bg: 'bg-emerald-400/10' },
          { label: 'Reel Views', value: '890K', icon: Film, color: 'text-purple-400', bg: 'bg-purple-400/10' },
          { label: 'Live Viewers', value: '24', icon: Users, color: 'text-red-400', bg: 'bg-red-400/10' },
          { label: 'Engagement', value: '12.4%', icon: TrendingUp, color: 'text-amber-400', bg: 'bg-amber-400/10' },
          { label: 'Avg Watch', value: '3m 12s', icon: Clock, color: 'text-cyan-400', bg: 'bg-cyan-400/10' },
        ].map((kpi, i) => (
          <div key={i} className="bg-[#15151C] rounded-xl border border-white/5 p-4 flex flex-col">
            <div className="flex justify-between items-start mb-4">
              <span className="text-[#8B8B98] text-xs font-medium uppercase tracking-wider">{kpi.label}</span>
              <div className={`p-1.5 rounded-lg ${kpi.bg} ${kpi.color}`}>
                <kpi.icon className="w-4 h-4" />
              </div>
            </div>
            <span className="text-2xl font-bold text-white tracking-tight">{kpi.value}</span>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-[#15151C] rounded-xl border border-white/5 p-6">
          <h3 className="text-sm font-semibold text-white mb-6 uppercase tracking-wider">Content Performance</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData} margin={{ top: 5, right: 0, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#2A2A35" vertical={false} />
                <XAxis dataKey="name" stroke="#8B8B98" fontSize={12} tickLine={false} axisLine={false} />
                <YAxis stroke="#8B8B98" fontSize={12} tickLine={false} axisLine={false} />
                <RechartsTooltip 
                  contentStyle={{backgroundColor: '#1C1C24', borderColor: '#2A2A35', color: '#fff', borderRadius: '8px', fontSize: '12px'}}
                  itemStyle={{color: '#fff'}}
                />
                <Line type="monotone" dataKey="views" stroke="#F87171" strokeWidth={2} dot={false} activeDot={{r: 4}} />
                <Line type="monotone" dataKey="engagement" stroke="#60A5FA" strokeWidth={2} dot={false} activeDot={{r: 4}} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="bg-[#15151C] rounded-xl border border-white/5 p-6 flex flex-col">
          <h3 className="text-sm font-semibold text-white mb-4 uppercase tracking-wider flex items-center gap-2">
            <Activity className="w-4 h-4 text-red-500" /> Live Activity
          </h3>
          <div className="flex-1 flex flex-col items-center justify-center text-center p-6 border border-white/5 bg-[#0B0B0F] rounded-lg">
            <div className="w-12 h-12 bg-red-500/10 rounded-full flex items-center justify-center mb-3">
              <div className="w-4 h-4 bg-red-500 rounded-full animate-pulse"></div>
            </div>
            <h4 className="text-white font-medium mb-1">No Active Stream</h4>
            <p className="text-xs text-[#8B8B98] mb-4">Start broadcasting to see live metrics here.</p>
            <button onClick={() => onNavigate('streams')} className="px-4 py-2 bg-white/5 hover:bg-white/10 text-white rounded-lg text-xs font-medium transition-colors">
              Go to Studio
            </button>
          </div>
        </div>
      </div>
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#15151C] rounded-xl border border-white/5 p-6">
           <h3 className="text-sm font-semibold text-white mb-4 uppercase tracking-wider">Publishing Overview</h3>
           <div className="space-y-3">
             {['Tech Giants Announce AI Alliance (Published)', 'New EV Policy 2026 (Review)', 'Market Trends Q3 (Draft)'].map((item, i) => (
                <div key={i} className="flex justify-between items-center p-3 hover:bg-white/5 rounded-lg border border-transparent hover:border-white/5 transition-colors cursor-pointer">
                  <span className="text-sm text-white font-medium truncate pr-4">{item.split('(')[0]}</span>
                  <span className={`text-xs px-2 py-1 rounded-md whitespace-nowrap ${
                    item.includes('Published') ? 'bg-emerald-500/10 text-emerald-400' :
                    item.includes('Review') ? 'bg-amber-500/10 text-amber-400' :
                    'bg-white/10 text-[#8B8B98]'
                  }`}>
                    {item.match(/\\((.*?)\\)/)?.[1]}
                  </span>
                </div>
             ))}
           </div>
        </div>
        <div className="bg-[#15151C] rounded-xl border border-white/5 p-6">
           <h3 className="text-sm font-semibold text-white mb-4 uppercase tracking-wider">Recent Activity</h3>
           <div className="space-y-4">
             <div className="flex gap-3 items-start">
                <div className="w-2 h-2 rounded-full bg-emerald-500 mt-1.5 shrink-0"></div>
                <div>
                  <p className="text-sm text-white font-medium">Article Published</p>
                  <p className="text-xs text-[#8B8B98]">"Future of Remote Work" went live 2h ago</p>
                </div>
             </div>
             <div className="flex gap-3 items-start">
                <div className="w-2 h-2 rounded-full bg-purple-500 mt-1.5 shrink-0"></div>
                <div>
                  <p className="text-sm text-white font-medium">Reel Uploaded</p>
                  <p className="text-xs text-[#8B8B98]">"Office Tour" is processing 4h ago</p>
                </div>
             </div>
             <div className="flex gap-3 items-start">
                <div className="w-2 h-2 rounded-full bg-red-500 mt-1.5 shrink-0"></div>
                <div>
                  <p className="text-sm text-white font-medium">Stream Ended</p>
                  <p className="text-xs text-[#8B8B98]">"Weekly Q&A" lasted 45m (1.2K viewers)</p>
                </div>
             </div>
           </div>
        </div>
      </div>
    </div>
  );
}
