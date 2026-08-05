import Link from 'next/link';

export default function Sidebar() {
  return (
    <aside className="w-64 bg-slate-900 text-white h-screen flex flex-col">
      <div className="p-6">
        <h1 className="text-2xl font-bold tracking-tighter text-orange-500">Catalyst Admin</h1>
      </div>
      <nav className="flex-1 px-4 space-y-2">
        <Link href="/" className="block px-4 py-2 rounded hover:bg-slate-800 transition">
          Dashboard
        </Link>
        <Link href="/posts" className="block px-4 py-2 rounded hover:bg-slate-800 transition">
          Posts & Drops
        </Link>
        <Link href="/spaces" className="block px-4 py-2 rounded hover:bg-slate-800 transition">
          Live Spaces
        </Link>
        <Link href="/users" className="block px-4 py-2 rounded hover:bg-slate-800 transition">
          User Management
        </Link>
        <Link href="/notifications" className="block px-4 py-2 rounded hover:bg-slate-800 transition">
          Push Notifications
        </Link>
      </nav>
      <div className="p-6">
        <button className="w-full py-2 bg-slate-800 rounded hover:bg-slate-700 transition">
          Logout
        </button>
      </div>
    </aside>
  );
}
