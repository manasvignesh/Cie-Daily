import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { doc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Stream } from '../types';
import { useLiveKitToken } from '../hooks/useLiveKitToken';
import { 
  LiveKitRoom, 
  RoomAudioRenderer,
  ControlBar,
  useTracks,
  ParticipantTile,
  GridLayout
} from '@livekit/components-react';
import { Track } from 'livekit-client';
import '@livekit/components-styles';
import { useLiveComments } from '../hooks/useLiveComments';
import { format } from 'date-fns';

import { Trash2, AlertCircle, PhoneOff, CameraOff } from 'lucide-react';



const isMobileDevice = typeof navigator !== 'undefined' && (/iPhone|iPad|iPod|Android/i.test(navigator.userAgent) || !navigator.mediaDevices?.getDisplayMedia);

function StreamLayout() {
  const tracks = useTracks([
    { source: Track.Source.Camera, withPlaceholder: true },
    { source: Track.Source.ScreenShare, withPlaceholder: false },
  ]);

  return (
    <div className="flex flex-col h-full w-full relative">
      <div className="flex-1 p-2 md:p-4 h-full w-full relative">
         <GridLayout tracks={tracks}>
            <ParticipantTile />
         </GridLayout>
      </div>
      <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2 z-20 lk-theme-default max-w-[95%] overflow-x-auto">
        <ControlBar 
          controls={{ 
            camera: true, 
            microphone: true, 
            screenShare: !isMobileDevice, 
            chat: false, 
            leave: false 
          }} 
        />
      </div>
    </div>
  );
}

