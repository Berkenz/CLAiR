import { useNavigate } from "react-router-dom";
import {
  Sparkles, MessageCircle, ClipboardCheck, ArrowRight,
  ChevronRight, Bot, FolderOpen, Clock,
} from "lucide-react";

const CLIENT_CONVERSATIONS = [
  {
    id: "conv-1",
    clientName: "Maria Santos",
    date: "May 1, 2026",
    preview: "Asked about annulment process in the Philippines",
    lastMessage: "Total estimated range: ₱200,000 – ₱600,000 or more…",
  },
  {
    id: "conv-2",
    clientName: "Juan dela Cruz",
    date: "Apr 29, 2026",
    preview: "Asked about small claims court procedure",
    lastMessage: "No — lawyers are not allowed in small claims proceedings…",
  },
  {
    id: "conv-3",
    clientName: "Rosa Reyes",
    date: "Apr 27, 2026",
    preview: "Asked about labor rights after termination",
    lastMessage: "You may file a complaint with the NLRC within 4 years…",
  },
];

const quickActions = [
  {
    label: "Client Convos",
    icon: MessageCircle,
    to: "/conversations",
    desc: "View client–AI chats",
    bg: "bg-[#703d57]",
  },
  {
    label: "Documents",
    icon: FolderOpen,
    to: "/documents",
    desc: "Generated files",
    bg: "bg-[#402a2c]",
  },
  {
    label: "AI Assessment",
    icon: Sparkles,
    to: "/ai-assessment",
    desc: "Chat or assess AI",
    bg: "bg-[#957186]",
  },
];

