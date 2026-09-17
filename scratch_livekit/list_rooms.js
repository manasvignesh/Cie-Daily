const { RoomServiceClient } = require('livekit-server-sdk');

const livekitHost = 'wss://cie-daily-79ts1icb.livekit.cloud';
const apiKey = 'APIRdnqfgkFQ6CP';
const apiSecret = 'vcFGzW6W2NV5qzSdlXtuN2vbFcMytIXyO90sAXV7NQF';

const roomService = new RoomServiceClient(livekitHost, apiKey, apiSecret);

async function listRooms() {
  try {
    const rooms = await roomService.listRooms();
    console.log('Rooms:', rooms.map(r => r.name));
    for (const room of rooms) {
       const participants = await roomService.listParticipants(room.name);
       console.log(`Room ${room.name} participants:`, participants.map(p => p.identity));
    }
  } catch (err) {
    console.error(err);
  }
}

listRooms();
