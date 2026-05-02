import { useState } from "react";
import { Send, Plus, X, Search, Trash2 } from "lucide-react";
import { cn } from "@/lib/cn";

interface Message {
  id: string;
  from: "me" | "them";
  text: string;
  time: string;
}

interface Conversation {
  id: string;
  name: string;
  initials: string;
  lastMessage: string;
  time: string;
  unread: number;
  messages: Message[];
}

const AVATAR_COLORS = ["bg-[#703d57]", "bg-[#957186]", "bg-[#402a2c]", "bg-[#d9b8c4] text-[#402a2c]"];

const INITIAL_CONVERSATIONS: Conversation[] = [
  {
    id: "1", name: "Mark Grayson", initials: "MG", lastMessage: "See you at 9AM.", time: "9:00 AM", unread: 1,
    messages: [
      { id: "a", from: "them", text: "Good morning, Atty. Just confirming our appointment tomorrow.", time: "8:50 AM" },
      { id: "b", from: "me",   text: "Good morning, Mark! Yes, we're confirmed for 9AM.", time: "8:55 AM" },
      { id: "c", from: "them", text: "See you at 9AM.", time: "9:00 AM" },
    ],
  },
  {
    id: "2", name: "Randy Beans", initials: "RB", lastMessage: "Can you send the updated docs?", time: "Yesterday", unread: 0,
    messages: [
      { id: "a", from: "them", text: "Hello Atty, I have some questions about the estate planning.", time: "Mon" },
      { id: "b", from: "me",   text: "Of course, Randy. What would you like to know?", time: "Mon" },
      { id: "c", from: "them", text: "Can you send the updated docs?", time: "Yesterday" },
    ],
  },
  {
    id: "3", name: "Ana Cadampog", initials: "AC", lastMessage: "Thank you, Attorney.", time: "Mon", unread: 0,
    messages: [
      { id: "a", from: "me",   text: "Hi Ana, your case has been officially closed. Congratulations!", time: "Mon" },
      { id: "b", from: "them", text: "Thank you, Attorney.", time: "Mon" },
    ],
  },
];

