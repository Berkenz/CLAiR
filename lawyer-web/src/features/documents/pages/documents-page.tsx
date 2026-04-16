import { useState } from "react";
import { Plus, Search, Trash2, Download, FileText, X, FolderOpen, File } from "lucide-react";
import { cn } from "@/lib/cn";

type DocCategory = "Contract" | "Court Filing" | "Evidence" | "Correspondence" | "Other";

interface Document {
  id: string;
  name: string;
  category: DocCategory;
  caseRef: string;
  size: string;
  date: string;
}

const CATEGORIES: DocCategory[] = ["Contract", "Court Filing", "Evidence", "Correspondence", "Other"];

const CATEGORY_COLORS: Record<DocCategory, string> = {
  "Contract":       "bg-[#f7f0f4] text-[#703d57]",
  "Court Filing":   "bg-blue-50 text-blue-700",
  "Evidence":       "bg-amber-50 text-amber-700",
  "Correspondence": "bg-emerald-50 text-emerald-700",
  "Other":          "bg-gray-100 text-gray-500",
};

const INITIAL_DOCS: Document[] = [
  { id: "1", name: "Mijares_Complaint_Filed.pdf",      category: "Court Filing",   caseRef: "Mijares vs. Lumbab",    size: "1.2 MB", date: "2024-01-15" },
  { id: "2", name: "Cutamora_Trust_Agreement.docx",    category: "Contract",       caseRef: "Cutamora Family Trust", size: "845 KB", date: "2024-02-20" },
  { id: "3", name: "Eroja_Employment_Contract.pdf",    category: "Contract",       caseRef: "Eroja Labor",           size: "540 KB", date: "2024-03-05" },
  { id: "4", name: "Cadampog_Decree_Final.pdf",        category: "Court Filing",   caseRef: "Cadampog Marriage",     size: "2.1 MB", date: "2023-11-22" },
  { id: "5", name: "Reyes_Evidence_Photos.zip",        category: "Evidence",       caseRef: "Reyes vs. Villa",       size: "14 MB",  date: "2024-04-10" },
  { id: "6", name: "Client_Letter_Grayson.docx",       category: "Correspondence", caseRef: "Mark Grayson",          size: "120 KB", date: "2024-04-12" },
];

const EMPTY_FORM = { name: "", category: "Contract" as DocCategory, caseRef: "", size: "—" };

