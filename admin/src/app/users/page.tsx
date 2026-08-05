export default function UsersPage() {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">User Management</h1>

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 p-6">
        <div className="flex justify-between items-center mb-6">
          <input 
            type="text" 
            placeholder="Search students by email or name..." 
            className="w-96 border border-slate-200 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-orange-500/50"
          />
          <button className="text-orange-500 font-medium hover:text-orange-600">
            Export CSV
          </button>
        </div>
        
        <table className="w-full text-left">
          <thead className="bg-slate-50 border-b border-slate-100">
            <tr>
              <th className="px-6 py-4 font-semibold text-slate-600">Student Name</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Email</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Department</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            <tr className="hover:bg-slate-50">
              <td className="px-6 py-4 font-medium text-slate-900">Alice Smith</td>
              <td className="px-6 py-4 text-slate-600">alice@mlrit.ac.in</td>
              <td className="px-6 py-4 text-slate-600">CSE</td>
              <td className="px-6 py-4">
                <span className="bg-green-100 text-green-700 px-2 py-1 rounded text-sm font-medium">Active</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
