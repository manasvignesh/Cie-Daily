/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './components/ProtectedRoute';
import { AdminLayout } from './components/AdminLayout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { LiveStudio } from './pages/LiveStudio';
import { StreamHistory } from './pages/StreamHistory';
import { Settings } from './pages/Settings';
import { Comments } from './pages/Comments';
import { auth } from './lib/firebase';

function ConfigRequired() {
  return (
    <div className="min-h-screen bg-[#0B0B0F] flex items-center justify-center p-4">
      <div className="bg-[#15151C] p-8 rounded-2xl border border-red-500/30 text-white max-w-md w-full shadow-2xl">
        <h1 className="text-2xl font-bold text-red-500 mb-4">Configuration Required</h1>
        <p className="text-[#8B8B98] mb-6">
          Please configure your Firebase and LiveKit environment variables in the Settings menu to continue.
        </p>
        <div className="bg-[#0B0B0F] p-4 rounded-lg border border-white/5 space-y-2">
          <p className="text-sm font-medium text-white mb-2">Required Variables:</p>
          <ul className="text-xs space-y-1.5 text-[#8B8B98] font-mono">
            <li>VITE_FIREBASE_API_KEY</li>
            <li>VITE_FIREBASE_AUTH_DOMAIN</li>
            <li>VITE_FIREBASE_PROJECT_ID</li>
            <li>VITE_LIVEKIT_URL</li>
            <li>LIVEKIT_API_KEY</li>
            <li>LIVEKIT_API_SECRET</li>
          </ul>
        </div>
      </div>
    </div>
  );
}

export default function App() {
  if (!auth) {
    return <ConfigRequired />;
  }

  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />
        
        <Route element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }>
          <Route path="/" element={<Dashboard />} />
          <Route path="/streams" element={<Dashboard initialTab="streams" />} />
          <Route path="/reels" element={<Dashboard initialTab="reels" />} />
          <Route path="/articles" element={<Dashboard initialTab="articles" />} />
          <Route path="/analytics" element={<Dashboard initialTab="analytics" />} />

          <Route path="/comments" element={<Comments />} />
          <Route path="/history" element={<StreamHistory />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/studio/:streamId" element={<LiveStudio />} />
        </Route>
      </Routes>
    </Router>
  );
}
