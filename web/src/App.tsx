import { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, Navigate, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Users, FileText, AlertTriangle, Settings, LogOut, Loader2, Download } from 'lucide-react';
import { apiClient } from './api';
import { generateInspectionsPDF, generateComplaintsPDF, generateOfficersPDF } from './pdfReports';

function LoginScreen({ onLogin }: { onLogin: () => void }) {
  const [email, setEmail] = useState('phi@moh.lk');
  const [password, setPassword] = useState('phi12345');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  // Forgot password state
  const [showForgot, setShowForgot] = useState(false);
  const [forgotStep, setForgotStep] = useState<'email' | 'otp' | 'newpass'>('email');
  const [forgotEmail, setForgotEmail] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [forgotMsg, setForgotMsg] = useState('');
  const [forgotError, setForgotError] = useState('');
  const [forgotLoading, setForgotLoading] = useState(false);
  const [displayOtp, setDisplayOtp] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await apiClient.post('/auth/login', { email, password });
      localStorage.setItem('token', res.data.access_token);
      onLogin();
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Login failed. Please check credentials.');
    } finally {
      setLoading(false);
    }
  };

  const handleRequestOtp = async () => {
    setForgotLoading(true);
    setForgotError('');
    setForgotMsg('');
    try {
      const res = await apiClient.post('/auth/request-otp', { email: forgotEmail });
      setForgotMsg(res.data.message);
      if (res.data.otp_code) setDisplayOtp(res.data.otp_code);
      setForgotStep('otp');
    } catch (err: any) {
      setForgotError(err.response?.data?.detail || 'Failed to send OTP.');
    } finally {
      setForgotLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    setForgotLoading(true);
    setForgotError('');
    try {
      await apiClient.post('/auth/verify-otp', { email: forgotEmail, otp_code: otpCode });
      setForgotMsg('OTP verified! Enter your new password.');
      setForgotStep('newpass');
    } catch (err: any) {
      setForgotError(err.response?.data?.detail || 'Invalid OTP.');
    } finally {
      setForgotLoading(false);
    }
  };

  const handleResetPassword = async () => {
    setForgotLoading(true);
    setForgotError('');
    try {
      // Request a fresh OTP for the reset call
      const otpRes = await apiClient.post('/auth/request-otp', { email: forgotEmail });
      const freshOtp = otpRes.data.otp_code;
      await apiClient.post('/auth/reset-password', {
        email: forgotEmail,
        otp_code: freshOtp,
        new_password: newPassword
      });
      setForgotMsg('Password reset successfully! You can now login.');
      setTimeout(() => {
        setShowForgot(false);
        setForgotStep('email');
        setForgotMsg('');
        setDisplayOtp('');
      }, 2000);
    } catch (err: any) {
      setForgotError(err.response?.data?.detail || 'Failed to reset password.');
    } finally {
      setForgotLoading(false);
    }
  };

  const closeForgot = () => {
    setShowForgot(false);
    setForgotStep('email');
    setForgotError('');
    setForgotMsg('');
    setDisplayOtp('');
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8 bg-white p-10 rounded-xl shadow-lg">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            MOH Admin Portal
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            Sign in to manage PHI operations
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          {error && <div className="text-red-500 text-sm text-center">{error}</div>}
          <div className="rounded-md shadow-sm -space-y-px">
            <div>
              <input
                type="email"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div>
              <input
                type="password"
                required
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>
          <div className="flex items-center justify-end">
            <button type="button" onClick={() => setShowForgot(true)} className="text-sm text-blue-600 hover:text-blue-500">
              Forgot your password?
            </button>
          </div>
          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:bg-blue-400"
            >
              {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Sign in'}
            </button>
          </div>

          <div className="mt-6 text-center border-t border-gray-200 pt-4">
            <p className="text-sm text-gray-600 mb-2">Are you a citizen reporting a health issue?</p>
            <a 
              href="/report-issue"
              className="inline-flex justify-center py-2 px-4 border border-green-600 text-sm font-medium rounded-md text-green-700 bg-white hover:bg-green-50 w-full"
            >
              Submit a Public Complaint
            </a>
          </div>
        </form>
      </div>

      {/* Forgot Password Modal */}
      {showForgot && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-xl shadow-2xl p-8 max-w-md w-full mx-4">
            <div className="flex justify-between items-center mb-6">
              <h3 className="text-xl font-bold text-gray-900">Reset Password</h3>
              <button onClick={closeForgot} className="text-gray-400 hover:text-gray-600 text-2xl">&times;</button>
            </div>

            {forgotMsg && <div className="mb-4 p-3 bg-green-50 text-green-700 rounded-lg text-sm">{forgotMsg}</div>}
            {forgotError && <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-lg text-sm">{forgotError}</div>}

            {forgotStep === 'email' && (
              <div className="space-y-4">
                <p className="text-sm text-gray-600">Enter your email address to receive an OTP code.</p>
                <input
                  type="email"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  placeholder="Email address"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                />
                <button
                  onClick={handleRequestOtp}
                  disabled={forgotLoading || !forgotEmail}
                  className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium disabled:bg-blue-400"
                >
                  {forgotLoading ? <Loader2 className="w-5 h-5 animate-spin mx-auto" /> : 'Send OTP'}
                </button>
              </div>
            )}

            {forgotStep === 'otp' && (
              <div className="space-y-4">
                <p className="text-sm text-gray-600">Enter the 6-digit OTP code sent to your email.</p>
                {displayOtp && (
                  <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-center">
                    <span className="text-xs text-yellow-600">Demo Mode - OTP Code:</span>
                    <span className="block text-2xl font-mono font-bold text-yellow-800 tracking-widest mt-1">{displayOtp}</span>
                  </div>
                )}
                <input
                  type="text"
                  maxLength={6}
                  className="w-full px-4 py-3 border border-gray-300 rounded-lg text-center text-2xl font-mono tracking-widest focus:ring-blue-500 focus:border-blue-500"
                  placeholder="000000"
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, ''))}
                />
                <button
                  onClick={handleVerifyOtp}
                  disabled={forgotLoading || otpCode.length !== 6}
                  className="w-full py-2 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium disabled:bg-blue-400"
                >
                  {forgotLoading ? <Loader2 className="w-5 h-5 animate-spin mx-auto" /> : 'Verify OTP'}
                </button>
              </div>
            )}

            {forgotStep === 'newpass' && (
              <div className="space-y-4">
                <p className="text-sm text-gray-600">Enter your new password.</p>
                <input
                  type="password"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500"
                  placeholder="New password"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                />
                <button
                  onClick={handleResetPassword}
                  disabled={forgotLoading || newPassword.length < 6}
                  className="w-full py-2 px-4 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium disabled:bg-green-400"
                >
                  {forgotLoading ? <Loader2 className="w-5 h-5 animate-spin mx-auto" /> : 'Reset Password'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function DashboardLayout({ children, onLogout }: { children: React.ReactNode, onLogout: () => void }) {
  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200">
        <div className="h-16 flex items-center px-6 border-b border-gray-200">
          <span className="text-xl font-bold text-blue-900">MOH Dashboard</span>
        </div>
        <nav className="p-4 space-y-1">
          <Link to="/" className="flex items-center px-4 py-3 text-blue-700 bg-blue-50 rounded-lg font-medium">
            <LayoutDashboard className="w-5 h-5 mr-3" />
            Overview
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
            <button onClick={onLogout} className="w-full flex items-center px-4 py-3 text-red-600 hover:bg-red-50 rounded-lg font-medium mt-1">
              <LogOut className="w-5 h-5 mr-3" />
              Logout
            </button>
          </div>
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto">
        <header className="h-16 bg-white border-b border-gray-200 flex items-center px-8 justify-between">
          <h1 className="text-xl font-semibold text-gray-800">Area Overview</h1>
          <div className="flex items-center space-x-4">
            <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-700 font-bold">
              M
            </div>
            <span className="font-medium text-gray-700">MOH Admin</span>
          </div>
        </header>
        <div className="p-8">
          {children}
        </div>
      </main>
    </div>
  );
}

function InspectionsList() {
  const [inspections, setInspections] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchInspections() {
      try {
        const res = await apiClient.get('/dashboard/inspections');
        setInspections(res.data);
      } catch (err) {
        console.error('Failed to fetch inspections', err);
      } finally {
        setLoading(false);
      }
    }
    fetchInspections();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="w-8 h-8 animate-spin text-blue-500" /></div>;
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Field Inspections</h2>
        <button
          onClick={() => generateInspectionsPDF(inspections)}
          className="flex items-center bg-green-700 hover:bg-green-800 text-white px-4 py-2 rounded-lg text-sm font-medium"
        >
          <Download className="w-4 h-4 mr-2" />
          Download PDF
        </button>
      </div>
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Premise</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PHI Officer</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Score</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {inspections.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-4 text-center text-gray-500">No inspections found.</td>
              </tr>
            ) : (
              inspections.map((i) => (
                <tr key={i.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{i.premise_name}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{i.officer_name}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{new Date(i.started_at).toLocaleDateString()}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      i.compliance_score >= 80 ? 'bg-green-100 text-green-800' :
                      i.compliance_score >= 50 ? 'bg-yellow-100 text-yellow-800' :
                      'bg-red-100 text-red-800'
                    }`}>
                      {i.compliance_score !== null ? `${i.compliance_score}%` : 'N/A'}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <button className="text-blue-600 hover:text-blue-900">View Report</button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function OfficersList() {
  const [officers, setOfficers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchOfficers() {
      try {
        const res = await apiClient.get('/dashboard/officers');
        setOfficers(res.data);
      } catch (err) {
        console.error('Failed to fetch officers', err);
      } finally {
        setLoading(false);
      }
    }
    fetchOfficers();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="w-8 h-8 animate-spin text-blue-500" /></div>;
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">PHI Officers</h2>
        <div className="flex gap-3">
          <button
            onClick={() => generateOfficersPDF(officers)}
            className="flex items-center bg-green-700 hover:bg-green-800 text-white px-4 py-2 rounded-lg text-sm font-medium"
          >
            <Download className="w-4 h-4 mr-2" />
            Download PDF
          </button>
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium">
            + Add New Officer
          </button>
        </div>
      </div>
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">MOH Area</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {officers.length === 0 ? (
              <tr>
                <td colSpan={4} className="px-6 py-4 text-center text-gray-500">No officers found.</td>
              </tr>
            ) : (
              officers.map((o) => (
                <tr key={o.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{o.full_name}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{o.email}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{o.moh_area || 'Not assigned'}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      o.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {o.is_active ? 'ACTIVE' : 'INACTIVE'}
                    </span>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ComplaintsList() {
  const [complaints, setComplaints] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchComplaints() {
      try {
        const res = await apiClient.get('/dashboard/complaints');
        setComplaints(res.data);
      } catch (err) {
        console.error('Failed to fetch complaints', err);
      } finally {
        setLoading(false);
      }
    }
    fetchComplaints();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="w-8 h-8 animate-spin text-blue-500" /></div>;
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">Complaints Management</h2>
        <button
          onClick={() => generateComplaintsPDF(complaints)}
          className="flex items-center bg-green-700 hover:bg-green-800 text-white px-4 py-2 rounded-lg text-sm font-medium"
        >
          <Download className="w-4 h-4 mr-2" />
          Download PDF
        </button>
      </div>
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tracking No</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Title</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Priority</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Received Date</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {complaints.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-4 text-center text-gray-500">No complaints found.</td>
              </tr>
            ) : (
              complaints.map((c) => (
                <tr key={c.id}>
                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600">{c.tracking_no}</td>
                  <td className="px-6 py-4 text-sm text-gray-900">{c.title}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      c.priority === 'emergency' ? 'bg-red-100 text-red-800' :
                      c.priority === 'high' ? 'bg-orange-100 text-orange-800' :
                      'bg-green-100 text-green-800'
                    }`}>
                      {c.priority.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                      c.status === 'resolved' ? 'bg-green-100 text-green-800' :
                      'bg-yellow-100 text-yellow-800'
                    }`}>
                      {c.status.toUpperCase()}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {new Date(c.received_date).toLocaleDateString()}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function DashboardHome() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      try {
        const res = await apiClient.get('/dashboard/admin_stats');
        setStats(res.data);
      } catch (err) {
        console.error('Failed to fetch stats', err);
      } finally {
        setLoading(false);
      }
    }
    fetchStats();
  }, []);

  if (loading) {
    return <div className="flex justify-center items-center h-64"><Loader2 className="w-8 h-8 animate-spin text-blue-500" /></div>;
  }

  if (!stats) {
    return <div className="text-red-500">Failed to load dashboard data.</div>;
  }

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Overview: {stats.moh_area || 'All Areas'}</h2>
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Total Inspections (Month)</h3>
          <p className="text-3xl font-bold mt-2">{stats.total_inspections_month}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Active Complaints</h3>
          <p className="text-3xl font-bold mt-2">{stats.active_complaints}</p>
          {stats.emergency_complaints > 0 && (
            <span className="text-red-600 text-sm font-medium mt-2 block">{stats.emergency_complaints} Emergency</span>
          )}
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Violations Issued</h3>
          <p className="text-3xl font-bold mt-2">{stats.violations_issued}</p>
        </div>
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-gray-500 text-sm font-medium">Active PHI Officers</h3>
          <p className="text-3xl font-bold mt-2">{stats.total_officers}</p>
        </div>
      </div>
      
      {/* Placeholder for charts or recent activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
         <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-80 flex items-center justify-center">
            <span className="text-gray-400">Activity Chart Coming Soon</span>
         </div>
         <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm h-80 flex items-center justify-center">
            <span className="text-gray-400">Recent Violations Map Coming Soon</span>
         </div>
      </div>
    </div>
  );
}

function SettingsPage() {
  const [activeTab, setActiveTab] = useState('profile');
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">System Settings</h2>
      
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden flex">
        {/* Settings Sidebar */}
        <div className="w-64 bg-gray-50 border-r border-gray-200 p-4 min-h-[500px]">
          <ul className="space-y-2">
            <li>
              <button 
                onClick={() => setActiveTab('profile')}
                className={`w-full text-left px-4 py-2 rounded-lg font-medium ${activeTab === 'profile' ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Profile Settings
              </button>
            </li>
            <li>
              <button 
                onClick={() => setActiveTab('system')}
                className={`w-full text-left px-4 py-2 rounded-lg font-medium ${activeTab === 'system' ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                System Preferences
              </button>
            </li>
            <li>
              <button 
                onClick={() => setActiveTab('backup')}
                className={`w-full text-left px-4 py-2 rounded-lg font-medium ${activeTab === 'backup' ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100'}`}
              >
                Data & Backup
              </button>
            </li>
          </ul>
        </div>

        {/* Settings Content */}
        <div className="flex-1 p-8">
          {saved && (
            <div className="mb-4 p-4 bg-green-50 border border-green-200 text-green-700 rounded-lg flex items-center">
              <svg className="w-5 h-5 mr-2" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"></path></svg>
              Settings saved successfully!
            </div>
          )}

          {activeTab === 'profile' && (
            <form onSubmit={handleSave} className="space-y-6 max-w-lg">
              <h3 className="text-lg font-semibold border-b pb-2">Admin Profile</h3>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input type="text" defaultValue="MOH Admin" className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email Address</label>
                <input type="email" defaultValue="phi@moh.lk" className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Change Password</label>
                <input type="password" placeholder="Enter new password" className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500" />
              </div>
              <button type="submit" className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">Save Profile</button>
            </form>
          )}

          {activeTab === 'system' && (
            <form onSubmit={handleSave} className="space-y-6 max-w-lg">
              <h3 className="text-lg font-semibold border-b pb-2">System Preferences</h3>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Default MOH Area</label>
                <select className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500">
                  <option>Colombo MOH</option>
                  <option>Gampaha MOH</option>
                  <option>Kandy MOH</option>
                </select>
              </div>
              <div className="flex items-center">
                <input type="checkbox" id="email_notif" defaultChecked className="h-4 w-4 text-blue-600 border-gray-300 rounded" />
                <label htmlFor="email_notif" className="ml-2 block text-sm text-gray-700">Receive email alerts for Emergency Complaints</label>
              </div>
              <div className="flex items-center">
                <input type="checkbox" id="sms_notif" className="h-4 w-4 text-blue-600 border-gray-300 rounded" />
                <label htmlFor="sms_notif" className="ml-2 block text-sm text-gray-700">Receive SMS alerts for Critical Violations</label>
              </div>
              <button type="submit" className="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-medium">Save Preferences</button>
            </form>
          )}

          {activeTab === 'backup' && (
            <div className="space-y-6 max-w-lg">
              <h3 className="text-lg font-semibold border-b pb-2">Data & Backup</h3>
              <p className="text-sm text-gray-600">Export your entire system database for local safekeeping or auditing purposes.</p>
              
              <div className="p-4 border border-blue-200 bg-blue-50 rounded-lg flex items-start">
                <FileText className="w-6 h-6 text-blue-600 mt-1 mr-3" />
                <div>
                  <h4 className="font-semibold text-blue-900">Download Database Backup</h4>
                  <p className="text-sm text-blue-700 mt-1 mb-3">Generates a complete SQLite (.db) or CSV export of all inspections, complaints, and officer data.</p>
                  <button className="bg-white border border-blue-300 text-blue-700 hover:bg-blue-50 px-4 py-2 rounded-lg font-medium text-sm">
                    Generate Export
                  </button>
                </div>
              </div>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}

import PublicComplaintPortal from './PublicComplaintPortal';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(!!localStorage.getItem('token'));

  const handleLogin = () => setIsAuthenticated(true);
  const handleLogout = () => {
    localStorage.removeItem('token');
    setIsAuthenticated(false);
  };

  return (
    <Router>
      <Routes>
        <Route path="/report-issue" element={<PublicComplaintPortal />} />
        
        <Route path="/login" element={isAuthenticated ? <Navigate to="/" replace /> : <LoginScreen onLogin={handleLogin} />} />
        
        <Route path="/*" element={
          isAuthenticated ? (
            <DashboardLayout onLogout={handleLogout}>
              <Routes>
                <Route path="/" element={<DashboardHome />} />
                <Route path="/overview" element={<DashboardHome />} />
                <Route path="/officers" element={<OfficersList />} />
                <Route path="/inspections" element={<InspectionsList />} />
                <Route path="/complaints" element={<ComplaintsList />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </DashboardLayout>
          ) : (
            <Navigate to="/login" replace />
          )
        } />
      </Routes>
    </Router>
  );
}

export default App;