export function MessagesPage() {
  const [conversations, setConversations] = useState<Conversation[]>(INITIAL_CONVERSATIONS);
  const [activeId, setActiveId] = useState<string | null>(INITIAL_CONVERSATIONS[0].id);
  const [input, setInput] = useState("");
  const [search, setSearch] = useState("");
  const [newModal, setNewModal] = useState(false);
  const [newName, setNewName] = useState("");
  const [deleteId, setDeleteId] = useState<string | null>(null);

  const active = conversations.find((c) => c.id === activeId) ?? null;
  const filtered = conversations.filter((c) =>
    c.name.toLowerCase().includes(search.toLowerCase())
  );

  function sendMessage() {
    if (!input.trim() || !activeId) return;
    const now = new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    setConversations((prev) =>
      prev.map((c) =>
        c.id === activeId
          ? { ...c, lastMessage: input, time: now, messages: [...c.messages, { id: Date.now().toString(), from: "me", text: input, time: now }] }
          : c
      )
    );
    setInput("");
  }

  function markRead(id: string) {
    setConversations((prev) => prev.map((c) => c.id === id ? { ...c, unread: 0 } : c));
    setActiveId(id);
  }

  function startNewConversation() {
    if (!newName.trim()) return;
    const initials = newName.split(" ").map((w) => w[0]).join("").slice(0, 2).toUpperCase();
    const newConv: Conversation = {
      id: Date.now().toString(), name: newName, initials, lastMessage: "", time: "Now", unread: 0, messages: [],
    };
    setConversations((prev) => [newConv, ...prev]);
    setActiveId(newConv.id);
    setNewModal(false);
    setNewName("");
  }

  function deleteConversation(id: string) {
    setConversations((prev) => prev.filter((c) => c.id !== id));
    if (activeId === id) setActiveId(conversations.find((c) => c.id !== id)?.id ?? null);
    setDeleteId(null);
  }

  return (
    <div className="max-w-5xl mx-auto">
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Messages</h1>
          <p className="mt-0.5 text-sm text-[#957186]">Client communications</p>
        </div>
        <button
          onClick={() => setNewModal(true)}
          className="flex items-center gap-2 rounded-xl bg-[#703d57] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors"
        >
          <Plus className="h-4 w-4" />
          New Message
        </button>
      </div>

      <div className="flex rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden" style={{ height: "calc(100vh - 220px)" }}>
        {/* Sidebar */}
        <div className="w-72 shrink-0 border-r border-gray-100 flex flex-col">
          <div className="p-3 border-b border-gray-100">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-gray-400" />
              <input
                className="w-full rounded-lg border border-[#d9b8c4]/40 bg-[#f7f0f4] pl-8 pr-3 py-2 text-xs text-[#241715] placeholder:text-gray-400 focus:outline-none"
                placeholder="Search conversations..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
          <div className="flex-1 overflow-y-auto">
            {filtered.map((c, i) => (
              <div
                key={c.id}
                onClick={() => markRead(c.id)}
                className={cn(
                  "flex items-start gap-3 px-4 py-3.5 cursor-pointer border-b border-gray-50 hover:bg-[#f7f0f4]/70 transition-colors group",
                  activeId === c.id && "bg-[#f7f0f4]"
                )}
              >
                <div className={`h-9 w-9 rounded-full flex items-center justify-center text-xs font-bold text-white shrink-0 ${AVATAR_COLORS[i % AVATAR_COLORS.length]}`}>
                  {c.initials}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className={cn("text-sm truncate", c.unread > 0 ? "font-bold text-[#241715]" : "font-medium text-[#402a2c]")}>{c.name}</p>
                    <span className="text-[10px] text-gray-400 shrink-0 ml-2">{c.time}</span>
                  </div>
                  <p className="text-xs text-gray-400 truncate mt-0.5">{c.lastMessage}</p>
                </div>
                {c.unread > 0 && (
                  <div className="h-4 w-4 rounded-full bg-[#703d57] flex items-center justify-center text-[9px] font-bold text-white shrink-0 mt-0.5">
                    {c.unread}
                  </div>
                )}
                <button
                  onClick={(e) => { e.stopPropagation(); setDeleteId(c.id); }}
                  className="opacity-0 group-hover:opacity-100 p-1 rounded text-gray-300 hover:text-red-500 transition-all"
                >
                  <Trash2 className="h-3 w-3" />
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Thread */}
        {active ? (
          <div className="flex flex-col flex-1 min-w-0">
            {/* Thread header */}
            <div className="flex items-center gap-3 px-5 py-3.5 border-b border-gray-100">
              <div className={`h-8 w-8 rounded-full flex items-center justify-center text-xs font-bold text-white ${AVATAR_COLORS[conversations.findIndex(c => c.id === active.id) % AVATAR_COLORS.length]}`}>
                {active.initials}
              </div>
              <div>
                <p className="text-sm font-semibold text-[#241715]">{active.name}</p>
                <p className="text-xs text-gray-400">Client</p>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3">
              {active.messages.map((m) => (
                <div key={m.id} className={cn("flex", m.from === "me" ? "justify-end" : "justify-start")}>
                  <div className={cn(
                    "max-w-[72%] rounded-2xl px-4 py-2.5 text-sm",
                    m.from === "me"
                      ? "bg-[#703d57] text-white rounded-br-sm"
                      : "bg-[#f7f0f4] text-[#241715] rounded-bl-sm"
                  )}>
                    <p>{m.text}</p>
                    <p className={cn("text-[10px] mt-1", m.from === "me" ? "text-white/60 text-right" : "text-gray-400")}>{m.time}</p>
                  </div>
                </div>
              ))}
            </div>

            {/* Input */}
            <div className="border-t border-gray-100 p-4">
              <div className="flex gap-3">
                <input
                  className="flex-1 rounded-xl border border-[#d9b8c4]/60 px-4 py-2.5 text-sm text-[#241715] placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                  placeholder="Type a message..."
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && sendMessage()}
                />
                <button
                  onClick={sendMessage}
                  className="flex items-center justify-center h-10 w-10 rounded-xl bg-[#703d57] text-white hover:bg-[#5a3046] transition-colors shrink-0"
                >
                  <Send className="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-400 text-sm">
            Select a conversation to start messaging.
          </div>
        )}
      </div>

      {/* New Conversation Modal */}
      {newModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-bold text-[#241715] text-lg">New Conversation</h2>
              <button onClick={() => setNewModal(false)} className="p-1 rounded-lg text-gray-400 hover:text-gray-700"><X className="h-5 w-5" /></button>
            </div>
            <div>
              <label className="block text-xs font-semibold text-[#703d57] mb-1">Client Name</label>
              <input
                className="w-full rounded-xl border border-[#d9b8c4]/60 px-3 py-2.5 text-sm text-[#241715] focus:outline-none focus:ring-2 focus:ring-[#703d57]/30"
                placeholder="e.g. Rosa Mijares"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && startNewConversation()}
              />
            </div>
            <div className="flex gap-3 mt-5">
              <button onClick={() => setNewModal(false)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors">Cancel</button>
              <button onClick={startNewConversation} className="flex-1 rounded-xl bg-[#703d57] py-2.5 text-sm font-semibold text-white hover:bg-[#5a3046] transition-colors">Start Chat</button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-sm rounded-2xl bg-white shadow-xl p-6">
            <h2 className="font-bold text-[#241715] text-lg mb-2">Delete Conversation?</h2>
            <p className="text-sm text-gray-500 mb-6">All messages will be permanently removed.</p>
            <div className="flex gap-3">
              <button onClick={() => setDeleteId(null)} className="flex-1 rounded-xl border border-[#d9b8c4]/60 py-2.5 text-sm font-semibold text-[#402a2c] hover:bg-[#f7f0f4] transition-colors">Cancel</button>
              <button onClick={() => deleteConversation(deleteId)} className="flex-1 rounded-xl bg-red-600 py-2.5 text-sm font-semibold text-white hover:bg-red-700 transition-colors">Delete</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}