import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { getAllSocietiesForSuperAdmin, type SocietyListDto } from "../api/tenant";
import { useAuth } from "../context/AuthContext";
import { Building, Loader2 } from "lucide-react";

export default function SuperAdminSocietyPicker() {
  const { currentUser, switchContext } = useAuth();
  const navigate = useNavigate();

  const [societies, setSocieties] = useState<SocietyListDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [switchingId, setSwitchingId] = useState<string | null>(null);

  useEffect(() => {
    const fetchSocieties = async () => {
      try {
        const data = await getAllSocietiesForSuperAdmin();
        setSocieties(data);
      } catch (err) {
        console.error("Failed to load societies", err);
      } finally {
        setLoading(false);
      }
    };
    fetchSocieties();
  }, []);
/*
  const handleSelectSociety = async (society: SocietyDto) => {
    setSwitchingId(society.societyId);
    try {
      // Create a mock User object to feed into switchContext
      const mockUserForContext = {
        id: currentUser?.id || "",
        name: society.societyName,
        flat: "SuperAdmin",
        societyId: society.societyId,
        flatId: "", // SuperAdmin has no flat
        role: "SuperAdmin",
        memberType: "SuperAdmin",
        isSuperAdmin: true,
      };

      await switchContext(mockUserForContext);
      navigate("/"); // Go to dashboard with the new Fat Token
    } catch (err) {
      console.error("Failed to switch context", err);
      setSwitchingId(null);
    }
  };*/
    const handleSelectSociety = async (society: SocietyListDto) => { // <-- USE NEW TYPE
    setSwitchingId(society.id);
    try {
      const mockUserForContext = {
        id: currentUser?.id || "",
        name: society.name,
        flat: "SuperAdmin",
        societyId: society.id, // <-- USE society.id
        flatId: "", 
        role: "SuperAdmin",
        memberType: "SuperAdmin",
        isSuperAdmin: true
      };

      await switchContext(mockUserForContext);
      navigate('/'); 
    } catch (err) {
      console.error("Failed to switch context", err);
      setSwitchingId(null);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col items-center justify-center p-8">
      <div className="max-w-4xl w-full">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-slate-800 flex items-center justify-center gap-3">
            <Building className="w-8 h-8 text-blue-600" /> SuperAdmin Portal
          </h1>
          <p className="text-slate-500 mt-2">
            Select a society to manage. You will enter its context with elevated
            permissions.
          </p>
        </div>

        {loading ? (
          <div className="flex justify-center py-10"><Loader2 className="animate-spin text-blue-500 w-8 h-8" /></div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {societies.map(s => (
              <button
                key={s.id} // <-- USE s.id
                onClick={() => handleSelectSociety(s)}
                disabled={switchingId !== null}
                className="bg-white p-6 rounded-lg shadow-sm border border-slate-200 hover:border-blue-500 hover:shadow-md transition text-left flex flex-col"
              >
                <h3 className="text-lg font-semibold text-slate-800">{s.name}</h3> {/* <-- USE s.name */}
                <p className="text-sm text-slate-500 mt-1">{s.address || s.city || 'Click to manage'}</p>
                <span className="mt-3 text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded w-fit">Society</span>
                
                {switchingId === s.id && <Loader2 className="animate-spin text-blue-500 w-4 h-4 mt-2 self-end" />}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
