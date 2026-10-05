// src/pages/AssignMember.tsx
import { useState, useEffect } from 'react';
import {
  getAllSocieties,
  getBlocksBySociety,
  getFlatsByBlock,
  type Society,
  type Block,
  type Flat,
} from '../api/tenantAdmin';
import {
  lookupUser,
  addMember,
  registerUser,
  type UserLookupDto,
  type AddMemberPayload,
} from '../api/memberAdmin';
import { Search, UserPlus, Loader2, CheckCircle, AlertCircle, Home, Star } from 'lucide-react';

const MEMBER_TYPES = ['Owner', 'Tenant', 'CommitteeMember'] as const;
type MemberType = (typeof MEMBER_TYPES)[number];

const MEMBER_TYPE_COLORS: Record<MemberType, string> = {
  Owner: 'bg-green-100 text-green-700',
  Tenant: 'bg-blue-100 text-blue-700',
  CommitteeMember: 'bg-amber-100 text-amber-700',
};

const MEMBER_TYPE_DOT_COLORS: Record<MemberType, string> = {
  Owner: 'bg-green-500',
  Tenant: 'bg-blue-500',
  CommitteeMember: 'bg-amber-500',
};

interface AssignmentRecord {
  mobileNumber: string;
  fullName: string;
  flatNumber: string;
  societyName: string;
  memberType: MemberType;
  isPrimary: boolean;
  assignedAt: Date;
}

