import { useState } from "react";
import { Plus, X, Pencil, Trash2, Clock, User, FileText } from "lucide-react";

interface Appointment {
  id: string;
  time: string;
  client: string;
  type: string;
  notes: string;
  date: string;
}

const APPOINTMENT_TYPES = [
  "Initial Consultation",
  "Document Review",
  "Follow-Up",
  "Hearing Preparation",
  "Deposition",
  "Settlement Discussion",
  "Case Update",
  "Other",
];

const TODAY = new Date().toISOString().split("T")[0];

const INITIAL_APPOINTMENTS: Appointment[] = [
  { id: "1", time: "09:00", client: "Mark Grayson",   type: "Initial Consultation", notes: "New property dispute case.", date: TODAY },
  { id: "2", time: "11:30", client: "Randy Beans",    type: "Document Review",       notes: "Review estate documents.",   date: TODAY },
  { id: "3", time: "14:00", client: "Ben Poindexter", type: "Follow-Up",             notes: "Labor case follow-up.",      date: TODAY },
  { id: "4", time: "16:30", client: "Billy Buther",   type: "Hearing Preparation",   notes: "Prepare for Friday.",        date: TODAY },
];

const EMPTY_FORM = { time: "", client: "", type: APPOINTMENT_TYPES[0], notes: "", date: TODAY };

const TYPE_COLORS: Record<string, string> = {
  "Initial Consultation": "bg-[#f7f0f4] text-[#703d57]",
  "Document Review":      "bg-blue-50 text-blue-700",
  "Follow-Up":            "bg-amber-50 text-amber-700",
  "Hearing Preparation":  "bg-red-50 text-red-700",
  "Deposition":           "bg-purple-50 text-purple-700",
  "Settlement Discussion":"bg-emerald-50 text-emerald-700",
  "Case Update":          "bg-gray-100 text-gray-600",
  "Other":                "bg-gray-100 text-gray-600",
};

export function AppointmentsPage() {
  const [appointments, setAppointments] = useState<Appointment[]>(INITIAL_APPOINTMENTS);
  const [selectedDate, setSelectedDate] = useState(TODAY);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingAppt, setEditingAppt] = useState<Appointment | null>(null);
  const [form, setForm] = useState({ ...EMPTY_FORM });
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const dayAppts = appointments
    .filter((a) => a.date === selectedDate)
    .sort((a, b) => a.time.localeCompare(b.time));

  function openAdd() {
    setEditingAppt(null);
    setForm({ ...EMPTY_FORM, date: selectedDate });
    setModalOpen(true);
  }

  function openEdit(a: Appointment) {
    setEditingAppt(a);
    setForm({ time: a.time, client: a.client, type: a.type, notes: a.notes, date: a.date });
    setModalOpen(true);
  }

  function handleSave() {
    if (!form.time || !form.client || !form.date) return;
    if (editingAppt) {
      setAppointments((prev) => prev.map((a) => a.id === editingAppt.id ? { ...a, ...form } : a));
    } else {
      setAppointments((prev) => [...prev, { id: Date.now().toString(), ...form }]);
    }
    setModalOpen(false);
  }

  function handleDelete(id: string) {
    setAppointments((prev) => prev.filter((a) => a.id !== id));
    setDeleteId(null);
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Appointments</h1>
          <p className="mt-0.5 text-sm text-[#957186]">Schedule and manage client meetings</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 rounded-xl bg-[#703d57] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors"
        >
          <Plus className="h-4 w-4" />
          New Appointment
        </button>
      </div>

      {/* Date picker strip */}
      <div className="flex items-center gap-3">
        <label className="text-xs font-semibold text-[#703d57]">Date</label>
        <input
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="rounded-xl border border-[#d9b8c4]/60 bg-white px-3 py-2 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
        />
        <span className="text-xs text-gray-400">{dayAppts.length} appointment{dayAppts.length !== 1 ? "s" : ""}</span>
      </div>

      {/* Day schedule */}
      <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden">
        {dayAppts.length === 0 ? (
          <div className="py-16 text-center">
            <p className="text-gray-400 text-sm">No appointments for this day.</p>
            <button onClick={openAdd} className="mt-3 text-sm text-[#703d57] hover:underline font-medium">
              + Add one
            </button>
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {dayAppts.map((a) => (
              <div key={a.id} className="flex items-start gap-5 px-6 py-4 hover:bg-[#f7f0f4]/60 transition-colors group">
                {/* Time */}
                <div className="w-14 shrink-0 pt-0.5">
                  <p className="text-sm font-bold text-[#703d57]">{a.time}</p>
                </div>

                {/* Left accent */}
                <div className="w-0.5 self-stretch bg-[#d9b8c4] rounded-full shrink-0" />

                {/* Details */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <p className="font-semibold text-[#241715] text-sm">{a.client}</p>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${TYPE_COLORS[a.type] || "bg-gray-100 text-gray-600"}`}>
                      {a.type}
                    </span>
                  </div>
                  {a.notes && <p className="text-xs text-gray-400 mt-1">{a.notes}</p>}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={() => openEdit(a)} className="p-1.5 rounded-lg text-gray-400 hover:text-[#703d57] hover:bg-[#f7f0f4] transition-colors">
                    <Pencil className="h-3.5 w-3.5" />
                  </button>
                  <button onClick={() => setDeleteId(a.id)} className="p-1.5 rounded-lg text-gray-400 hover:text-red-600 hover:bg-red-50 transition-colors">
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Add/Edit Modal */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="font-bold text-[#241715] text-lg">{editingAppt ? "Edit Appointment" : "New Appointment"}</h2>
              <button onClick={() => setModalOpen(false)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-[#703d57] mb-1">
                    <Clock className="h-3 w-3 inline mr-1" />Date *
                  </label>
                  <input
                    type="date"
                    className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                    value={form.date}
                    onChange={(e) => setForm({ ...form, date: e.target.value })}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-[#703d57] mb-1">
                    <Clock className="h-3 w-3 inline mr-1" />Time *
                  </label>
                  <input
                    type="time"
                    className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                    value={form.time}
                    onChange={(e) => setForm({ ...form, time: e.target.value })}
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">
                  <User className="h-3 w-3 inline mr-1" />Client Name *
                </label>
                <input
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.client}
                  onChange={(e) => setForm({ ...form, client: e.target.value })}
                  placeholder="e.g. Mark Grayson"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">Appointment Type</label>
                <select
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  value={form.type}
                  onChange={(e) => setForm({ ...form, type: e.target.value })}
                >
                  {APPOINTMENT_TYPES.map((t) => <option key={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-[#703d57] mb-1">
                  <FileText className="h-3 w-3 inline mr-1" />Notes
                </label>
                <textarea
                  rows={3}
                  className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30 resize-none"
                  value={form.notes}
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                  placeholder="Optional notes..."
                />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => setModalOpen(false)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors">
                Cancel
              </button>
              <button onClick={handleSave} className="flex-1 rounded-xl bg-[#703d57] py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors">
                {editingAppt ? "Save Changes" : "Add Appointment"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl p-6">
            <h2 className="font-bold text-[#241715] text-lg mb-2">Delete Appointment?</h2>
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