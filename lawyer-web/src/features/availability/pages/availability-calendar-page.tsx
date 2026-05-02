import { useState } from "react";
import { ChevronLeft, ChevronRight, Clock, Plus, X, Check } from "lucide-react";
import { cn } from "@/lib/cn";

const DAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["January","February","March","April","May","June","July","August","September","October","November","December"];

const TIME_SLOTS = [
  "8:00 AM","8:30 AM","9:00 AM","9:30 AM","10:00 AM","10:30 AM",
  "11:00 AM","11:30 AM","12:00 PM","12:30 PM","1:00 PM","1:30 PM",
  "2:00 PM","2:30 PM","3:00 PM","3:30 PM","4:00 PM","4:30 PM",
  "5:00 PM",
];

interface Slot {
  id: string;
  date: string; // YYYY-MM-DD
  time: string;
  available: boolean;
  label?: string;
}

// Sample data — replace with API when backend is ready
const SAMPLE_SLOTS: Slot[] = [
  { id: "1", date: toDateStr(new Date()), time: "9:00 AM",  available: true },
  { id: "2", date: toDateStr(new Date()), time: "10:00 AM", available: true },
  { id: "3", date: toDateStr(new Date()), time: "2:00 PM",  available: false, label: "Initial Consultation – Mark G." },
  { id: "4", date: toDateStr(addDays(new Date(), 1)), time: "9:00 AM",  available: false, label: "Document Review – Randy B." },
  { id: "5", date: toDateStr(addDays(new Date(), 1)), time: "3:00 PM",  available: true },
  { id: "6", date: toDateStr(addDays(new Date(), 3)), time: "11:00 AM", available: true },
  { id: "7", date: toDateStr(addDays(new Date(), 3)), time: "1:00 PM",  available: true },
];