export function DocumentsPage() {
  const [docs, setDocs] = useState<Document[]>(INITIAL_DOCS);
  const [search, setSearch] = useState("");
  const [filterCat, setFilterCat] = useState<DocCategory | "All">("All");
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState({ ...EMPTY_FORM });
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const filtered = docs.filter((d) => {
    const matchSearch = d.name.toLowerCase().includes(search.toLowerCase()) ||
      d.caseRef.toLowerCase().includes(search.toLowerCase());
    const matchCat = filterCat === "All" || d.category === filterCat;
    return matchSearch && matchCat;
  });

  function handleAdd() {
    if (!form.name) return;
    const today = new Date().toISOString().split("T")[0];
    setDocs((prev) => [{ id: Date.now().toString(), ...form, date: today }, ...prev]);
    setModalOpen(false);
    setForm({ ...EMPTY_FORM });
  }

  function handleDelete(id: string) {
    setDocs((prev) => prev.filter((d) => d.id !== id));
    setDeleteId(null);
  }

  const totalCount = docs.length;
  const categoryCounts = CATEGORIES.map((c) => ({ cat: c, count: docs.filter((d) => d.category === c).length }));

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Documents</h1>
          <p className="mt-0.5 text-sm text-[#957186]">{totalCount} documents generated</p>
        </div>
        <button
          onClick={() => setModalOpen(true)}
          className="flex items-center gap-2 rounded-xl bg-[#703d57] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors"
        >
          <Plus className="h-4 w-4" />
          Add Document
        </button>
      </div>

      {/* Category summary cards */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {categoryCounts.map(({ cat, count }) => (
          <button
            key={cat}
            onClick={() => setFilterCat(filterCat === cat ? "All" : cat)}
            className={cn(
              "rounded-xl border p-3 text-left transition-all",
              filterCat === cat
                ? "border-[#703d57] bg-[#703d57] text-white shadow-md"
                : "border-[#d9b8c4]/40 bg-white hover:bg-[#f7f0f4]"
            )}
          >
            <p className={cn("text-lg font-bold", filterCat === cat ? "text-white" : "text-[#241715]")}>{count}</p>
            <p className={cn("text-xs mt-0.5 leading-tight", filterCat === cat ? "text-white/80" : "text-gray-500")}>{cat}</p>
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
        <input
          className="w-full rounded-xl border border-[#d9b8c4]/60 bg-white pl-9 pr-4 py-2.5 text-sm text-[#241715] placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
          placeholder="Search documents or case..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {/* Documents list */}
      <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden">
        {filtered.length === 0 ? (
          <div className="py-16 text-center">
            <FolderOpen className="h-10 w-10 text-[#d9b8c4] mx-auto mb-3" />
            <p className="text-gray-400 text-sm">No documents found.</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-[#f7f0f4]">
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide">Document</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden sm:table-cell">Category</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden md:table-cell">Case / Client</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden lg:table-cell">Date</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-[#703d57] uppercase tracking-wide hidden lg:table-cell">Size</th>
                <th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody>
              {filtered.map((d) => (
                <tr key={d.id} className="border-b border-gray-50 hover:bg-[#f7f0f4]/60 transition-colors last:border-0">
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-3">
                      <div className="h-8 w-8 rounded-lg bg-[#f7f0f4] flex items-center justify-center shrink-0">
                        <File className="h-4 w-4 text-[#703d57]" />
                      </div>
                      <span className="font-medium text-[#241715] truncate max-w-[180px]" title={d.name}>{d.name}</span>
                    </div>
                  </td>
                  <td className="px-5 py-3.5 hidden sm:table-cell">
                    <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${CATEGORY_COLORS[d.category]}`}>{d.category}</span>
                  </td>
                  <td className="px-5 py-3.5 text-gray-500 hidden md:table-cell">{d.caseRef}</td>
                  <td className="px-5 py-3.5 text-gray-400 text-xs hidden lg:table-cell">{d.date}</td>
                  <td className="px-5 py-3.5 text-gray-400 text-xs hidden lg:table-cell">{d.size}</td>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2 justify-end">
                      <button
                        title="Download"
                        className="p-1.5 rounded-lg text-gray-400 hover:text-[#703d57] hover:bg-[#f7f0f4] transition-colors"
                      >
                        <Download className="h-3.5 w-3.5" />
                      </button>
                      <button
                        onClick={() => setDeleteId(d.id)}
                        className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors"
                      >
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

      {/* Add Modal */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="font-bold text-[#241715] text-lg">Add Document</h2>
              <button onClick={() => setModalOpen(false)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">
                  <FileText className="h-3 w-3 inline mr-1" />Document Name *
                </label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="e.g. Mijares_Complaint.pdf"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Category</label>
                <select
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.category}
                  onChange={(e) => setForm({ ...form, category: e.target.value as DocCategory })}
                >
                  {CATEGORIES.map((c) => <option key={c}>{c}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Case / Client</label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.caseRef}
                  onChange={(e) => setForm({ ...form, caseRef: e.target.value })}
                  placeholder="e.g. Mijares vs. Lumbab"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">File Size</label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.size}
                  onChange={(e) => setForm({ ...form, size: e.target.value })}
                  placeholder="e.g. 1.2 MB"
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModalOpen(false)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors">Cancel</button>
              <button onClick={handleAdd} className="flex-1 rounded-xl bg-[#703d57] py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors">Add Document</button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl p-6">
            <h2 className="font-bold text-[#241715] text-lg mb-2">Delete Document?</h2>
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