const AssignMember = () => {
  const [mobileNumber, setMobileNumber] = useState('');
  const [searchedMobile, setSearchedMobile] = useState('');
  const [foundUser, setFoundUser] = useState<UserLookupDto | null>(null);
  const [userNotFound, setUserNotFound] = useState(false);
  const [searchingUser, setSearchingUser] = useState(false);

  const [societies, setSocieties] = useState<Society[]>([]);
  const [blocks, setBlocks] = useState<Block[]>([]);
  const [flats, setFlats] = useState<Flat[]>([]);

  const [selectedSocietyId, setSelectedSocietyId] = useState('');
  const [selectedBlockId, setSelectedBlockId] = useState('');
  const [selectedFlatId, setSelectedFlatId] = useState('');

  const [memberType, setMemberType] = useState<MemberType>('Owner');
  const [isPrimary, setIsPrimary] = useState(false);

  const [loadingSocieties, setLoadingSocieties] = useState(false);
  const [loadingBlocks, setLoadingBlocks] = useState(false);
  const [loadingFlats, setLoadingFlats] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const [recentAssignments, setRecentAssignments] = useState<AssignmentRecord[]>([]);

    const [newUserName, setNewUserName] = useState('');
  const [newUserEmail, setNewUserEmail] = useState('');
  const [newUserPassword, setNewUserPassword] = useState('TempPass@123'); // Default temp password

  // ── Effects ──

  useEffect(() => {
    const fetchSocieties = async () => {
      setLoadingSocieties(true);
      try {
        const data = await getAllSocieties();
        setSocieties(data);
      } catch (err: any) {
        setError('Failed to load societies. ' + (err.message || ''));
      } finally {
        setLoadingSocieties(false);
      }
    };
    fetchSocieties();
  }, []);

  useEffect(() => {
    if (!selectedSocietyId) {
      setBlocks([]);
      setFlats([]);
      setSelectedBlockId('');
      setSelectedFlatId('');
      return;
    }
    const fetchBlocks = async () => {
      setLoadingBlocks(true);
      setBlocks([]);
      setFlats([]);
      setSelectedBlockId('');
      setSelectedFlatId('');
      try {
        const data = await getBlocksBySociety(selectedSocietyId);
        setBlocks(data);
      } catch (err) {
        setError('Failed to load blocks.');
      } finally {
        setLoadingBlocks(false);
      }
    };
    fetchBlocks();
  }, [selectedSocietyId]);

  useEffect(() => {
    if (!selectedBlockId) {
      setFlats([]);
      setSelectedFlatId('');
      return;
    }
    const fetchFlats = async () => {
      setLoadingFlats(true);
      setFlats([]);
      setSelectedFlatId('');
      try {
        const data = await getFlatsByBlock(selectedBlockId);
        setFlats(data);
      } catch (err) {
        setError('Failed to load flats.');
      } finally {
        setLoadingFlats(false);
      }
    };
    fetchFlats();
  }, [selectedBlockId]);

  // ── Handlers ──
  const handleRegisterUser = async () => {
    if (!mobileNumber || !newUserName || !newUserPassword) return;
    setSubmitting(true);
    setError('');
    try {
      const result = await registerUser({ 
        mobileNumber: mobileNumber, 
        fullName: newUserName, 
        email: newUserEmail || undefined,
        password: newUserPassword
      });
      
      // Auto-set the found user so the assignment form activates immediately
      setFoundUser({ 
        userId: result.id, 
        fullName: newUserName, 
        mobileNumber: mobileNumber, 
        email: newUserEmail || null, 
        isMobileVerified: false 
      });
      
      setUserNotFound(false);
      setSuccessMsg(`✅ User ${newUserName} registered successfully! You can now assign them to a flat.`);
    } catch (err: any) {
      setError('Registration failed: ' + (err.response?.data?.message || err.message));
    } finally {
      setSubmitting(false);
    }
  };


  const handleSearchUser = async () => {
    if (!mobileNumber.trim()) return;
    setSearchingUser(true);
    setFoundUser(null);
    setUserNotFound(false);
    setError('');
    setSuccessMsg('');
    setSearchedMobile(mobileNumber.trim());

    try {
      const user = await lookupUser(mobileNumber.trim());
      if (user) {
        setFoundUser(user);
      } else {
        setUserNotFound(true);
      }
    } catch (err: any) {
      setError('User search failed. ' + (err.response?.data?.message || err.message));
    } finally {
      setSearchingUser(false);
    }
  };

  const handleSubmit = async () => {
    if (!foundUser) { setError('Search for a user first.'); return; }
    if (!selectedSocietyId) { setError('Select a society.'); return; }
    if (!selectedBlockId) { setError('Select a block.'); return; }
    if (!selectedFlatId) { setError('Select a flat.'); return; }

    setError('');
    setSuccessMsg('');
    setSubmitting(true);

    const payload: AddMemberPayload = {
      societyId: selectedSocietyId,
      userId: foundUser.userId,
      flatId: selectedFlatId,
      memberType,
      isPrimary,
    };

    try {
      await addMember(payload);

      const societyName = societies.find(s => s.id === selectedSocietyId)?.name || '';
      const flatObj = flats.find(f => f.id === selectedFlatId);
      const flatDisplay = flatObj ? String(flatObj.flatNumber) : selectedFlatId;

      setRecentAssignments(prev => [{
        mobileNumber: searchedMobile,
        fullName: foundUser.fullName,
        flatNumber: flatDisplay,
        societyName,
        memberType,
        isPrimary,
        assignedAt: new Date(),
      }, ...prev]);

      setSuccessMsg(
        'Assigned ' + foundUser.fullName + ' as ' + memberType + ' of ' + flatDisplay
      );

      setMobileNumber('');
      setSearchedMobile('');
      setFoundUser(null);
      setUserNotFound(false);
    } catch (err: any) {
      const detail = err.response?.data?.detail
        || err.response?.data?.message
        || err.response?.data?.errors?.[0]
        || err.message;
      setError('Assignment failed: ' + detail);
    } finally {
      setSubmitting(false);
    }
  };

  const selectedSociety = societies.find(s => s.id === selectedSocietyId);
  const selectedBlock = blocks.find(b => b.id === selectedBlockId);
  const selectedFlat = flats.find(f => f.id === selectedFlatId);
  const isFormComplete = !!(foundUser && selectedSocietyId && selectedBlockId && selectedFlatId);

  // ── Render ──

  return (
    <div className="p-8 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center gap-3 mb-2">
        <UserPlus className="w-8 h-8 text-blue-600" />
        <h1 className="text-2xl font-bold">Assign Member</h1>
      </div>
      <p className="text-sm text-slate-500 mb-6">
        Search a registered user by mobile number, then assign them to a flat
        as Owner, Tenant, or Committee Member.
      </p>

      {/* Error */}
      {error && (
        <div className="flex items-start gap-2 bg-red-50 border border-red-200 text-red-700 p-4 rounded-lg mb-4">
          <AlertCircle size={18} className="mt-0.5 shrink-0" />
          <span className="text-sm">{error}</span>
          <button onClick={() => setError('')} className="ml-auto text-red-400 hover:text-red-600 text-lg leading-none">&times;</button>
        </div>
      )}

      {/* Success */}
      {successMsg && (
        <div className="flex items-start gap-2 bg-green-50 border border-green-200 text-green-700 p-4 rounded-lg mb-4">
          <CheckCircle size={18} className="mt-0.5 shrink-0" />
          <span className="text-sm font-medium">{successMsg}</span>
          <button onClick={() => setSuccessMsg('')} className="ml-auto text-green-400 hover:text-green-600 text-lg leading-none">&times;</button>
        </div>
      )}

      {/* ═══ 1. FIND USER ═══ */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">1. Find User</h2>

        <div className="flex gap-3">
          <input
            type="tel"
            placeholder="e.g. 9876543210"
            value={mobileNumber}
            onChange={(e) => {
              setMobileNumber(e.target.value);
              if (e.target.value !== searchedMobile) {
                setFoundUser(null);
                setUserNotFound(false);
              }
            }}
            onKeyDown={(e) => { if (e.key === 'Enter') handleSearchUser(); }}
            maxLength={15}
            disabled={searchingUser}
            className="flex-1 border border-slate-300 rounded-md px-4 py-2.5 text-sm focus:outline-none focus:border-blue-500 disabled:bg-slate-100"
          />
          <button
            onClick={handleSearchUser}
            disabled={searchingUser || !mobileNumber.trim()}
            className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white px-5 py-2.5 rounded-md transition text-sm font-medium"
          >
            {searchingUser ? <Loader2 size={16} className="animate-spin" /> : <Search size={16} />}
            {searchingUser ? 'Searching...' : 'Search'}
          </button>
        </div>

        {foundUser && (
          <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-lg">
            <div className="flex items-center gap-2 mb-1">
              <CheckCircle size={18} className="text-green-600" />
              <span className="font-semibold text-slate-800">{foundUser.fullName}</span>
              {foundUser.isMobileVerified && (
                <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full">Verified</span>
              )}
            </div>
            <p className="text-sm text-slate-500">
              Mobile: {foundUser.mobileNumber}
              {foundUser.email ? ' | Email: ' + foundUser.email : ''}
            </p>
            <p className="text-xs text-slate-400">User ID: {foundUser.userId}</p>
          </div>
        )}

        {userNotFound && (
          <div className="bg-amber-50 border border-amber-200 text-amber-700 p-4 rounded-lg mb-4">
            <div className="flex items-start gap-2 mb-3">
              <AlertCircle size={18} className="mt-0.5 shrink-0" />
              <span className="font-medium">No registered user found for <strong>{searchedMobile}</strong>.</span>
            </div>
            <p className="text-sm mb-3">Register them now to assign to a flat:</p>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <input
                type="text"
                placeholder="Full Name *"
                value={newUserName}
                onChange={(e) => setNewUserName(e.target.value)}
                className="border border-amber-300 rounded-md px-3 py-2 text-sm bg-white"
              />
              <input
                type="email"
                placeholder="Email (Optional)"
                value={newUserEmail}
                onChange={(e) => setNewUserEmail(e.target.value)}
                className="border border-amber-300 rounded-md px-3 py-2 text-sm bg-white"
              />
              <input
                type="password"
                placeholder="Password *"
                value={newUserPassword}
                onChange={(e) => setNewUserPassword(e.target.value)}
                className="border border-amber-300 rounded-md px-3 py-2 text-sm bg-white"
              />
            </div>
            <button
              onClick={handleRegisterUser}
              disabled={!newUserName || !newUserPassword}
              className="mt-3 bg-amber-600 hover:bg-amber-700 disabled:bg-slate-400 text-white px-4 py-2 rounded-md text-sm font-medium"
            >
              Register & Continue
            </button>
          </div>
        )}
      </div>

      {/* ═══ 2. SELECT FLAT ═══ */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">2. Select Flat</h2>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Society</label>
            <select
              value={selectedSocietyId}
              onChange={(e) => setSelectedSocietyId(e.target.value)}
              disabled={loadingSocieties}
              className="w-full border border-slate-300 rounded-md px-3 py-2.5 text-sm bg-white focus:outline-none focus:border-blue-500 disabled:bg-slate-100"
            >
              <option value="">{loadingSocieties ? 'Loading...' : '-- Select Society --'}</option>
              {societies.map((s) => (
                <option key={s.id} value={s.id}>{s.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Block</label>
            <select
              value={selectedBlockId}
              onChange={(e) => setSelectedBlockId(e.target.value)}
              disabled={!selectedSocietyId || loadingBlocks}
              className="w-full border border-slate-300 rounded-md px-3 py-2.5 text-sm bg-white focus:outline-none focus:border-blue-500 disabled:bg-slate-100"
            >
              <option value="">{loadingBlocks ? 'Loading...' : '-- Select Block --'}</option>
              {blocks.map((b) => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Flat</label>
            <select
              value={selectedFlatId}
              onChange={(e) => setSelectedFlatId(e.target.value)}
              disabled={!selectedBlockId || loadingFlats}
              className="w-full border border-slate-300 rounded-md px-3 py-2.5 text-sm bg-white focus:outline-none focus:border-blue-500 disabled:bg-slate-100"
            >
              <option value="">{loadingFlats ? 'Loading...' : '-- Select Flat --'}</option>
              {flats.map((f) => (
                <option key={f.id} value={f.id}>
                  {String(f.flatNumber)} - {String(f.flatType)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {selectedFlat && (
          <div className="mt-4 p-3 bg-slate-50 rounded-md flex items-center gap-2 text-sm text-slate-600">
            <Home size={16} className="text-slate-400" />
            <span>
              <strong>{selectedSociety?.name}</strong> &rarr;{' '}
              <strong>{selectedBlock?.name}</strong> &rarr;{' '}
              <strong>{String(selectedFlat.flatNumber)}</strong> ({String(selectedFlat.flatType)})
            </span>
          </div>
        )}
      </div>

      {/* ═══ 3. MEMBER TYPE + OPTIONS + SUBMIT ═══ */}
      <div className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 mb-6">
        <h2 className="text-lg font-semibold mb-4">3. Member Type</h2>

        <div className="flex gap-4 mb-4">
          {MEMBER_TYPES.map((type) => (
            <label
              key={type}
              className={
                'flex items-center gap-2 px-4 py-2.5 rounded-lg border-2 cursor-pointer transition ' +
                (memberType === type
                  ? 'border-blue-500 bg-blue-50'
                  : 'border-slate-200 hover:border-slate-300')
              }
            >
              <input
                type="radio"
                name="memberType"
                value={type}
                checked={memberType === type}
                onChange={() => setMemberType(type)}
                className="accent-blue-600"
              />
              <span className={'inline-flex items-center gap-1.5 text-sm font-medium px-2 py-0.5 rounded-full ' + MEMBER_TYPE_COLORS[type]}>
                <span className={'w-2 h-2 rounded-full ' + MEMBER_TYPE_DOT_COLORS[type]}></span>
                {type}
              </span>
            </label>
          ))}
        </div>

        {/* Is Primary */}
        {/* ✨ IsPrimary Checkbox & Smart Warning */}
        {/* Only show this option for Owners and CommitteeMembers. Tenants are rarely Primary Contacts. */}
        {memberType !== 'Tenant' && (
          <div className="mb-6">
            <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
              <input
                type="checkbox"
                checked={isPrimary}
                onChange={(e) => setIsPrimary(e.target.checked)}
                className="accent-blue-600 w-4 h-4"
              />
              <Star size={16} className={isPrimary ? 'text-amber-500' : 'text-slate-400'} />
              <span>
                Primary member
                <span className="text-slate-400 ml-1">(first owner / primary contact for this flat)</span>
              </span>
            </label>

            {/* Contextual Warning - only show if they check the box */}
            {isPrimary && (
              <p className="text-xs text-amber-600 mt-1.5 ml-6 flex items-center gap-1">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-3.(3).5 w-3.5" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M8.257 3.099c.765-1.47 2.4-1.47 3.165 0l5.941 11.43c.755 1.455-.345 2.971-1.58 2.971H3.896c-1.235 0-2.335-1.516-1.58-2.971L8.257 3.099zM11 7a1 1 0 10-2 0v3a1 1 0 002 0V7zm-1 7a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
                </svg>
                If this flat already has a Primary member, they will be automatically demoted to "Co-Owner".
              </p>
            )}
          </div>
        )}

        {/* Confirmation */}
        {isFormComplete && (
          <div className="bg-blue-50 border border-blue-200 text-blue-700 p-4 rounded-lg mb-4 text-sm">
            Assign <strong>{foundUser?.fullName}</strong> ({searchedMobile}) as{' '}
            <strong>{memberType}</strong> of{' '}
            <strong>{String(selectedFlat?.flatNumber)}</strong>{' '}
            in <strong>{selectedSociety?.name}</strong>
            {isPrimary ? ' (Primary)' : ''}?
          </div>
        )}

        <button
          onClick={handleSubmit}
          disabled={!isFormComplete || submitting}
          className="w-full flex items-center justify-center gap-2 bg-blue-600 hover:bg-blue-700 disabled:bg-slate-400 text-white py-3 rounded-md transition font-semibold text-base"
        >
          {submitting ? <Loader2 size={20} className="animate-spin" /> : <UserPlus size={20} />}
          {submitting ? 'Assigning...' : 'Assign Member'}
        </button>
      </div>

      {/* ═══ RECENT ASSIGNMENTS ═══ */}
      {recentAssignments.length > 0 && (
        <div className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
          <div className="p-4 border-b bg-slate-50 font-semibold">
            Recent Assignments (This Session)
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-slate-50 text-slate-500 text-sm uppercase border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3 font-medium">Mobile</th>
                  <th className="px-4 py-3 font-medium">Name</th>
                  <th className="px-4 py-3 font-medium">Society</th>
                  <th className="px-4 py-3 font-medium">Flat</th>
                  <th className="px-4 py-3 font-medium">Type</th>
                  <th className="px-4 py-3 font-medium">Primary</th>
                  <th className="px-4 py-3 font-medium">Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {recentAssignments.map((rec, idx) => (
                  <tr key={idx} className="hover:bg-slate-50">
                    <td className="px-4 py-3 text-sm text-slate-600">{rec.mobileNumber}</td>
                    <td className="px-4 py-3 text-sm font-medium text-slate-800">{rec.fullName}</td>
                    <td className="px-4 py-3 text-sm text-slate-600">{rec.societyName}</td>
                    <td className="px-4 py-3 text-sm font-medium text-slate-800">{rec.flatNumber}</td>
                    <td className="px-4 py-3">
                      <span className={'text-xs font-medium px-2 py-0.5 rounded-full ' + MEMBER_TYPE_COLORS[rec.memberType]}>
                        {rec.memberType}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-sm">
                      {rec.isPrimary ? '⭐' : '—'}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-500">
                      {rec.assignedAt.toLocaleTimeString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default AssignMember;