export default function PostsPage() {
  return (
    <div>
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Posts & Drops</h1>
        <button className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded font-medium transition">
          Create New Drop
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
        <table className="w-full text-left">
          <thead className="bg-slate-50 border-b border-slate-100">
            <tr>
              <th className="px-6 py-4 font-semibold text-slate-600">Title</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Author</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Status</th>
              <th className="px-6 py-4 font-semibold text-slate-600">Date</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            <tr className="hover:bg-slate-50 cursor-pointer">
              <td className="px-6 py-4 font-medium text-slate-900">10 UI Rules for 2024</td>
              <td className="px-6 py-4 text-slate-600">Admin Team</td>
              <td className="px-6 py-4">
                <span className="bg-green-100 text-green-700 px-2 py-1 rounded text-sm font-medium">Published</span>
              </td>
              <td className="px-6 py-4 text-slate-500">Oct 24, 2024</td>
            </tr>
            <tr className="hover:bg-slate-50 cursor-pointer">
              <td className="px-6 py-4 font-medium text-slate-900">Flutter Architecture Guide</td>
              <td className="px-6 py-4 text-slate-600">Engineering Dept</td>
              <td className="px-6 py-4">
                <span className="bg-amber-100 text-amber-700 px-2 py-1 rounded text-sm font-medium">Draft</span>
              </td>
              <td className="px-6 py-4 text-slate-500">-</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  );
}
