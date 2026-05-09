import { useState, useRef, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import {
  Sparkles, MessageSquare, ThumbsUp, Flag, Send, Plus,
  X, ChevronDown, AlertTriangle, Check, Bot, User,
} from "lucide-react";
import { cn } from "@/lib/cn";

// ─── Types ───────────────────────────────────────────────────────────────────

type Tab = "chat" | "assessment";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}

interface ConversationThread {
  id: string;
  clientName: string;
  date: string;
  preview: string;
  messages: ChatMessage[];
}

interface MessageFeedback {
  messageId: string;
  type: "commend" | "report";
  issues?: string[];
  comment?: string;
}

// ─── Sample conversations for the assessment tab ──────────────────────────────

const SAMPLE_CONVERSATIONS: ConversationThread[] = [
  {
    id: "conv-1",
    clientName: "Maria Santos",
    date: "May 1, 2026",
    preview: "Asked about annulment process in the Philippines",
    messages: [
      { id: "m1", role: "user", content: "Good afternoon. I want to know how to get an annulment here in the Philippines. My husband and I have been separated for 5 years now.", timestamp: new Date() },
      { id: "m2", role: "assistant", content: "Good afternoon! I understand this is a difficult situation. In the Philippines, annulment is a legal process that nullifies a marriage. Unlike divorce, which is not available in the Philippines (except for Muslim Filipinos), annulment declares a marriage void or voidable.\n\nThe common legal grounds for annulment under the Family Code include:\n\n1. Lack of parental consent (if either party was 18–21 at the time of marriage)\n2. Psychological incapacity (Article 36) — the most commonly used ground\n3. Fraud\n4. Force, intimidation, or undue influence\n5. Physical incapacity to consummate the marriage\n6. Sexually transmissible disease found to be serious and incurable\n\nThe process typically takes 2–5 years and can be costly. I strongly recommend consulting with a licensed family law attorney who can assess your specific situation and guide you through the proper legal steps.", timestamp: new Date() },
      { id: "m3", role: "user", content: "How much does it usually cost?", timestamp: new Date() },
      { id: "m4", role: "assistant", content: "The cost of annulment in the Philippines can vary significantly depending on several factors:\n\n• **Attorney's fees**: ₱150,000 – ₱500,000+ depending on the lawyer's experience and the complexity of the case\n• **Court filing fees**: ₱5,000 – ₱15,000 approximately\n• **Psychological evaluation**: ₱15,000 – ₱40,000 (required for Article 36 cases)\n• **Publication fees**: ₱10,000 – ₱20,000 (required by law)\n• **Miscellaneous expenses**: ₱10,000 – ₱30,000\n\nTotal estimated range: ₱200,000 – ₱600,000 or more.\n\nPlease note these are rough estimates. Costs can be lower with public attorneys (PAO) if you qualify based on income. I recommend getting a formal consultation with a lawyer for a more accurate assessment of your case.", timestamp: new Date() },
    ],
  },
  {
    id: "conv-2",
    clientName: "Juan dela Cruz",
    date: "Apr 29, 2026",
    preview: "Asked about small claims court procedure",
    messages: [
      { id: "m5", role: "user", content: "How do I file a small claims case? My neighbor owes me ₱80,000 and refuses to pay.", timestamp: new Date() },
      { id: "m6", role: "assistant", content: "You can file a small claims case at the Metropolitan Trial Court (MeTC) or Municipal Trial Court (MTC) that has jurisdiction over where you or the defendant resides.\n\nHere's a quick overview of the process:\n\n1. **Fill out the Statement of Claim form** (available at the court or downloadable online)\n2. **Attach supporting documents**: receipts, contracts, written agreements, acknowledgment receipts, text messages, etc.\n3. **Pay the filing fee**: usually ₱1,000 – ₱2,000 for claims up to ₱100,000\n4. **Serve summons**: the court will notify your defendant\n5. **Appear on the hearing date**: small claims hearings are decided on the same day — no lawyers are allowed\n\nImportantly, small claims court in the Philippines now covers money claims up to ₱400,000 under the 2022 Revised Rules on Small Claims Cases.\n\nSince your claim is ₱80,000, you are well within the threshold. The process is designed to be quick — typically resolved in one hearing.", timestamp: new Date() },
      { id: "m7", role: "user", content: "Do I need a lawyer?", timestamp: new Date() },
      { id: "m8", role: "assistant", content: "No — in fact, lawyers are not allowed to appear in small claims proceedings in the Philippines. This is by design to make the process faster and more accessible.\n\nYou will represent yourself (pro se). The court will guide you through the hearing. Just bring all your evidence and be prepared to explain your claim clearly.\n\nHowever, you may consult a lawyer beforehand to help you prepare your Statement of Claim and organize your evidence, even if they cannot appear with you in court.", timestamp: new Date() },
    ],
  },
  {
    id: "conv-3",
    clientName: "Rosa Reyes",
    date: "Apr 27, 2026",
    preview: "Asked about labor rights after termination",
    messages: [
      { id: "m9", role: "user", content: "I was terminated from my job without any notice. Is this legal?", timestamp: new Date() },
      { id: "m10", role: "assistant", content: "Under Philippine labor law, termination without notice may be illegal depending on the circumstances. The Labor Code of the Philippines requires employers to follow due process before terminating an employee.\n\nFor just causes (serious misconduct, willful disobedience, gross neglect, etc.), the employer must:\n1. Issue a written Notice to Explain (NTE)\n2. Give the employee at least 5 calendar days to respond\n3. Conduct a hearing if requested\n4. Issue a Notice of Termination\n\nFor authorized causes (redundancy, retrenchment, closure), the employer must:\n1. Give a 30-day advance written notice to both the employee AND the DOLE\n2. Pay separation pay\n\nIf none of these were followed, your termination may be considered **illegal dismissal**. You may file a complaint with the National Labor Relations Commission (NLRC) within 4 years from the date of dismissal.\n\nI recommend documenting everything and consulting with a labor lawyer as soon as possible.", timestamp: new Date() },
    ],
  },
];

