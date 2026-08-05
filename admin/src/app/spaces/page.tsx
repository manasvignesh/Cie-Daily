export default function SpacesPage() {
  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Live Spaces</h1>
        <button className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded font-medium transition">
          Host New Space
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h2 className="text-xl font-bold mb-4 flex items-center">
            <span className="w-2 h-2 rounded-full bg-red-500 mr-2 animate-pulse"></span>
            Active Host Console
          </h2>
          <div className="bg-slate-900 rounded-lg h-64 flex flex-col items-center justify-center text-slate-400">
            <p className="mb-4">LiveKit Host Controls</p>
            <div className="flex space-x-4">
              <button className="bg-slate-800 p-3 rounded-full hover:bg-slate-700">🎤</button>
              <button className="bg-slate-800 p-3 rounded-full hover:bg-slate-700">📹</button>
              <button className="bg-slate-800 p-3 rounded-full hover:bg-slate-700">💻</button>
              <button className="bg-red-500/20 text-red-500 p-3 rounded-full hover:bg-red-500/30">End</button>
            </div>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h2 className="text-xl font-bold mb-4">Scheduled Spaces</h2>
          <div className="space-y-4">
            <div className="border border-slate-100 rounded-lg p-4">
              <h3 className="font-bold">Q&A with the Founders</h3>
              <p className="text-slate-500 text-sm mt-1">Tomorrow, 2:00 PM</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