export function DashboardPage() {
  const navigate = useNavigate();

  return (
    <div className="space-y-6 max-w-5xl mx-auto">

      {/* Greeting */}
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">Hello, Atty. Mat. 👋</h1>
          <p className="mt-0.5 text-sm text-[#957186]">How can CLAiR help you today?</p>
        </div>
        <div className="hidden sm:flex items-center gap-2 text-xs text-[#957186] bg-white border border-[#d9b8c4]/40 rounded-xl px-3 py-2">
          <Clock className="h-3.5 w-3.5" />
          <span>{new Date().toLocaleDateString("en-PH", { weekday: "long", month: "long", day: "numeric", year: "numeric" })}</span>
        </div>
      </div>

      {/* Start new chat CTA */}
      <button
        onClick={() => navigate("/ai-assessment")}
        className="w-full flex items-center gap-4 bg-[#241715] hover:bg-[#402a2c] transition-colors rounded-2xl px-5 py-4 group"
      >
        <div className="h-10 w-10 rounded-xl bg-[#703d57] flex items-center justify-center shrink-0">
          <Sparkles className="h-5 w-5 text-white" />
        </div>
        <div className="flex-1 text-left">
          <p className="text-sm font-bold text-white">Start new chat with CLAiR AI</p>
          <p className="text-xs text-white/50 mt-0.5">Ask a legal question or get case insights</p>
        </div>
        <ArrowRight className="h-5 w-5 text-white/40 group-hover:text-white/80 group-hover:translate-x-1 transition-all shrink-0" />
      </button>

      {/* Quick Actions */}
      <div>
        <p className="text-xs font-semibold text-[#957186] uppercase tracking-widest mb-3">Quick Actions</p>
        <div className="grid grid-cols-3 gap-3">
          {quickActions.map(({ label, icon: Icon, to, desc, bg }) => (
            <button
              key={to}
              onClick={() => navigate(to)}
              className="flex flex-col items-center gap-2.5 bg-white border border-[#d9b8c4]/40 rounded-2xl p-5 hover:border-[#703d57]/40 hover:bg-[#f7f0f4] transition-all group"
            >
              <div className={`h-11 w-11 rounded-xl ${bg} flex items-center justify-center transition-colors`}>
                <Icon className="h-5 w-5 text-white" />
              </div>
              <span className="text-sm font-semibold text-[#241715]">{label}</span>
              <span className="text-xs text-[#957186] text-center hidden sm:block">{desc}</span>
            </button>
          ))}
        </div>
      </div>

      {/* AI Tools */}
      <div>
        <p className="text-xs font-semibold text-[#957186] uppercase tracking-widest mb-3">AI Tools</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <button
            onClick={() => navigate("/ai-assessment?tab=chat")}
            className="flex items-center gap-4 bg-white border border-[#d9b8c4]/40 rounded-2xl p-4 hover:border-[#703d57]/40 hover:bg-[#f7f0f4] transition-all group text-left"
          >
            <div className="h-11 w-11 rounded-xl bg-[#703d57] flex items-center justify-center shrink-0">
              <MessageCircle className="h-5 w-5 text-white" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-[#241715]">Chat with CLAiR AI</p>
              <p className="text-xs text-[#957186] mt-0.5">Get instant legal research and advice</p>
            </div>
            <ChevronRight className="h-4 w-4 text-[#d9b8c4] group-hover:text-[#703d57] transition-colors shrink-0" />
          </button>

          <button
            onClick={() => navigate("/ai-assessment?tab=assessment")}
            className="flex items-center gap-4 bg-white border border-[#d9b8c4]/40 rounded-2xl p-4 hover:border-[#703d57]/40 hover:bg-[#f7f0f4] transition-all group text-left"
          >
            <div className="h-11 w-11 rounded-xl bg-[#402a2c] flex items-center justify-center shrink-0">
              <ClipboardCheck className="h-5 w-5 text-white" />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-bold text-[#241715]">Assess AI Conversations</p>
              <p className="text-xs text-[#957186] mt-0.5">Review and give feedback on client–AI chats</p>
            </div>
            <ChevronRight className="h-4 w-4 text-[#d9b8c4] group-hover:text-[#703d57] transition-colors shrink-0" />
          </button>
        </div>
      </div>

      {/* Client Conversations */}
      <div className="pb-6">
        <div className="flex items-center justify-between mb-3">
          <p className="text-xs font-semibold text-[#957186] uppercase tracking-widest">Client Conversations</p>
          <button
            onClick={() => navigate("/conversations")}
            className="text-xs text-[#703d57] hover:underline font-semibold flex items-center gap-1"
          >
            See all <ChevronRight className="h-3.5 w-3.5" />
          </button>
        </div>
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white shadow-sm overflow-hidden">
          {CLIENT_CONVERSATIONS.map((conv, i) => (
            <button
              key={conv.id}
              onClick={() => navigate("/conversations")}
              className={`w-full flex items-start gap-3 px-5 py-4 hover:bg-[#f7f0f4] transition-colors text-left group ${
                i < CLIENT_CONVERSATIONS.length - 1 ? "border-b border-gray-50" : ""
              }`}
            >
              <div className="h-9 w-9 rounded-full bg-[#eedde8] flex items-center justify-center text-xs font-bold text-[#703d57] shrink-0 mt-0.5">
                {conv.clientName.split(" ").map((n) => n[0]).join("").slice(0, 2)}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2 mb-0.5">
                  <p className="text-sm font-semibold text-[#241715] truncate">{conv.clientName}</p>
                  <span className="text-[10px] text-[#957186] shrink-0">{conv.date}</span>
                </div>
                <p className="text-xs text-[#957186] truncate">{conv.preview}</p>
                <div className="flex items-center gap-1.5 mt-1">
                  <Bot className="h-3 w-3 text-[#703d57] shrink-0" />
                  <p className="text-[11px] text-gray-400 truncate">{conv.lastMessage}</p>
                </div>
              </div>
              <ChevronRight className="h-4 w-4 text-[#d9b8c4] group-hover:text-[#703d57] transition-colors shrink-0 mt-2" />
            </button>
          ))}
        </div>
      </div>

    </div>
  );
}
