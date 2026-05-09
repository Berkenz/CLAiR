import { useState } from "react";
import { Plus, Search, X, Pencil, Trash2 } from "lucide-react";
import { cn } from "@/lib/cn";

type CaseStatus = "Active" | "Pending" | "Closed";

interface Case {
  id: string;
  initials: string;
  name: string;
  type: string;
  client: string;
  status: CaseStatus;
  date: string;
}

const INITIAL_CASES: Case[] = [
  { id: "1", initials: "ML", name: "Mijares vs. Lumbab",    type: "Property Dispute",  client: "Rosa Mijares",    status: "Active",  date: "2024-01-10" },
  { id: "2", initials: "CF", name: "Cutamora Family Trust", type: "Estate Planning",   client: "Leo Cutamora",    status: "Pending", date: "2024-02-14" },
  { id: "3", initials: "EL", name: "Eroja Labor",            type: "Employment Law",    client: "Danny Eroja",     status: "Active",  date: "2024-03-01" },
  { id: "4", initials: "CM", name: "Cadampog Marriage",      type: "Family Law",        client: "Ana Cadampog",    status: "Closed",  date: "2023-11-20" },
  { id: "5", initials: "RV", name: "Reyes vs. Villa",        type: "Civil Litigation",  client: "Marco Reyes",     status: "Active",  date: "2024-04-05" },
];

const STATUS_COLORS: Record<CaseStatus, string> = {
  Active:  "bg-emerald-100 text-emerald-700",
  Pending: "bg-amber-100 text-amber-700",
  Closed:  "bg-gray-100 text-gray-500",
};

const AVATAR_COLORS = ["bg-[#703d57]", "bg-[#957186]", "bg-[#402a2c]", "bg-[#d9b8c4] text-[#402a2c]", "bg-[#703d57]"];

const CASE_TYPES = ["Property Dispute", "Estate Planning", "Employment Law", "Family Law", "Civil Litigation", "Criminal Defense", "Corporate Law", "Other"];

const EMPTY_FORM = { name: "", type: CASE_TYPES[0], client: "", status: "Active" as CaseStatus, date: "" };

export function CasesPage() {
  const [cases, setCases] = useState<Case[]>(INITIAL_CASES);
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState<CaseStatus | "All">("All");
  const [modalOpen, setModalOpen] = useState(false);
  const [editingCase, setEditingCase] = useState<Case | null>(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const filtered = cases.filter((c) => {
    const matchSearch = c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.client.toLowerCase().includes(search.toLowerCase());
    const matchStatus = filterStatus === "All" || c.status === filterStatus;
    return matchSearch && matchStatus;
  });

  function openAdd() {
    setEditingCase(null);
    setForm(EMPTY_FORM);
    setModalOpen(true);
  }

  function openEdit(c: Case) {
    setEditingCase(c);
    setForm({ name: c.name, type: c.type, client: c.client, status: c.status, date: c.date });
    setModalOpen(true);
  }

  function handleSave() {
    if (!form.name || !form.client) return;
    const initials = form.name.split(" ").map((w) => w[0]).join("").slice(0, 2).toUpperCase();
    if (editingCase) {
      setCases((prev) => prev.map((c) => c.id === editingCase.id ? { ...c, ...form, initials } : c));
    } else {
      setCases((prev) => [...prev, { id: Date.now().toString(), initials, ...form }]);
    }
    setModalOpen(false);
  }

  function handleDelete(id: string) {
    setCases((prev) => prev.filter((c) => c.id !== id));
    setDeleteId(null);
  }

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Cases</h1>
          <p className="mt-0.5 text-sm text-[#957186]">Manage all your active and past cases</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 rounded-xl bg-[#703d57] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors"
        >
          <Plus className="h-4 w-4" />
          New Case
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            className="w-full rounded-xl border border-[#d9b8c4]/60 bg-white pl-9 pr-4 py-2.5 text-sm text-[#241715] placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
            placeholder="Search cases or clients..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
        <div className="flex gap-2">
          {(["All", "Active", "Pending", "Closed"] as const).map((s) => (
            <button
              key={s}
              onClick={() => setFilterStatus(s)}
              className={cn(
                "rounded-xl px-3 py-2.5 text-xs font-semibold transition-colors border",
                filterStatus === s
                  ? "bg-[#703d57] text-white border-[#703d57]"
                  : "bg-white text-[#402a2c] border-[#d9b8c4]/60 hover:bg-[#f7f0f4]"
              )}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden">
        {filtered.length === 0 ? (
          <div className="py-16 text-center text-gray-400 text-sm">No cases found.</div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-[#f7f0f4]">
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide">Case</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden sm:table-cell">Type</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden md:table-cell">Client</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide">Status</th>
                <th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody>
              {filtered.map((c, i) => (
                <tr key={c.id} className="border-b border-gray-50 hover:bg-[#f7f0f4]/60 transition-colors last:border-0">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className={`h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${AVATAR_COLORS[i % AVATAR_COLORS.length]}`}>
                        {c.initials}
                      </div>
                      <span className="font-medium text-[#241715]">{c.name}</span>
                    </div>
                  </td>
                  <td className="px-5 py-3.5 text-gray-500 hidden sm:table-cell">{c.type}</td>
                  <td className="px-5 py-3.5 text-gray-500 hidden md:table-cell">{c.client}</td>
                  <td className="px-5 py-3.5">
                    <span className={`inline-block text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[c.status]}`}>
                      {c.status}
                    </span>
                  </td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2 justify-end">
                      <button onClick={() => openEdit(c)} className="p-1.5 rounded-lg text-gray-400 hover:text-[#703d57] hover:bg-[#f7f0f4] transition-colors">
                        <Pencil className="h-3.5 w-3.5" />
                      </button>
                      <button onClick={() => setDeleteId(c.id)} className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors">
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Add/Edit Modal */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="font-bold text-[#241715] text-lg">{editingCase ? "Edit Case" : "New Case"}</h2>
              <button onClick={() => setModalOpen(false)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Case Name *</label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="e.g. Mijares vs. Lumbab"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Type</label>
                <select
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.type}
                  onChange={(e) => setForm({ ...form, type: e.target.value })}
                >
                  {CASE_TYPES.map((t) => <option key={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Client Name *</label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.client}
                  onChange={(e) => setForm({ ...form, client: e.target.value })}
                  placeholder="e.g. Rosa Mijares"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Status</label>
                <select
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.status}
                  onChange={(e) => setForm({ ...form, status: e.target.value as CaseStatus })}
                >
                  <option>Active</option>
                  <option>Pending</option>
                  <option>Closed</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Date Filed</label>
                <input
                  type="date"
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.date}
                  onChange={(e) => setForm({ ...form, date: e.target.value })}
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setModalOpen(false)}
                className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleSave}
                className="flex-1 rounded-xl bg-[#703d57] py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors"
              >
                {editingCase ? "Save Changes" : "Add Case"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl p-6">
            <h2 className="font-bold text-[#241715] text-lg mb-2">Delete Case?</h2>
            <p className="text-sm text-gray-500 mb-6">This action cannot be undone.</p>
            <div className="flex gap-3">
              <button onClick={() => setDeleteId(null)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors">Cancel</button>
              <button onClick={() => handleDelete(deleteId)} className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 transition-colors">Delete</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}