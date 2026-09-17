import { useState, useEffect } from 'react';
import { useAuth } from './useAuth';

export function useLiveKitToken(streamId: string, roomName: string) {
  const { user } = useAuth();
  const [token, setToken] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    async function fetchToken() {
      if (!user) {
        setLoading(false);
        return;
      }
      
      setLoading(true);
      setError(null);
      try {
        const idToken = await user.getIdToken();
        const response = await fetch('/api/livekit/token', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${idToken}`
          },
          body: JSON.stringify({ streamId, roomName })
        });

        const data = await response.json();
        
        if (!response.ok) {
          throw new Error(data.error || 'Failed to fetch token');
        }

        setToken(data.token);
      } catch (err: any) {
        console.error('Error fetching LiveKit token:', err);
        setError(err.message || 'Failed to connect to LiveKit');
      } finally {
        setLoading(false);
      }
    }

    if (streamId && roomName && user) {
      fetchToken();
    } else if (!streamId) {
      setLoading(false);
    }
  }, [user, streamId, roomName]);

  return { token, error, loading };
}