// ─── Report issue options ─────────────────────────────────────────────────────

const REPORT_ISSUES = [
  { id: "incorrect", label: "Incorrect information", desc: "The AI stated facts that are legally inaccurate" },
  { id: "misleading", label: "Misleading advice", desc: "The response could lead the client to wrong conclusions" },
  { id: "outdated", label: "Outdated law cited", desc: "References repealed or amended legislation" },
  { id: "incomplete", label: "Incomplete answer", desc: "Important aspects of the legal question were omitted" },
  { id: "jurisdiction", label: "Wrong jurisdiction", desc: "Advice does not apply to Philippine law or the relevant region" },
  { id: "overconfident", label: "Overly confident tone", desc: "Presented uncertain information as definitive legal fact" },
  { id: "harmful", label: "Potentially harmful", desc: "Could cause legal or financial harm if followed" },
  { id: "other", label: "Other concern", desc: "Something else not listed above" },
];

// ─── Main component ───────────────────────────────────────────────────────────

export function AiAssessmentPage() {
  const [searchParams] = useSearchParams();
  const initialTab = (searchParams.get("tab") as Tab) ?? "chat";
  const [activeTab, setActiveTab] = useState<Tab>(initialTab);

  return (
    <div className="max-w-5xl mx-auto space-y-5">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="h-9 w-9 rounded-xl bg-[#703d57] flex items-center justify-center">
          <Sparkles className="h-5 w-5 text-white" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">AI Assessment</h1>
          <p className="text-sm text-[#957186]">Chat with AI or review and assess client–AI conversations</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-0 border-b border-[#d9b8c4]/60">
        <button
          onClick={() => setActiveTab("chat")}
          className={cn(
            "flex items-center gap-2 px-5 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors",
            activeTab === "chat"
              ? "border-[#703d57] text-[#703d57]"
              : "border-transparent text-[#957186] hover:text-[#703d57]"
          )}
        >
          <MessageSquare className="h-4 w-4" />
          AI Chat
        </button>
        <button
          onClick={() => setActiveTab("assessment")}
          className={cn(
            "flex items-center gap-2 px-5 py-2.5 text-sm font-medium border-b-2 -mb-px transition-colors",
            activeTab === "assessment"
              ? "border-[#703d57] text-[#703d57]"
              : "border-transparent text-[#957186] hover:text-[#703d57]"
          )}
        >
          <Flag className="h-4 w-4" />
          Assessment Feedback
        </button>
      </div>

      {activeTab === "chat" ? <ChatTab /> : <AssessmentTab />}
    </div>
  );
}

// ─── Tab 1: AI Chat ───────────────────────────────────────────────────────────

function ChatTab() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [started, setStarted] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const STARTERS = [
    "What are the grounds for annulment in the Philippines?",
    "Explain the small claims court process",
    "What are employee rights upon illegal dismissal?",
    "How does estate settlement work without a will?",
  ];

  async function sendMessage(text?: string) {
    const content = text ?? input.trim();
    if (!content || loading) return;
    setInput("");
    setStarted(true);

    const userMsg: ChatMessage = {
      id: Date.now().toString(),
      role: "user",
      content,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setLoading(true);

    // Simulated AI response — replace with real API call when backend is ready
    setTimeout(() => {
      const reply: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: "assistant",
        content: `Thank you for your question regarding "${content.slice(0, 60)}${content.length > 60 ? "…" : ""}". This is a simulated AI response. Once the backend is connected, this will return a real legal AI answer tailored to Philippine law and your specific query.`,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, reply]);
      setLoading(false);
    }, 1500);
  }

  function handleKey(e: React.KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  }

  function newChat() {
    setMessages([]);
    setStarted(false);
    setInput("");
  }

  return (
    <div className="flex flex-col" style={{ height: "calc(100vh - 260px)", minHeight: 480 }}>
      {/* Top bar */}
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs text-[#957186]">
          {started ? `${messages.length} message${messages.length !== 1 ? "s" : ""}` : "New conversation"}
        </span>
        {started && (
          <button
            onClick={newChat}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#d9b8c4] text-xs font-medium text-[#957186] hover:bg-[#f7f0f4] transition"
          >
            <Plus className="h-3.5 w-3.5" />
            New chat
          </button>
        )}
      </div>

      {/* Messages area */}
      <div className="flex-1 overflow-y-auto rounded-2xl border border-[#d9b8c4]/40 bg-white">
        {!started ? (
          /* Empty state / conversation starters */
          <div className="h-full flex flex-col items-center justify-center px-6 py-12 text-center">
            <div className="h-14 w-14 rounded-2xl bg-[#703d57] flex items-center justify-center mb-4">
              <Sparkles className="h-7 w-7 text-white" />
            </div>
            <h2 className="text-lg font-bold text-[#241715] mb-1">CLAiR Legal Assistant</h2>
            <p className="text-sm text-[#957186] max-w-sm mb-8">
              Ask any legal question and get an AI-powered response based on Philippine law.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 w-full max-w-lg">
              {STARTERS.map((s) => (
                <button
                  key={s}
                  onClick={() => sendMessage(s)}
                  className="text-left px-4 py-3 rounded-xl border border-[#d9b8c4]/60 bg-[#f7f0f4] text-sm text-[#241715] hover:border-[#703d57] hover:bg-[#eedde8] transition-all"
                >
                  {s}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="p-5 space-y-5">
            {messages.map((msg) => (
              <div key={msg.id} className={cn("flex gap-3", msg.role === "user" ? "justify-end" : "justify-start")}>
                {msg.role === "assistant" && (
                  <div className="h-8 w-8 rounded-full bg-[#703d57] flex items-center justify-center shrink-0 mt-0.5">
                    <Bot className="h-4 w-4 text-white" />
                  </div>
                )}
                <div className={cn(
                  "max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap",
                  msg.role === "user"
                    ? "bg-[#703d57] text-white rounded-tr-sm"
                    : "bg-[#f7f0f4] text-[#241715] rounded-tl-sm"
                )}>
                  {msg.content}
                </div>
                {msg.role === "user" && (
                  <div className="h-8 w-8 rounded-full bg-[#957186] flex items-center justify-center shrink-0 mt-0.5">
                    <User className="h-4 w-4 text-white" />
                  </div>
                )}
              </div>
            ))}
            {loading && (
              <div className="flex gap-3">
                <div className="h-8 w-8 rounded-full bg-[#703d57] flex items-center justify-center shrink-0">
                  <Bot className="h-4 w-4 text-white" />
                </div>
                <div className="bg-[#f7f0f4] rounded-2xl rounded-tl-sm px-4 py-3">
                  <div className="flex gap-1 items-center h-5">
                    {[0, 1, 2].map((i) => (
                      <div key={i} className="h-2 w-2 rounded-full bg-[#957186] animate-bounce"
                        style={{ animationDelay: `${i * 0.15}s` }} />
                    ))}
                  </div>
                </div>
              </div>
            )}
            <div ref={bottomRef} />
          </div>
        )}
      </div>

      {/* Input box */}
      <div className="mt-3 flex gap-2 items-end">
        <div className="flex-1 rounded-2xl border border-[#d9b8c4] bg-white focus-within:border-[#703d57] focus-within:ring-2 focus-within:ring-[#703d57]/10 transition">
          <textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKey}
            placeholder="Ask a legal question… (Enter to send, Shift+Enter for new line)"
            rows={2}
            className="w-full px-4 pt-3 pb-1 text-sm text-[#241715] placeholder-[#c490aa] bg-transparent outline-none resize-none"
          />
          <div className="flex items-center justify-between px-3 pb-2">
            <span className="text-[10px] text-[#c490aa]">Philippine law context</span>
            <button
              onClick={() => sendMessage()}
              disabled={!input.trim() || loading}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] disabled:opacity-40 disabled:cursor-not-allowed transition"
            >
              <Send className="h-3.5 w-3.5" />
              Send
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Tab 2: Assessment Feedback ───────────────────────────────────────────────

function AssessmentTab() {
  const [selected, setSelected] = useState<ConversationThread | null>(null);
  const [feedbacks, setFeedbacks] = useState<Record<string, MessageFeedback>>({});
  const [reportTarget, setReportTarget] = useState<string | null>(null);
  const [selectedIssues, setSelectedIssues] = useState<string[]>([]);
  const [comment, setComment] = useState("");
  const [submitted, setSubmitted] = useState<string | null>(null);

  function openReport(messageId: string) {
    setReportTarget(messageId);
    setSelectedIssues([]);
    setComment("");
  }

  function toggleIssue(id: string) {
    setSelectedIssues((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id]
    );
  }

  function submitReport() {
    if (!reportTarget || selectedIssues.length === 0) return;
    setFeedbacks((prev) => ({
      ...prev,
      [reportTarget]: { messageId: reportTarget, type: "report", issues: selectedIssues, comment },
    }));
    setSubmitted(reportTarget);
    setReportTarget(null);
    setTimeout(() => setSubmitted(null), 3000);
  }

  function submitCommend(messageId: string) {
    setFeedbacks((prev) => ({
      ...prev,
      [messageId]: { messageId, type: "commend" },
    }));
  }

  return (
    <div className="grid gap-5 lg:grid-cols-[280px_1fr]" style={{ minHeight: 560 }}>
      {/* Conversation list */}
      <div className="space-y-2">
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide px-1 mb-3">
          Client Conversations
        </p>
        {SAMPLE_CONVERSATIONS.map((conv) => (
          <button
            key={conv.id}
            onClick={() => { setSelected(conv); setFeedbacks({}); }}
            className={cn(
              "w-full text-left p-4 rounded-2xl border transition-all",
              selected?.id === conv.id
                ? "border-[#703d57] bg-[#f7f0f4]"
                : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]"
            )}
          >
            <div className="flex items-center justify-between mb-1">
              <p className="text-sm font-semibold text-[#241715]">{conv.clientName}</p>
              <span className="text-[10px] text-[#957186]">{conv.date}</span>
            </div>
            <p className="text-xs text-[#957186] leading-relaxed line-clamp-2">{conv.preview}</p>
            <div className="mt-2 flex items-center gap-1">
              <MessageSquare className="h-3 w-3 text-[#c490aa]" />
              <span className="text-[10px] text-[#c490aa]">{conv.messages.length} messages</span>
            </div>
          </button>
        ))}
      </div>

      {/* Conversation viewer */}
      <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white overflow-hidden flex flex-col">
        {!selected ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center px-8 py-16">
            <div className="h-14 w-14 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
              <MessageSquare className="h-6 w-6 text-[#957186]" />
            </div>
            <p className="text-sm font-semibold text-[#241715]">Select a conversation</p>
            <p className="text-xs text-[#957186] mt-1 max-w-xs">
              Choose a client–AI conversation from the left to begin your assessment.
            </p>
          </div>
        ) : (
          <>
            {/* Conversation header */}
            <div className="px-5 py-4 border-b border-[#d9b8c4]/30 bg-[#f7f0f4]">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-bold text-[#241715]">{selected.clientName}</p>
                  <p className="text-xs text-[#957186]">{selected.date} · {selected.messages.length} messages</p>
                </div>
                <span className="text-xs bg-amber-100 text-amber-700 border border-amber-200 px-2.5 py-1 rounded-full font-semibold">
                  Review mode
                </span>
              </div>
            </div>

            {/* Messages — view only */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {selected.messages.map((msg) => {
                const fb = feedbacks[msg.id];
                const isAI = msg.role === "assistant";

                return (
                  <div key={msg.id}>
                    <div className={cn("flex gap-3", !isAI && "justify-end")}>
                      {isAI && (
                        <div className="h-7 w-7 rounded-full bg-[#703d57] flex items-center justify-center shrink-0 mt-0.5">
                          <Bot className="h-3.5 w-3.5 text-white" />
                        </div>
                      )}
                      <div className={cn(
                        "max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap",
                        isAI
                          ? "bg-[#f7f0f4] text-[#241715] rounded-tl-sm"
                          : "bg-[#703d57] text-white rounded-tr-sm"
                      )}>
                        {msg.content}
                      </div>
                      {!isAI && (
                        <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center shrink-0 mt-0.5">
                          <User className="h-3.5 w-3.5 text-white" />
                        </div>
                      )}
                    </div>

                    {/* Assessment buttons — only on AI messages */}
                    {isAI && (
                      <div className="ml-10 mt-2 flex items-center gap-2">
                        {fb?.type === "commend" ? (
                          <span className="flex items-center gap-1 text-xs text-emerald-600 font-medium">
                            <Check className="h-3.5 w-3.5" /> Commended
                          </span>
                        ) : fb?.type === "report" ? (
                          <span className="flex items-center gap-1 text-xs text-red-500 font-medium">
                            <Flag className="h-3.5 w-3.5" /> Reported
                          </span>
                        ) : (
                          <>
                            <button
                              onClick={() => submitCommend(msg.id)}
                              className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-emerald-200 bg-emerald-50 text-xs font-medium text-emerald-700 hover:bg-emerald-100 transition"
                            >
                              <ThumbsUp className="h-3 w-3" />
                              Commend
                            </button>
                            <button
                              onClick={() => openReport(msg.id)}
                              className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-red-200 bg-red-50 text-xs font-medium text-red-600 hover:bg-red-100 transition"
                            >
                              <Flag className="h-3 w-3" />
                              Report
                            </button>
                          </>
                        )}
                        {submitted === msg.id && (
                          <span className="text-xs text-[#957186] animate-pulse">Feedback sent to developers ✓</span>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Assessment summary bar */}
            {Object.keys(feedbacks).length > 0 && (
              <div className="px-5 py-3 border-t border-[#d9b8c4]/30 bg-[#f7f0f4] flex items-center gap-4">
                <span className="text-xs text-[#957186]">Your assessment:</span>
                <span className="flex items-center gap-1 text-xs text-emerald-700 font-medium">
                  <ThumbsUp className="h-3.5 w-3.5" />
                  {Object.values(feedbacks).filter((f) => f.type === "commend").length} commended
                </span>
                <span className="flex items-center gap-1 text-xs text-red-600 font-medium">
                  <Flag className="h-3.5 w-3.5" />
                  {Object.values(feedbacks).filter((f) => f.type === "report").length} reported
                </span>
              </div>
            )}
          </>
        )}
      </div>

      {/* ── Report Modal ── */}
      {reportTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white shadow-2xl">
            {/* Modal header */}
            <div className="flex items-start justify-between p-6 border-b border-[#d9b8c4]/30">
              <div className="flex items-center gap-3">
                <div className="h-9 w-9 rounded-xl bg-red-100 flex items-center justify-center">
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                </div>
                <div>
                  <h2 className="font-bold text-[#241715]">Report AI Response</h2>
                  <p className="text-xs text-[#957186] mt-0.5">This feedback will be sent to the development team</p>
                </div>
              </div>
              <button onClick={() => setReportTarget(null)} className="p-1 rounded-lg text-gray-400 hover:text-gray-600 transition">
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Issue selection */}
            <div className="p-6 space-y-4">
              <div>
                <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-3">
                  What's wrong with this response? <span className="text-red-500">*</span>
                </p>
                <div className="space-y-2">
                  {REPORT_ISSUES.map((issue) => {
                    const checked = selectedIssues.includes(issue.id);
                    return (
                      <button
                        key={issue.id}
                        onClick={() => toggleIssue(issue.id)}
                        className={cn(
                          "w-full flex items-start gap-3 p-3 rounded-xl border text-left transition-all",
                          checked
                            ? "border-red-300 bg-red-50"
                            : "border-[#d9b8c4]/40 hover:border-[#703d57]/30 hover:bg-[#f7f0f4]"
                        )}
                      >
                        <div className={cn(
                          "h-4 w-4 rounded border-2 flex items-center justify-center shrink-0 mt-0.5 transition-colors",
                          checked ? "bg-red-500 border-red-500" : "border-[#d9b8c4]"
                        )}>
                          {checked && <Check className="h-2.5 w-2.5 text-white" />}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-[#241715]">{issue.label}</p>
                          <p className="text-xs text-[#957186] mt-0.5">{issue.desc}</p>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Comment */}
              <div>
                <label className="block text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">
                  Additional comments <span className="normal-case font-normal text-[#c490aa]">(optional)</span>
                </label>
                <textarea
                  rows={3}
                  value={comment}
                  onChange={(e) => setComment(e.target.value)}
                  placeholder="Describe the specific error or provide the correct information…"
                  className="w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] focus:bg-white transition resize-none"
                />
              </div>
            </div>

            {/* Modal footer */}
            <div className="flex gap-3 px-6 pb-6">
              <button
                onClick={() => setReportTarget(null)}
                className="flex-1 py-2.5 rounded-xl border border-[#d9b8c4] text-sm font-semibold text-[#957186] hover:bg-[#f7f0f4] transition"
              >
                Cancel
              </button>
              <button
                onClick={submitReport}
                disabled={selectedIssues.length === 0}
                className="flex-1 py-2.5 rounded-xl bg-red-600 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition flex items-center justify-center gap-2"
              >
                <Flag className="h-4 w-4" />
                Send report
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}