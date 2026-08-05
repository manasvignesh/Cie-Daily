export default function NotificationsPage() {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Push Notifications</h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h2 className="text-xl font-bold mb-6">Send New Broadcast</h2>
          
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Title</label>
              <input type="text" className="w-full border border-slate-200 rounded-lg px-4 py-2" placeholder="e.g. New Drop Available!" />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Message Body</label>
              <textarea rows={4} className="w-full border border-slate-200 rounded-lg px-4 py-2" placeholder="Write your message here..."></textarea>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Target Audience</label>
              <select className="w-full border border-slate-200 rounded-lg px-4 py-2 bg-white">
                <option>All Students</option>
                <option>CSE Department</option>
                <option>1st Year Students</option>
              </select>
            </div>
            <button className="w-full bg-orange-500 hover:bg-orange-600 text-white py-3 rounded-lg font-medium transition mt-4">
              Send Broadcast Now
            </button>
          </div>
        </div>
        
        <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
          <h2 className="text-xl font-bold mb-4">Mobile Preview</h2>
          <div className="flex justify-center items-center h-64 bg-slate-100 rounded-lg border border-slate-200">
            <div className="w-64 bg-white shadow-xl rounded-2xl overflow-hidden border border-slate-100 p-4 relative">
              <div className="flex items-center space-x-3 mb-2">
                <div className="w-6 h-6 bg-orange-500 rounded flex items-center justify-center text-[10px] text-white font-bold">CC</div>
                <span className="text-xs font-bold text-slate-500 uppercase">CIE Connect • now</span>
              </div>
              <h4 className="font-bold text-sm text-slate-900">New Drop Available!</h4>
              <p className="text-sm text-slate-600 mt-1 line-clamp-2">Check out the latest insights on building scalable mobile architectures.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
