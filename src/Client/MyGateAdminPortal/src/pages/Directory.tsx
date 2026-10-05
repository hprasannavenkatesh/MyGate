import { useState, useEffect } from 'react';
import { getDirectory, getCategories, type DirectoryEntryDto } from '../api/directory';
import { useAuth } from '../context/AuthContext';
import { Loader2, Phone } from 'lucide-react';

const Directory = () => {
  const { currentUser } = useAuth();
  const [entries, setEntries] = useState<DirectoryEntryDto[]>([]);
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch = async () => {
      if (!currentUser?.societyId) return;
      setLoading(true);
      try {
        const [e, c] = await Promise.all([
          getDirectory(currentUser.societyId),
          getCategories(currentUser.societyId)
        ]);
        setEntries(e);
        setCategories(c);
      } catch (err) {
        console.error('Failed to fetch directory', err);
      } finally {
        setLoading(false);
      }
    };
    fetch();
  }, [currentUser?.societyId]);

  const filtered = selectedCategory
    ? entries.filter(e => e.category === selectedCategory)
    : entries;

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Society Directory</h1>

      {/* Category filter */}
      <div className="flex gap-2 mb-6 flex-wrap">
        <button onClick={() => setSelectedCategory('')}
          className={`px-3 py-1 rounded-full text-sm font-medium ${!selectedCategory ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-600'}`}>
          All
        </button>
        {categories.map(c => (
          <button key={c} onClick={() => setSelectedCategory(c)}
            className={`px-3 py-1 rounded-full text-sm font-medium ${selectedCategory === c ? 'bg-blue-600 text-white' : 'bg-slate-100 text-slate-600'}`}>
            {c}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="flex justify-center py-10"><Loader2 className="animate-spin" size={24} /></div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map(e => (
            <div key={e.id} className="bg-white p-4 rounded-lg border shadow-sm">
              <div className="flex justify-between items-start mb-2">
                <h3 className="font-semibold">{e.name}</h3>
                <span className="text-xs bg-slate-100 text-slate-600 px-2 py-1 rounded">{e.category}</span>
              </div>
              <div className="text-sm text-slate-600 space-y-1">
                <div className="flex items-center gap-2"><Phone size={14} /> {e.contactNumber}</div>
                {e.email && <div className="text-xs">{e.email}</div>}
                {e.address && <div className="text-xs text-slate-400">{e.address}</div>}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Directory;