export function LiveStudio() {
  const { streamId } = useParams();
  const navigate = useNavigate();
  const [stream, setStream] = useState<Stream | null>(null);
  const [loading, setLoading] = useState(true);
  const [rulesError, setRulesError] = useState<string | null>(null);
  const [liveKitError, setLiveKitError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  const [insecureWarning, setInsecureWarning] = useState(false);
  
  const roomName = stream?.roomName || streamId || '';
  const { token, error: tokenError, loading: tokenLoading } = useLiveKitToken(streamId || '', roomName);
  const { comments, deleteComment, error: commentsError } = useLiveComments(streamId || '');

  useEffect(() => {
    // Detect non-secure context on mobile devices
    if (typeof window !== 'undefined' && !window.isSecureContext && window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1') {
      setInsecureWarning(true);
    }
  }, []);

  useEffect(() => {
    async function fetchStream() {
      if (!streamId) return;
      try {
        const docRef = doc(db, 'liveStreams', streamId);
        const docSnap = await getDoc(docRef);
        if (docSnap.exists()) {
          const data = docSnap.data();
          setStream({ 
            id: docSnap.id, 
            roomName: data.roomName || docSnap.id,
            ...data 
          } as Stream);
        } else {
          setStream(null);
        }
      } catch (e: any) {
        if (e?.code !== 'permission-denied') console.error("Error fetching stream:", e);
        if (e?.code === 'permission-denied') {
           setRulesError("Firestore Permission Denied. Please ensure your Firebase Security Rules allow access to the 'liveStreams' collection.");
        }
      } finally {
        setLoading(false);
      }
    }
    fetchStream();
  }, [streamId, navigate]);

  const handleStartStream = async () => {
    if (!streamId) return;
    try {
      await updateDoc(doc(db, 'liveStreams', streamId), {
        status: 'live',
        startedAt: serverTimestamp()
      });
      setStream(prev => prev ? { ...prev, status: 'live' } : null);
    } catch (e: any) {
      if (e?.code === 'permission-denied') {
        alert("Firestore Permission Denied: Unable to start stream. Check your security rules.");
      } else {
        alert("Failed to start stream");
      }
    }
  };

  const handleEndStream = async () => {
    if (!streamId) return;
    try {
      await updateDoc(doc(db, 'liveStreams', streamId), {
        status: 'ended',
        endedAt: serverTimestamp()
      });
      navigate('/');
    } catch (e: any) {
      if (e?.code === 'permission-denied') {
        alert("Firestore Permission Denied: Unable to end stream. Check your security rules.");
      } else {
        alert("Failed to end stream");
      }
    }
  };

  if (loading || (tokenLoading && !tokenError)) {
    return (
      <div className="flex items-center justify-center p-12 text-[#8B8B98]">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-red-500 border-t-transparent rounded-full animate-spin"></div>
          <p>Initializing Studio...</p>
        </div>
      </div>
    );
  }

  if (!stream) {
    return (
      <div className="p-8 text-center bg-[#15151C] rounded-2xl border border-white/5 max-w-lg mx-auto mt-8">
        <CameraOff className="w-12 h-12 text-white/30 mx-auto mb-3" />
        <h3 className="text-lg font-bold text-white mb-2">Stream not found</h3>
        <p className="text-[#8B8B98] text-sm mb-6">This stream may have been deleted or does not exist.</p>
        <button 
          onClick={() => navigate('/')}
          className="px-6 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg text-sm transition-colors"
        >
          Return to Dashboard
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-[calc(100vh-8rem)] flex flex-col lg:flex-row gap-6 pb-8">
      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
          <div>
            <h1 className="text-xl md:text-2xl font-bold text-white mb-1">{stream.title}</h1>
            <p className="text-[#8B8B98] text-sm">{stream.description || 'No description'}</p>
          </div>
          
          <div className="flex items-center gap-3">
            {stream.status === 'scheduled' ? (
              <button 
                onClick={handleStartStream}
                className="px-5 py-2.5 bg-red-500 hover:bg-red-600 text-white font-bold rounded-full transition-colors shadow-lg shadow-red-500/20 text-sm"
              >
                Go Live
              </button>
            ) : (
              <div className="flex items-center gap-2">
                <span className="flex items-center gap-2 px-3 py-1 bg-red-500/10 text-red-500 rounded-full text-xs md:text-sm font-semibold border border-red-500/20 animate-pulse">
                  <span className="w-2 h-2 rounded-full bg-red-500"></span>
                  LIVE
                </span>
              </div>
            )}
            
            <button 
              onClick={handleEndStream}
              className="px-4 py-2.5 bg-red-500/80 hover:bg-red-600 text-white font-bold rounded-full transition-colors flex items-center gap-2 text-sm"
            >
              <PhoneOff className="w-4 h-4" />
              End
            </button>
          </div>
        </div>

        {insecureWarning && (
          <div className="mb-4 bg-amber-500/10 border border-amber-500/30 rounded-xl p-4 flex gap-3 text-amber-300 text-sm">
            <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-semibold mb-0.5">Mobile Browser Note</p>
              <p className="text-xs opacity-90">Mobile browsers (iOS Safari / Android Chrome) require an HTTPS connection to grant camera and microphone access. If video fails to turn on, connect via HTTPS.</p>
            </div>
          </div>
        )}

        {rulesError && (
          <div className="mb-4 bg-red-500/10 border border-red-500/30 rounded-xl p-4 flex gap-4 text-red-400 text-sm">
            <AlertCircle className="w-5 h-5 flex-shrink-0" />
            <p>{rulesError}</p>
          </div>
        )}

        {(tokenError || liveKitError) && (
          <div className="mb-4 bg-red-500/10 rounded-xl border border-red-500/20 flex flex-col items-center justify-center text-red-400 p-6 text-center">
            <AlertCircle className="w-8 h-8 mb-2" />
            <p className="font-bold text-base mb-1">LiveKit Connection Notice</p>
            <p className="text-xs max-w-md">{tokenError || liveKitError}</p>
          </div>
        )}

        {token && import.meta.env.VITE_LIVEKIT_URL ? (
          connected ? (
            <LiveKitRoom
              data-lk-theme="default"
              video={true}
              audio={true}
              token={token}
              serverUrl={import.meta.env.VITE_LIVEKIT_URL}
              connect={true}
              onError={(err) => {
                console.error("LiveKit room error:", err);
                setLiveKitError(err?.message || "Failed to connect to LiveKit room");
              }}
              onDisconnected={() => {
                setConnected(false);
              }}
              className="flex-1 min-h-[360px] md:min-h-[480px] flex flex-col bg-[#0B0B0F] rounded-2xl overflow-hidden border border-white/5 relative"
            >
              <StreamLayout />
              <RoomAudioRenderer />
            </LiveKitRoom>
          ) : (
            <div className="flex-1 min-h-[360px] md:min-h-[480px] bg-[#15151C] rounded-2xl border border-white/5 flex items-center justify-center flex-col text-[#8B8B98] p-6">
              <div className="bg-[#0B0B0F] p-6 md:p-8 rounded-xl border border-white/10 text-center max-w-md w-full">
                <CameraOff className="w-10 h-10 md:w-12 md:h-12 mb-4 mx-auto text-white/50" />
                <h3 className="text-lg md:text-xl font-bold text-white mb-2">Ready to enter Studio</h3>
                <p className="text-xs md:text-sm mb-6 text-[#8B8B98]">Connect your camera and microphone to the broadcast room.</p>
                <button 
                  onClick={() => setConnected(true)}
                  className="w-full py-3 bg-red-500 text-white hover:bg-red-600 font-bold rounded-lg transition-colors shadow-lg shadow-red-500/20"
                >
                  Enter Studio
                </button>
              </div>
            </div>
          )
        ) : (
          !tokenError && (
            <div className="flex-1 min-h-[360px] bg-[#15151C] rounded-2xl border border-white/5 flex items-center justify-center flex-col text-[#8B8B98] p-8">
              <CameraOff className="w-10 h-10 mb-3 text-white/30" />
              <p className="text-sm">Connecting to LiveKit server...</p>
            </div>
          )
        )}
      </div>

      {/* Right Sidebar - Chat */}
      <div className="w-full lg:w-80 xl:w-96 bg-[#15151C] rounded-2xl border border-white/5 flex flex-col overflow-hidden h-72 lg:h-auto shrink-0">
        <div className="p-4 border-b border-white/5 bg-[#1C1C24]">
          <h2 className="font-semibold text-white text-sm md:text-base">Live Comments</h2>
          <p className="text-xs text-[#8B8B98]">Audience feedback in real-time</p>
        </div>
        
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {commentsError ? (
            <div className="h-full flex flex-col items-center justify-center text-center px-4 text-red-400">
              <AlertCircle className="w-6 h-6 mb-2" />
              <p className="text-xs font-medium mb-1">Failed to load comments</p>
              <p className="text-[11px] opacity-80">{commentsError}</p>
            </div>
          ) : comments.length === 0 ? (
            <div className="h-full flex items-center justify-center text-center px-4 py-8">
              <p className="text-[#8B8B98] text-xs">No comments yet. When viewers join, their messages will appear here.</p>
            </div>
          ) : (
            comments.map((comment) => (
              <div key={comment.id} className="bg-[#0B0B0F] p-3 rounded-lg border border-white/5 group relative">
                <div className="flex justify-between items-start mb-1">
                  <span className="font-medium text-xs text-white truncate max-w-[140px]">{comment.username || (comment as any).userName || (comment as any).authorName || "Anonymous"}</span>
                  <span className="text-[10px] text-[#8B8B98]">
                    {(comment.createdAt || (comment as any).timestamp) ? format((comment.createdAt || (comment as any).timestamp).toDate(), 'HH:mm') : 'Just now'}
                  </span>
                </div>
                <p className="text-xs text-[#8B8B98] break-words">{comment.message || (comment as any).text || (comment as any).content}</p>
                
                <button 
                  onClick={() => deleteComment(comment.id)}
                  className="absolute -top-2 -right-2 bg-red-500 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity shadow-lg"
                  title="Delete comment"
                >
                  <Trash2 className="w-3 h-3" />
                </button>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