function toDateStr(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

function addDays(d: Date, n: number) {
  const r = new Date(d);
  r.setDate(r.getDate() + n);
  return r;
}

function getDaysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

function getFirstDayOfMonth(year: number, month: number) {
  return new Date(year, month, 1).getDay();
}

export function AvailabilityCalendarPage() {
  const today = new Date();
  const [viewYear, setViewYear] = useState(today.getFullYear());
  const [viewMonth, setViewMonth] = useState(today.getMonth());
  const [selectedDate, setSelectedDate] = useState<string>(toDateStr(today));
  const [slots, setSlots] = useState<Slot[]>(SAMPLE_SLOTS);
  const [addingSlot, setAddingSlot] = useState(false);
  const [newTime, setNewTime] = useState("");
  const [saved, setSaved] = useState(false);

  function prevMonth() {
    if (viewMonth === 0) { setViewYear((y) => y - 1); setViewMonth(11); }
    else setViewMonth((m) => m - 1);
  }

  function nextMonth() {
    if (viewMonth === 11) { setViewYear((y) => y + 1); setViewMonth(0); }
    else setViewMonth((m) => m + 1);
  }

  const daysInMonth = getDaysInMonth(viewYear, viewMonth);
  const firstDay = getFirstDayOfMonth(viewYear, viewMonth);

  // Days that have any slot
  const daysWithSlots = new Set(slots.map((s) => s.date));

  function slotsForDate(date: string) {
    return slots.filter((s) => s.date === date).sort((a, b) => a.time.localeCompare(b.time));
  }

  function toggleAvailability(id: string) {
    setSlots((prev) => prev.map((s) => s.id === id ? { ...s, available: !s.available } : s));
  }

  function removeSlot(id: string) {
    setSlots((prev) => prev.filter((s) => s.id !== id));
  }

  function addSlot() {
    if (!newTime || !selectedDate) return;
    const exists = slots.some((s) => s.date === selectedDate && s.time === newTime);
    if (exists) return;
    setSlots((prev) => [
      ...prev,
      { id: Date.now().toString(), date: selectedDate, time: newTime, available: true },
    ]);
    setNewTime("");
    setAddingSlot(false);
  }

  function handleSave() {
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
    // API call goes here when backend is ready
  }

  const selectedSlots = slotsForDate(selectedDate);
  const selectedDateObj = new Date(selectedDate + "T00:00:00");
  const isToday = (d: number) => {
    const dd = new Date(viewYear, viewMonth, d);
    return toDateStr(dd) === toDateStr(today);
  };

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Availability Calendar</h1>
          <p className="mt-0.5 text-sm text-[#957186]">Manage your schedule and available appointment slots</p>
        </div>
        <button
          onClick={handleSave}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#703d57] text-sm font-semibold text-white hover:bg-[#5a3046] transition"
        >
          {saved ? <><Check className="h-4 w-4" /> Saved!</> : "Save changes"}
        </button>
      </div>

      <div className="grid gap-5 lg:grid-cols-[1fr_340px]">
        {/* ── Calendar ── */}
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-5 shadow-sm">
          {/* Month nav */}
          <div className="flex items-center justify-between mb-5">
            <button onClick={prevMonth} className="p-2 rounded-xl hover:bg-[#f7f0f4] text-[#703d57] transition">
              <ChevronLeft className="h-4 w-4" />
            </button>
            <h2 className="text-sm font-bold text-[#241715]">{MONTHS[viewMonth]} {viewYear}</h2>
            <button onClick={nextMonth} className="p-2 rounded-xl hover:bg-[#f7f0f4] text-[#703d57] transition">
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>

          {/* Day headers */}
          <div className="grid grid-cols-7 mb-2">
            {DAYS.map((d) => (
              <div key={d} className="text-center text-xs font-semibold text-[#957186] py-1">{d}</div>
            ))}
          </div>

          {/* Day cells */}
          <div className="grid grid-cols-7 gap-1">
            {/* Empty cells for first day offset */}
            {Array.from({ length: firstDay }).map((_, i) => (
              <div key={`empty-${i}`} />
            ))}

            {Array.from({ length: daysInMonth }).map((_, i) => {
              const day = i + 1;
              const dateStr = `${viewYear}-${String(viewMonth + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
              const isSelected = dateStr === selectedDate;
              const hasSlots = daysWithSlots.has(dateStr);
              const daySlots = slotsForDate(dateStr);
              const hasAvailable = daySlots.some((s) => s.available);
              const hasBooked = daySlots.some((s) => !s.available);

              return (
                <button
                  key={day}
                  onClick={() => setSelectedDate(dateStr)}
                  className={cn(
                    "relative aspect-square flex flex-col items-center justify-center rounded-xl text-sm font-medium transition-all",
                    isSelected
                      ? "bg-[#703d57] text-white"
                      : isToday(day)
                      ? "bg-[#f7f0f4] text-[#703d57] font-bold"
                      : "text-[#241715] hover:bg-[#f7f0f4]"
                  )}
                >
                  {day}
                  {hasSlots && (
                    <div className="absolute bottom-1 flex gap-0.5">
                      {hasAvailable && (
                        <div className={cn("h-1 w-1 rounded-full", isSelected ? "bg-white/70" : "bg-emerald-500")} />
                      )}
                      {hasBooked && (
                        <div className={cn("h-1 w-1 rounded-full", isSelected ? "bg-white/50" : "bg-[#703d57]")} />
                      )}
                    </div>
                  )}
                </button>
              );
            })}
          </div>

          {/* Legend */}
          <div className="flex items-center gap-4 mt-4 pt-4 border-t border-[#d9b8c4]/30">
            <div className="flex items-center gap-1.5 text-xs text-[#957186]">
              <div className="h-2 w-2 rounded-full bg-emerald-500" />
              Available slot
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[#957186]">
              <div className="h-2 w-2 rounded-full bg-[#703d57]" />
              Booked
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[#957186]">
              <div className="h-2 w-2 rounded-full bg-[#f7f0f4] border border-[#703d57]" />
              Today
            </div>
          </div>
        </div>

        {/* ── Day Panel ── */}
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white p-5 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-sm font-bold text-[#241715]">
                {selectedDateObj.toLocaleDateString("en-PH", { weekday: "long", month: "long", day: "numeric" })}
              </h3>
              <p className="text-xs text-[#957186]">{selectedSlots.length} slot{selectedSlots.length !== 1 ? "s" : ""} scheduled</p>
            </div>
            <button
              onClick={() => setAddingSlot((v) => !v)}
              className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-[#f7f0f4] text-xs font-semibold text-[#703d57] hover:bg-[#eedde8] transition"
            >
              <Plus className="h-3.5 w-3.5" />
              Add slot
            </button>
          </div>

          {/* Add slot form */}
          {addingSlot && (
            <div className="mb-4 p-3 rounded-xl bg-[#f7f0f4] border border-[#d9b8c4]/40 space-y-2">
              <p className="text-xs font-semibold text-[#5a3046]">New available slot</p>
              <select
                value={newTime}
                onChange={(e) => setNewTime(e.target.value)}
                className="w-full rounded-lg border border-[#d9b8c4] bg-white px-3 py-2 text-xs text-[#241715] outline-none focus:border-[#703d57]"
              >
                <option value="">Select time…</option>
                {TIME_SLOTS.filter((t) => !slots.some((s) => s.date === selectedDate && s.time === t)).map((t) => (
                  <option key={t}>{t}</option>
                ))}
              </select>
              <div className="flex gap-2">
                <button onClick={addSlot} disabled={!newTime}
                  className="flex-1 py-1.5 rounded-lg bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] disabled:opacity-50 transition">
                  Add
                </button>
                <button onClick={() => { setAddingSlot(false); setNewTime(""); }}
                  className="flex-1 py-1.5 rounded-lg border border-[#d9b8c4] text-xs font-medium text-[#957186] hover:bg-white transition">
                  Cancel
                </button>
              </div>
            </div>
          )}

          {/* Slot list */}
          {selectedSlots.length === 0 ? (
            <div className="py-12 text-center">
              <Clock className="h-8 w-8 text-[#d9b8c4] mx-auto mb-2" />
              <p className="text-sm text-[#957186]">No slots for this day</p>
              <p className="text-xs text-[#c490aa] mt-1">Click "Add slot" to set availability</p>
            </div>
          ) : (
            <div className="space-y-2">
              {selectedSlots.map((slot) => (
                <div
                  key={slot.id}
                  className={cn(
                    "flex items-center gap-3 p-3 rounded-xl border transition-all",
                    slot.available
                      ? "bg-emerald-50 border-emerald-100"
                      : "bg-[#f7f0f4] border-[#d9b8c4]/40"
                  )}
                >
                  <Clock className={cn("h-3.5 w-3.5 shrink-0", slot.available ? "text-emerald-600" : "text-[#957186]")} />
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-[#241715]">{slot.time}</p>
                    {slot.label && (
                      <p className="text-[11px] text-[#957186] truncate mt-0.5">{slot.label}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-1.5">
                    {!slot.label && (
                      <button
                        onClick={() => toggleAvailability(slot.id)}
                        className={cn(
                          "px-2 py-0.5 rounded-lg text-[10px] font-semibold border transition",
                          slot.available
                            ? "bg-emerald-100 text-emerald-700 border-emerald-200 hover:bg-emerald-200"
                            : "bg-gray-100 text-gray-500 border-gray-200 hover:bg-gray-200"
                        )}
                      >
                        {slot.available ? "Open" : "Closed"}
                      </button>
                    )}
                    {slot.label && (
                      <span className="px-2 py-0.5 rounded-lg text-[10px] font-semibold bg-[#eedde8] text-[#703d57] border border-[#d9b8c4]">
                        Booked
                      </span>
                    )}
                    {!slot.label && (
                      <button
                        onClick={() => removeSlot(slot.id)}
                        className="p-1 rounded-lg text-gray-300 hover:text-red-400 hover:bg-red-50 transition"
                      >
                        <X className="h-3 w-3" />
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="rounded-xl bg-[#f7f0f4] border border-[#d9b8c4]/40 px-4 py-3 text-xs text-[#957186]">
        <strong className="text-[#5a3046]">Note:</strong> Changes are saved locally for now. Backend sync will be enabled once the API is connected.
      </div>
    </div>
  );
}