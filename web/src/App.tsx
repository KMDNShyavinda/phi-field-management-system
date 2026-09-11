import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { LayoutDashboard, Users, FileText, AlertTriangle, Settings, LogOut } from 'lucide-react';

function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200">
        <div className="h-16 flex items-center px-6 border-b border-gray-200">
          <span className="text-xl font-bold text-blue-900">PHI Admin</span>
        </div>
        <nav className="p-4 space-y-1">
          <Link to="/" className="flex items-center px-4 py-3 text-blue-700 bg-blue-50 rounded-lg font-medium">
            <LayoutDashboard className="w-5 h-5 mr-3" />
            Dashboard
          </Link>
          <Link to="/officers" className="flex items-center px-4 py-3 text-gray-600 hover:bg-gray-50 hover:text-gray-900 rounded-lg font-medium">
            <Users className="w-5 h-5 mr-3" />
            PHI Officers
          </Link>
          <Link to="/inspections" className="flex items-center px-4 py-3 text-gray-600 hover:bg-gray-50 hover:text-gray-900 rounded-lg font-medium">
            <FileText className="w-5 h-5 mr-3" />
            Inspections
          </Link>
          <Link to="/complaints" className="flex items-center px-4 py-3 text-gray-600 hover:bg-gray-50 hover:text-gray-900 rounded-lg font-medium">
            <AlertTriangle className="w-5 h-5 mr-3" />
            Complaints
          </Link>
          <div className="pt-4 mt-4 border-t border-gray-200">
            <Link to="/settings" className="flex items-center px-4 py-3 text-gray-600 hover:bg-gray-50 hover:text-gray-900 rounded-lg font-medium">
              <Settings className="w-5 h-5 mr-3" />
              Settings
            </Link>
            <button className="w-full flex items-center px-4 py-3 text-red-600 hover:bg-red-50 rounded-lg font-medium mt-1">
              <LogOut className="w-5 h-5 mr-3" />
              Logout
            </button>
          </div>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <header className="h-16 bg-white border-b border-gray-200 flex items-center px-8 justify-between">
          <h1 className="text-xl font-semibold text-gray-800">Colombo MOH Area</h1>
          <div className="flex items-center space-x-4">
            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-700 font-bold">
              A
            </div>
            <span className="font-medium text-gray-700">Admin User</span>
          </div>
        </header>
        <div className="p-8">
          {children}
        </div>
      </main>
    </div>
  );
}

function DashboardHome() {
  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Overview</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Total Inspections (This Month)</h3>
          <p className="text-3xl font-bold mt-2">1,248</p>
          <span className="text-green-600 text-sm font-medium mt-2 block">+12% from last month</span>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Active Complaints</h3>
          <p className="text-3xl font-bold mt-2">42</p>
          <span className="text-red-600 text-sm font-medium mt-2 block">8 Emergency priority</span>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Violations Issued</h3>
          <p className="text-3xl font-bold mt-2">156</p>
          <span className="text-orange-600 text-sm font-medium mt-2 block">Requires follow-up</span>
        </div>
      </div>
    </div>
  );
}

function App() {
  return (
    <Router>
      <DashboardLayout>
        <Routes>
          <Route path="/" element={<DashboardHome />} />
          <Route path="*" element={<div>Page coming soon</div>} />
        </Routes>
      </DashboardLayout>
    </Router>
  );
}

export default App;
