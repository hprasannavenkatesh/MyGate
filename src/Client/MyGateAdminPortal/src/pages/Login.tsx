// src/pages/Login.tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Loader2, Phone, Shield } from 'lucide-react';
import {API_URLS} from "../api/apiConfig";

//const IDENTITY_URL = API_URLS.IDENTITY;

const Login = () => {
  const navigate = useNavigate();
  const [mobile, setMobile] = useState('');
  const [otp, setOtp] = useState('');
  const [isOtpSent, setIsOtpSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  //const [basicToken, setBasicToken] = useState('');

  const handleRequestOtp = async () => {
    if (!mobile.trim()) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API_URLS.IDENTITY}/auth/request-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mobileNumber: mobile.trim() }),
      });
      if (res.ok) {
        setIsOtpSent(true);
      } else {
        setError('Failed to request OTP');
      }
    } catch (err: any) {
      setError('Error: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async () => {
    if (!otp.trim()) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API_URLS.IDENTITY}/auth/verify-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mobileNumber: mobile.trim(), otp: otp.trim() }),
      });

      if (res.ok) {
        const data = await res.json();
        const token = data.token;
        localStorage.setItem('auth_token', token);
        navigate('/');
        window.location.reload();
      } else {
        setError('Invalid OTP');
      }
    } catch (err: any) {
      setError('Error: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-lg border border-slate-200 w-full max-w-sm">
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-16 h-16 bg-blue-100 rounded-full mb-3">
            <Shield className="w-8 h-8 text-blue-600" />
          </div>
          <h1 className="text-xl font-bold text-slate-800">MyGate Admin</h1>
          <p className="text-sm text-slate-500 mt-1">Login to manage your society</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 text-sm p-3 rounded mb-4">
            {error}
          </div>
        )}

        {!isOtpSent ? (
          <>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Mobile Number
            </label>
            <div className="flex gap-2 mb-4">
              <div className="flex items-center px-3 border border-slate-300 rounded-l-md bg-slate-50 text-slate-500 text-sm">
                <Phone size={16} />
              </div>
              <input
                type="tel"
                value={mobile}
                onChange={(e) => setMobile(e.target.value)}
                placeholder="9876543210"
                maxLength={15}
                className="flex-1 border border-slate-300 rounded-r-md px-3 py-2.5 text-sm focus:outline-none focus:border-blue-500"
              />
            </div>
            <button
              onClick={handleRequestOtp}
              disabled={loading || !mobile.trim()}
              className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white py-2.5 rounded-md text-sm font-medium flex items-center justify-center gap-2"
            >
              {loading ? <Loader2 size={16} className="animate-spin" /> : null}
              {loading ? 'Sending...' : 'Send OTP'}
            </button>
            <p className="text-xs text-slate-400 mt-3 text-center">
              OTP will appear in the .NET terminal console
            </p>
          </>
        ) : (
          <>
            <p className="text-sm text-slate-600 mb-3">
              OTP sent to <strong>{mobile}</strong>
            </p>
            <label className="block text-sm font-medium text-slate-700 mb-1">
              Enter OTP
            </label>
            <input
              type="text"
              value={otp}
              onChange={(e) => setOtp(e.target.value)}
              placeholder="4-digit OTP"
              maxLength={4}
              className="w-full border border-slate-300 rounded-md px-3 py-2.5  text-center text-lg tracking-widest focus:outline-none focus:border-blue-500 mb-4"
            />
            <button
              onClick={handleVerifyOtp}
              disabled={loading || !otp.trim()}
              className="w-full bg-green-600 hover:bg-green-700 disabled:bg-slate-400 text-white py-2.5 rounded-md text-sm font-medium flex items-center justify-center gap-2"
            >
              {loading ? <Loader2 size={16} className="animate-spin" /> : null}
              {loading ? 'Verifying...' : 'Verify & Login'}
            </button>
            <button
              onClick={() => { setIsOtpSent(false); setOtp(''); }}
              className="w-full text-slate-500 hover:text-slate-700 text-sm mt-2 py-2"
            >
              ← Change mobile number
            </button>
            <p className="text-xs text-slate-400 mt-3 text-center">
              Check .NET terminal for OTP
            </p>
          </>
        )}
      </div>
    </div>
  );
};

export default Login;