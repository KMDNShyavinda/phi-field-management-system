import React, { useState, useEffect } from 'react';
import { apiClient } from './api';

export default function PublicComplaintPortal() {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    address: '',
    moh_area: '',
    isEmergency: false,
    reporterName: '',
    reporterPhone: ''
  });
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');
  const [areas, setAreas] = useState<string[]>([]);
  const [assignedTo, setAssignedTo] = useState<string>('');

  useEffect(() => {
    apiClient.get('/public/areas').then(res => {
      setAreas(res.data);
      if (res.data.length > 0) {
        setFormData(f => ({ ...f, moh_area: res.data[0] }));
      }
    }).catch(err => console.error("Failed to load areas", err));
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('submitting');
    try {
      const res = await apiClient.post('/public/complaints', formData);
      setAssignedTo(res.data.assigned_to || 'Pending Assignment');
      setStatus('success');
      setFormData({
        title: '',
        description: '',
        address: '',
        moh_area: areas[0] || '',
        isEmergency: false,
        reporterName: '',
        reporterPhone: ''
      });
    } catch (err: any) {
      console.error(err);
      setStatus('error');
      setErrorMessage(err.response?.data?.detail || 'Failed to submit complaint. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md mx-auto bg-white rounded-xl shadow-md overflow-hidden md:max-w-2xl p-8">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-extrabold text-gray-900">Report a Health Issue</h2>
          <p className="mt-2 text-gray-600">
            Submit a public health complaint directly to your local Public Health Inspector.
          </p>
        </div>

        {status === 'success' ? (
          <div className="bg-green-50 border-l-4 border-green-400 p-4 mb-6">
            <div className="flex">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-green-700 font-medium">
                  Your complaint has been submitted successfully!
                </p>
                <p className="text-xs text-green-600 mt-1">
                  A tracking number has been generated. An inspector will review your report shortly.
                </p>
                <p className="text-sm text-green-800 mt-2 font-medium bg-green-100 inline-block px-2 py-1 rounded">
                  Assigned Officer: {assignedTo}
                </p>
                <br/>
                <button 
                  onClick={() => setStatus('idle')}
                  className="mt-4 text-green-800 underline text-sm font-semibold"
                >
                  Submit another report
                </button>
              </div>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-6">
            {status === 'error' && (
              <div className="bg-red-50 text-red-700 p-3 rounded text-sm">
                {errorMessage}
              </div>
            )}
            
            <div>
              <label htmlFor="title" className="block text-sm font-medium text-gray-700">Issue Title *</label>
              <input
                type="text"
                name="title"
                id="title"
                required
                value={formData.title}
                onChange={handleChange}
                placeholder="e.g., Unsanitary food handling at local bakery"
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              />
            </div>

            <div>
              <label htmlFor="moh_area" className="block text-sm font-medium text-gray-700">MOH Area (Local Health Office) *</label>
              <select
                name="moh_area"
                id="moh_area"
                required
                value={formData.moh_area}
                onChange={handleChange}
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm bg-white"
              >
                {areas.length === 0 && <option value="">Loading areas...</option>}
                {areas.map(a => (
                  <option key={a} value={a}>{a}</option>
                ))}
              </select>
            </div>

            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700">Detailed Description *</label>
              <textarea
                name="description"
                id="description"
                rows={4}
                required
                value={formData.description}
                onChange={handleChange}
                placeholder="Please describe the issue in detail..."
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              />
            </div>

            <div>
              <label htmlFor="address" className="block text-sm font-medium text-gray-700">Location / Address *</label>
              <input
                type="text"
                name="address"
                id="address"
                required
                value={formData.address}
                onChange={handleChange}
                placeholder="Where is this happening?"
                className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
              />
            </div>

            <div className="flex items-center">
              <input
                id="isEmergency"
                name="isEmergency"
                type="checkbox"
                checked={formData.isEmergency}
                onChange={handleChange}
                className="h-4 w-4 text-red-600 focus:ring-red-500 border-gray-300 rounded"
              />
              <label htmlFor="isEmergency" className="ml-2 block text-sm text-gray-900 font-medium">
                This is an emergency (Immediate risk to public health)
              </label>
            </div>

            <div className="border-t border-gray-200 pt-6">
              <h3 className="text-lg font-medium text-gray-900">Your Contact Details (Optional)</h3>
              <p className="text-sm text-gray-500 mb-4">We will keep this information confidential.</p>
              
              <div className="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
                <div>
                  <label htmlFor="reporterName" className="block text-sm font-medium text-gray-700">Full Name</label>
                  <input
                    type="text"
                    name="reporterName"
                    id="reporterName"
                    value={formData.reporterName}
                    onChange={handleChange}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
                  />
                </div>
                <div>
                  <label htmlFor="reporterPhone" className="block text-sm font-medium text-gray-700">Phone Number</label>
                  <input
                    type="tel"
                    name="reporterPhone"
                    id="reporterPhone"
                    value={formData.reporterPhone}
                    onChange={handleChange}
                    className="mt-1 block w-full border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none focus:ring-green-500 focus:border-green-500 sm:text-sm"
                  />
                </div>
              </div>
            </div>

            <div>
              <button
                type="submit"
                disabled={status === 'submitting'}
                className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:bg-green-400"
              >
                {status === 'submitting' ? 'Submitting...' : 'Submit Complaint'}
              </button>
            </div>
            
            <div className="text-center mt-4">
              <a href="/login" className="text-sm text-gray-500 hover:text-green-600 underline">
                I am a PHI Officer (Login)
              </a>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
