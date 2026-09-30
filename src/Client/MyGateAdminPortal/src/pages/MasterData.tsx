// src/pages/MasterData.tsx
import { useState, useEffect } from "react";
import {
  getAllSocieties,
  getBlocksBySociety,
  getFlatsByBlock,
  createSociety,
  createBlock,
  createFlat,
  type Society,
  type Block,
  type Flat,
} from "../api/tenantAdmin";
import { Plus, Loader2 } from "lucide-react";

const MasterData = () => {
  // State
  const [societies, setSocieties] = useState<Society[]>([]);
  const [blocks, setBlocks] = useState<Block[]>([]);
  const [flats, setFlats] = useState<Flat[]>([]);

  const [selectedSociety, setSelectedSociety] = useState<string>("");
  const [selectedBlock, setSelectedBlock] = useState<string>("");

  const [loading, setLoading] = useState(false);

  // Modals
  const [showSocietyModal, setShowSocietyModal] = useState(false);
  const [showBlockModal, setShowBlockModal] = useState(false);
  const [showFlatModal, setShowFlatModal] = useState(false);

  // Form fields
  const [societyName, setSocietyName] = useState("");
  const [societyAddress, setSocietyAddress] = useState("");
  const [societyCity, setSocietyCity] = useState("");
  const [blockName, setBlockName] = useState("");
  const [flatNumber, setFlatNumber] = useState("");
  const [flatType, setFlatType] = useState<string>("2BHK"); // Default to 2BHK

  // Fetch Societies on mount
  useEffect(() => {
    fetchSocieties();
  }, []);

  const FLAT_TYPES = ["1BHK", "2BHK", "3BHK", "4BHK", "Villa", "Studio"];

  const fetchSocieties = async () => {
    setLoading(true);
    try {
      const data = await getAllSocieties();
      setSocieties(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Fetch Blocks when society changes
  useEffect(() => {
    if (!selectedSociety) {
      setBlocks([]);
      setFlats([]);
      return;
    }
    const fetchBlocks = async () => {
      try {
        const data = await getBlocksBySociety(selectedSociety);
        setBlocks(data);
        setFlats([]);
        setSelectedBlock("");
      } catch (err) {
        console.error(err);
      }
    };
    fetchBlocks();
  }, [selectedSociety]);

  // Fetch Flats when block changes
  useEffect(() => {
    if (!selectedBlock) {
      setFlats([]);
      return;
    }
    const fetchFlats = async () => {
      try {
        const data = await getFlatsByBlock(selectedBlock);
        setFlats(data);
      } catch (err) {
        console.error(err);
      }
    };
    fetchFlats();
  }, [selectedBlock]);

  // Handlers
  const handleCreateSociety = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await createSociety({
        name: societyName,
        address: societyAddress,
        city: societyCity,
      });
      setShowSocietyModal(false);
      setSocietyName("");
      setSocietyAddress("");
      setSocietyCity("");
      fetchSocieties();
    } catch (err) {
      alert("Failed to create society");
    }
  };

  const handleCreateBlock = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await createBlock({ societyId: selectedSociety, name: blockName });
      setShowBlockModal(false);
      setBlockName("");
      // Refresh blocks
      const data = await getBlocksBySociety(selectedSociety);
      setBlocks(data);
    } catch (err) {
      alert("Failed to create block");
    }
  };

  const handleCreateFlat = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await createFlat({
        blockId: selectedBlock,
        societyId: selectedSociety,
        flatNumber,
        flatType: flatType
      });
      setShowFlatModal(false);
      setFlatNumber("");
      setFlatType("2BHK"); // Reset dropdown
      // Refresh flats
      const data = await getFlatsByBlock(selectedBlock);
      setFlats(data);
    } catch (err) {
      alert("Failed to create flat");
    }
  };

  return (
    <div className="p-8">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Master Data Management</h1>
        <button
          onClick={() => setShowSocietyModal(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md transition"
        >
          <Plus size={18} /> New Society
        </button>
      </div>

      {loading ? (
        <div className="flex justify-center py-10">
          <Loader2 className="animate-spin" size={24} />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Column 1: Societies */}
          <div className="bg-white rounded-lg shadow border border-slate-200">
            <div className="p-4 border-b bg-slate-50 font-semibold">
              Societies ({societies.length})
            </div>
            <div className="divide-y max-h-[60vh] overflow-y-auto">
              {societies.map((s) => (
                <div
                  key={s.id}
                  onClick={() => setSelectedSociety(s.id)}
                  className={`p-4 cursor-pointer hover:bg-blue-50 transition ${selectedSociety === s.id ? "bg-blue-100 border-l-4 border-blue-500" : ""}`}
                >
                  <p className="font-medium text-slate-800">{s.name}</p>
                  <p className="text-xs text-slate-500">{s.city}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Column 2: Blocks */}
          <div className="bg-white rounded-lg shadow border border-slate-200">
            <div className="p-4 border-b bg-slate-50 font-semibold flex justify-between items-center">
              <span>Blocks ({blocks.length})</span>
              {selectedSociety && (
                <button
                  onClick={() => setShowBlockModal(true)}
                  className="text-xs bg-blue-600 text-white px-2 py-1 rounded flex items-center gap-1"
                >
                  <Plus size={12} /> Add
                </button>
              )}
            </div>
            <div className="divide-y max-h-[60vh] overflow-y-auto">
              {!selectedSociety ? (
                <div className="p-4 text-slate-400 text-center">
                  Select a society
                </div>
              ) : (
                blocks.map((b) => (
                  <div
                    key={b.id}
                    onClick={() => setSelectedBlock(b.id)}
                    className={`p-4 cursor-pointer hover:bg-green-50 transition ${selectedBlock === b.id ? "bg-green-100 border-l-4 border-green-500" : ""}`}
                  >
                    <p className="font-medium text-slate-800">{b.name}</p>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Column 3: Flats */}
          <div className="bg-white rounded-lg shadow border border-slate-200">
            <div className="p-4 border-b bg-slate-50 font-semibold flex justify-between items-center">
              <span>Flats ({flats.length})</span>
              {selectedBlock && (
                <button
                  onClick={() => setShowFlatModal(true)}
                  className="text-xs bg-green-600 text-white px-2 py-1 rounded flex items-center gap-1"
                >
                  <Plus size={12} /> Add
                </button>
              )}
            </div>
            <div className="divide-y max-h-[60vh] overflow-y-auto">
              {!selectedBlock ? (
                <div className="p-4 text-slate-400 text-center">
                  Select a block
                </div>
              ) : (
                flats.map((f) => (
                  <div key={f.id} className="p-4">
                    <p className="font-medium text-slate-800">{f.flatNumber}</p>
                     <span className="text-xs bg-slate-100 text-slate-600 px-2 py-1 rounded">{f.flatType}</span>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* --- Modals --- */}

      {showSocietyModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[400px]">
            <h2 className="text-xl font-bold mb-4">Create Society</h2>
            <form onSubmit={handleCreateSociety} className="space-y-3">
              <input
                type="text"
                placeholder="Name"
                value={societyName}
                onChange={(e) => setSocietyName(e.target.value)}
                className="w-full border p-2 rounded"
                required
              />
              <input
                type="text"
                placeholder="Address"
                value={societyAddress}
                onChange={(e) => setSocietyAddress(e.target.value)}
                className="w-full border p-2 rounded"
                required
              />
              <input
                type="text"
                placeholder="City"
                value={societyCity}
                onChange={(e) => setSocietyCity(e.target.value)}
                className="w-full border p-2 rounded"
                required
              />
              <div className="flex gap-2 justify-end pt-2">
                <button
                  type="button"
                  onClick={() => setShowSocietyModal(false)}
                  className="px-4 py-2 border rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showBlockModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[300px]">
            <h2 className="text-xl font-bold mb-4">Create Block</h2>
            <form onSubmit={handleCreateBlock} className="space-y-3">
              <input
                type="text"
                placeholder="Block Name (e.g. Block A)"
                value={blockName}
                onChange={(e) => setBlockName(e.target.value)}
                className="w-full border p-2 rounded"
                required
              />
              <div className="flex gap-2 justify-end pt-2">
                <button
                  type="button"
                  onClick={() => setShowBlockModal(false)}
                  className="px-4 py-2 border rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-blue-600 text-white rounded"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {showFlatModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg w-[300px]">
            <h2 className="text-xl font-bold mb-4">Create Flat</h2>
            <form onSubmit={handleCreateFlat} className="space-y-3">
              <input
                type="text"
                placeholder="Flat Number (e.g. 101)"
                value={flatNumber}
                onChange={(e) => setFlatNumber(e.target.value)}
                className="w-full border p-2 rounded"
                required
              />
              {/* NEW: Flat Type Dropdown */}
              <select
                value={flatType}
                onChange={(e) => setFlatType(e.target.value)}
                className="w-full border p-2 rounded bg-white"
              >
                {FLAT_TYPES.map((type) => (
                  <option key={type} value={type}>
                    {type}
                  </option>
                ))}
              </select>

              <div className="flex gap-2 justify-end pt-2">
                <button
                  type="button"
                  onClick={() => setShowFlatModal(false)}
                  className="px-4 py-2 border rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-green-600 text-white rounded"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default MasterData;
