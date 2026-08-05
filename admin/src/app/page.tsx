export default function DashboardPage() {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h3 className="text-slate-500 font-medium">Total Students</h3>
          <p className="text-3xl font-bold text-slate-900 mt-2">1,248</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h3 className="text-slate-500 font-medium">Active Spaces</h3>
          <p className="text-3xl font-bold text-slate-900 mt-2">3</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <h3 className="text-slate-500 font-medium">Today's Drops</h3>
          <p className="text-3xl font-bold text-slate-900 mt-2">1</p>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6 h-96">
        <h2 className="text-xl font-bold mb-4">Engagement Overview</h2>
        <div className="h-full flex items-center justify-center text-slate-400">
          [Chart Placeholder: Daily Active Users vs Time]
        </div>
      </div>
    </div>
  );
}
