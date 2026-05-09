import { useState, useRef, useEffect, useCallback } from "react";
import { useSearchParams } from "react-router-dom";
import {
  Sparkles, MessageSquare, ThumbsUp, Flag, Send, Plus,
  X, AlertTriangle, Check, Bot, User, Pin, RefreshCw,
} from "lucide-react";
import { cn } from "@/lib/cn";
import { api } from "@/lib/api";
import { getApiErrorMessage, getApiErrorMessageWithNetworkHint } from "@/lib/api-error";

// ─── Types ───────────────────────────────────────────────────────────────────

type Tab = "chat" | "assessment";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
}

interface MessageFeedback {
  messageId: string;
  type: "commend" | "report";
  issues?: string[];
  comment?: string;
}

interface ChatSendResponse {
  reply: string;
  conversation_id: string;
  conversation_title: string;
}

interface LawyerConversationSummary {
  id: string;
  title: string;
  is_pinned: boolean;
  created_at: string;
  updated_at: string | null;
}

interface LawyerConversationDetailMessage {
  id: string;
  role: string;
  text: string;
  created_at: string;
}

interface SharedBookingSummary {
  appointment_id: string;
  shared_at: string;
  appointment_date: string;
  appointment_time: string;
  appointment_type: string;
  status: string;
}

interface SharedBookingDetail extends SharedBookingSummary {
  description_preview: string | null;
}

interface ClientConversationSummary {
  id: string;
  title: string;
  updated_at: string | null;
  client_display_name: string;
  latest_shared_booking: SharedBookingSummary;
}

interface AssessmentApiMessage {
  id: string;
  role: string;
  text: string;
  created_at: string;
}

interface AssessmentFeedbackRow {
  message_id: string;
  feedback_type: string;
  issue_codes: string[] | null;
  comment: string | null;
}

interface ClientConversationDetail {
  id: string;
  title: string;
  updated_at: string | null;
  client_display_name: string;
  messages: AssessmentApiMessage[];
  my_feedback: AssessmentFeedbackRow[];
  shared_bookings: SharedBookingDetail[];
}

function formatBookingDateShort(isoDate: string): string {
  const [y, m, d] = isoDate.split("-").map(Number);
  if (!y || !m || !d) return isoDate;
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  return `${months[m - 1]} ${d}, ${y}`;
}

function formatBookingTimeShort(t: string): string {
  const parts = t.split(":");
  const h = Number(parts[0]);
  const min = Number(parts[1]);
  if (Number.isNaN(h) || Number.isNaN(min)) return t;
  const ampm = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 || 12;
  return `${h12}:${String(min).padStart(2, "0")} ${ampm}`;
}

function sharedBookingOneLiner(b: SharedBookingSummary): string {
  return `${formatBookingDateShort(b.appointment_date)} ${formatBookingTimeShort(b.appointment_time)} · ${b.status} · ${b.appointment_type}`;
}

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
  const [activeTab, setActiveTab] = useState<Tab>(
    initialTab === "assessment" ? "assessment" : "chat",
  );

  useEffect(() => {
    const t = searchParams.get("tab");
    if (t === "assessment" || t === "chat") setActiveTab(t);
  }, [searchParams]);

  return (
    <div className="max-w-5xl mx-auto space-y-5">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="h-9 w-9 rounded-xl bg-[#703d57] flex items-center justify-center">
          <Sparkles className="h-5 w-5 text-white" />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-[#241715]">AI Assessment</h1>
          <p className="text-sm text-[#957186]">Chat with AI or review CLAiR chats clients choose to share when booking with you</p>
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
  const [histories, setHistories] = useState<LawyerConversationSummary[]>([]);
  const [historiesLoading, setHistoriesLoading] = useState(true);
  const [historiesError, setHistoriesError] = useState("");
  const [loadingConversation, setLoadingConversation] = useState(false);

  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [started, setStarted] = useState(false);
  const [conversationId, setConversationId] = useState<string | null>(null);
  const [conversationTitle, setConversationTitle] = useState<string | null>(null);
  const [chatError, setChatError] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);

  const refreshHistories = useCallback(async () => {
    try {
      const { data } = await api.get<{ conversations: LawyerConversationSummary[] }>("/conversations");
      setHistories(data.conversations);
      setHistoriesError("");
    } catch (err) {
      setHistoriesError(getApiErrorMessageWithNetworkHint(err, "Could not refresh conversations."));
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setHistoriesLoading(true);
      try {
        const { data } = await api.get<{ conversations: LawyerConversationSummary[] }>("/conversations");
        if (!cancelled) {
          setHistories(data.conversations);
          setHistoriesError("");
        }
      } catch (err) {
        if (!cancelled) {
          setHistoriesError(getApiErrorMessageWithNetworkHint(err, "Could not load conversation history."));
        }
      } finally {
        if (!cancelled) setHistoriesLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const STARTERS = [
    "What are the grounds for annulment in the Philippines?",
    "Explain the small claims court process",
    "What are employee rights upon illegal dismissal?",
    "How does estate settlement work without a will?",
  ];

  async function loadConversation(id: string) {
    if (loadingConversation || loading) return;
    setChatError("");
    setLoadingConversation(true);
    try {
      const { data } = await api.get<{
        id: string;
        title: string;
        messages: LawyerConversationDetailMessage[];
      }>(`/conversations/${id}`);
      const sorted = [...data.messages].sort(
        (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime(),
      );
      const mapped: ChatMessage[] = sorted.map((m) => ({
        id: m.id,
        role: m.role === "model" ? "assistant" : "user",
        content: m.text,
        timestamp: new Date(m.created_at),
      }));
      setConversationId(data.id);
      setConversationTitle(data.title);
      setMessages(mapped);
      setStarted(true);
    } catch (err) {
      setChatError(getApiErrorMessage(err, "Could not open that conversation."));
    } finally {
      setLoadingConversation(false);
    }
  }

  async function sendMessage(text?: string) {
    const content = text ?? input.trim();
    if (!content || loading) return;
    setChatError("");
    setInput("");
    const prior = messages;
    const historyForApi = prior.map((m) => ({
      role: m.role === "assistant" ? ("model" as const) : ("user" as const),
      text: m.content,
    }));

    const userMsg: ChatMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content,
      timestamp: new Date(),
    };
    setMessages((prev) => [...prev, userMsg]);
    setStarted(true);
    setLoading(true);

    try {
      const payload: {
        message: string;
        history: { role: "user" | "model"; text: string }[];
        conversation_id?: string;
      } = {
        message: content,
        history: historyForApi,
      };
      if (conversationId) payload.conversation_id = conversationId;

      const { data } = await api.post<ChatSendResponse>("/chat/send", payload);
      setConversationId(data.conversation_id);
      if (data.conversation_title?.trim()) {
        setConversationTitle(data.conversation_title);
      }

      const reply: ChatMessage = {
        id: crypto.randomUUID(),
        role: "assistant",
        content: data.reply,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, reply]);
      void refreshHistories();
    } catch (err) {
      setMessages((prev) => (prev.length > 0 ? prev.slice(0, -1) : prev));
      setInput(content);
      if (prior.length === 0) {
        setStarted(false);
        setConversationTitle(null);
      }
      setChatError(getApiErrorMessage(err, "Could not get a response. Please try again."));
    } finally {
      setLoading(false);
    }
  }

  function handleKey(e: React.KeyboardEvent) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      void sendMessage();
    }
  }

  function newChat() {
    setMessages([]);
    setStarted(false);
    setInput("");
    setConversationId(null);
    setConversationTitle(null);
    setChatError("");
  }

  return (
    <div
      className="grid gap-4 lg:grid-cols-[260px_1fr] lg:items-stretch"
      style={{ minHeight: "calc(100vh - 260px)" }}
    >
      {/* Sidebar: saved lawyer AI threads */}
      <div className="flex flex-col rounded-2xl border border-[#d9b8c4]/40 bg-[#fdf9fb] p-3 max-h-[42vh] lg:max-h-none lg:min-h-[480px]">
        <div className="flex items-center justify-between gap-2 mb-2">
          <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide">Your chats</p>
          <button
            type="button"
            title="Refresh list"
            onClick={() => void refreshHistories()}
            className="p-1.5 rounded-lg text-[#957186] hover:bg-[#f7f0f4] transition"
          >
            <RefreshCw className="h-3.5 w-3.5" />
          </button>
        </div>
        <button
          type="button"
          onClick={newChat}
          className="flex items-center justify-center gap-1.5 w-full py-2.5 rounded-xl bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] transition mb-2"
        >
          <Plus className="h-3.5 w-3.5" />
          New conversation
        </button>
        {historiesError ? (
          <div className="rounded-lg border border-red-200 bg-red-50 px-2 py-1.5 text-[10px] text-red-700 mb-2">
            {historiesError}
          </div>
        ) : null}
        <div className="flex-1 overflow-y-auto space-y-1.5 pr-0.5 min-h-0">
          {historiesLoading ? (
            <p className="text-xs text-[#957186] px-1 py-2">Loading…</p>
          ) : histories.length === 0 ? (
            <p className="text-xs text-[#957186] px-1 py-2">No saved chats yet. Send a message to create one.</p>
          ) : (
            histories.map((h) => {
              const active = conversationId !== null && h.id === conversationId;
              return (
                <button
                  key={h.id}
                  type="button"
                  onClick={() => void loadConversation(h.id)}
                  disabled={loadingConversation}
                  className={cn(
                    "w-full text-left p-3 rounded-xl border text-xs transition-all disabled:opacity-50",
                    active
                      ? "border-[#703d57] bg-[#f7f0f4]"
                      : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]",
                  )}
                >
                  <div className="flex items-start justify-between gap-1 mb-1">
                    <span className="font-semibold text-[#241715] line-clamp-2 flex-1">{h.title}</span>
                    {h.is_pinned ? (
                      <Pin className="h-3 w-3 text-[#703d57] shrink-0 mt-0.5" aria-hidden />
                    ) : null}
                  </div>
                  <span className="text-[10px] text-[#957186]">
                    {formatAssessmentConvDate(h.updated_at)}
                  </span>
                </button>
              );
            })
          )}
        </div>
      </div>

      {/* Main chat column */}
      <div className="flex flex-col min-h-[480px]">
        <div className="flex items-center justify-between mb-3 gap-2">
          <div className="min-w-0">
            <p className="text-xs font-semibold text-[#241715] truncate">
              {conversationTitle ?? (started ? "Conversation" : "New conversation")}
            </p>
            <span className="text-[10px] text-[#957186]">
              {started
                ? `${messages.length} message${messages.length !== 1 ? "s" : ""}`
                : "Ask anything about Philippine law"}
            </span>
          </div>
          {started ? (
            <button
              type="button"
              onClick={newChat}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#d9b8c4] text-xs font-medium text-[#957186] hover:bg-[#f7f0f4] transition shrink-0"
            >
              <Plus className="h-3.5 w-3.5" />
              New chat
            </button>
          ) : null}
        </div>

        {chatError ? (
          <div className="mb-3 rounded-xl border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-700">
            {chatError}
          </div>
        ) : null}

        <div className="flex-1 overflow-y-auto rounded-2xl border border-[#d9b8c4]/40 bg-white min-h-0">
          {loadingConversation ? (
            <div className="h-full flex items-center justify-center py-16 text-sm text-[#957186]">
              Loading conversation…
            </div>
          ) : !started ? (
            <div className="h-full flex flex-col items-center justify-center px-6 py-12 text-center min-h-[320px]">
              <div className="h-14 w-14 rounded-2xl bg-[#703d57] flex items-center justify-center mb-4">
                <Sparkles className="h-7 w-7 text-white" />
              </div>
              <h2 className="text-lg font-bold text-[#241715] mb-1">CLAiR Legal Assistant</h2>
              <p className="text-sm text-[#957186] max-w-sm mb-8">
                Ask any legal question and get an AI-powered response based on Philippine law (same engine as the mobile app).
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 w-full max-w-lg">
                {STARTERS.map((s) => (
                  <button
                    key={s}
                    type="button"
                    onClick={() => void sendMessage(s)}
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
                  <div
                    className={cn(
                      "max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap",
                      msg.role === "user"
                        ? "bg-[#703d57] text-white rounded-tr-sm"
                        : "bg-[#f7f0f4] text-[#241715] rounded-tl-sm",
                    )}
                  >
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
                        <div
                          key={i}
                          className="h-2 w-2 rounded-full bg-[#957186] animate-bounce"
                          style={{ animationDelay: `${i * 0.15}s` }}
                        />
                      ))}
                    </div>
                  </div>
                </div>
              )}
              <div ref={bottomRef} />
            </div>
          )}
        </div>

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
              <span className="text-[10px] text-[#c490aa]">
                Philippine law context · synced with conversation history
              </span>
              <button
                type="button"
                onClick={() => void sendMessage()}
                disabled={!input.trim() || loading || loadingConversation}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] disabled:opacity-40 disabled:cursor-not-allowed transition"
              >
                <Send className="h-3.5 w-3.5" />
                Send
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

// ─── Tab 2 helpers ───────────────────────────────────────────────────────────

function formatAssessmentConvDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric",
    });
  } catch {
    return "—";
  }
}

function feedbackRecordFromRows(rows: AssessmentFeedbackRow[]): Record<string, MessageFeedback> {
  const m: Record<string, MessageFeedback> = {};
  for (const r of rows) {
    m[r.message_id] = {
      messageId: r.message_id,
      type: r.feedback_type === "commend" ? "commend" : "report",
      issues: r.issue_codes ?? undefined,
      comment: r.comment ?? undefined,
    };
  }
  return m;
}

function assessmentApiMessagesToView(rows: AssessmentApiMessage[]): ChatMessage[] {
  return rows.map((m) => ({
    id: m.id,
    role: m.role === "model" ? "assistant" : "user",
    content: m.text,
    timestamp: new Date(m.created_at),
  }));
}

// ─── Tab 2: Assessment Feedback ───────────────────────────────────────────────

function AssessmentTab() {
  const [summaries, setSummaries] = useState<ClientConversationSummary[]>([]);
  const [listLoading, setListLoading] = useState(true);
  const [listError, setListError] = useState("");
  const [selectedSummary, setSelectedSummary] = useState<ClientConversationSummary | null>(null);
  const [detail, setDetail] = useState<ClientConversationDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState("");
  const [feedbacks, setFeedbacks] = useState<Record<string, MessageFeedback>>({});
  const [reportTarget, setReportTarget] = useState<string | null>(null);
  const [selectedIssues, setSelectedIssues] = useState<string[]>([]);
  const [comment, setComment] = useState("");
  const [submitted, setSubmitted] = useState<string | null>(null);
  const [feedbackBusy, setFeedbackBusy] = useState(false);
  const [feedbackBanner, setFeedbackBanner] = useState("");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setListLoading(true);
      setListError("");
      try {
        const { data } = await api.get<{ conversations: ClientConversationSummary[] }>(
          "/lawyer/ai-assessment/client-conversations",
        );
        if (!cancelled) setSummaries(data.conversations);
      } catch (err) {
        if (!cancelled) {
          setListError(
            getApiErrorMessageWithNetworkHint(err, "Could not load client conversations."),
          );
        }
      } finally {
        if (!cancelled) setListLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!selectedSummary) {
      setDetail(null);
      setFeedbacks({});
      return;
    }
    let cancelled = false;
    (async () => {
      setDetailLoading(true);
      setDetailError("");
      try {
        const { data } = await api.get<ClientConversationDetail>(
          `/lawyer/ai-assessment/client-conversations/${selectedSummary.id}`,
        );
        if (!cancelled) {
          setDetail(data);
          setFeedbacks(feedbackRecordFromRows(data.my_feedback));
        }
      } catch (err) {
        if (!cancelled) {
          setDetail(null);
          setDetailError(
            getApiErrorMessage(err, "Could not load this conversation."),
          );
        }
      } finally {
        if (!cancelled) setDetailLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [selectedSummary?.id]);

  const viewMessages = detail ? assessmentApiMessagesToView(detail.messages) : [];

  function openReport(messageId: string) {
    setFeedbackBanner("");
    setReportTarget(messageId);
    setSelectedIssues([]);
    setComment("");
  }

  function toggleIssue(id: string) {
    setSelectedIssues((prev) =>
      prev.includes(id) ? prev.filter((i) => i !== id) : [...prev, id],
    );
  }

  async function submitReport() {
    if (!reportTarget || selectedIssues.length === 0 || feedbackBusy) return;
    setFeedbackBusy(true);
    setFeedbackBanner("");
    try {
      await api.post("/lawyer/ai-assessment/message-feedback", {
        message_id: reportTarget,
        feedback_type: "report",
        issue_codes: selectedIssues,
        comment: comment.trim() || undefined,
      });
      setFeedbacks((prev) => ({
        ...prev,
        [reportTarget]: {
          messageId: reportTarget,
          type: "report",
          issues: selectedIssues,
          comment: comment.trim() || undefined,
        },
      }));
      setSubmitted(reportTarget);
      setReportTarget(null);
      setTimeout(() => setSubmitted(null), 3000);
    } catch (err) {
      setFeedbackBanner(getApiErrorMessage(err, "Could not submit report."));
    } finally {
      setFeedbackBusy(false);
    }
  }

  async function submitCommend(messageId: string) {
    if (feedbackBusy) return;
    setFeedbackBusy(true);
    setFeedbackBanner("");
    try {
      await api.post("/lawyer/ai-assessment/message-feedback", {
        message_id: messageId,
        feedback_type: "commend",
        issue_codes: [],
      });
      setFeedbacks((prev) => ({
        ...prev,
        [messageId]: { messageId, type: "commend" },
      }));
      setSubmitted(messageId);
      setTimeout(() => setSubmitted(null), 3000);
    } catch (err) {
      setFeedbackBanner(getApiErrorMessage(err, "Could not submit commend."));
    } finally {
      setFeedbackBusy(false);
    }
  }

  return (
    <div className="grid gap-5 lg:grid-cols-[280px_1fr]" style={{ minHeight: 560 }}>
      {/* Conversation list */}
      <div className="space-y-2">
        <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide px-1 mb-3">
          Client Conversations
        </p>
        <p className="text-[11px] text-[#957186] px-1 mb-2 leading-relaxed">
          Only conversations a client attaches while requesting an appointment with you. Newest share first.
        </p>
        {listLoading ? (
          <p className="text-xs text-[#957186] px-1 py-4">Loading…</p>
        ) : listError ? (
          <div className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700">
            {listError}
          </div>
        ) : summaries.length === 0 ? (
          <p className="text-xs text-[#957186] px-1 py-4">
            Nothing shared yet. When a client checks “Attach CLAiR conversation” on their booking request, that chat appears here.
          </p>
        ) : (
          summaries.map((conv) => (
            <button
              key={conv.id}
              type="button"
              onClick={() => setSelectedSummary(conv)}
              className={cn(
                "w-full text-left p-4 rounded-2xl border transition-all",
                selectedSummary?.id === conv.id
                  ? "border-[#703d57] bg-[#f7f0f4]"
                  : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]",
              )}
            >
              <div className="flex items-center justify-between mb-1">
                <p className="text-sm font-semibold text-[#241715]">{conv.client_display_name}</p>
                <span className="text-[10px] text-[#957186]">{formatAssessmentConvDate(conv.updated_at)}</span>
              </div>
              <p className="text-xs text-[#957186] leading-relaxed line-clamp-2">{conv.title}</p>
              <p className="text-[10px] text-[#957186]/90 mt-1.5 leading-snug">
                Booking · {sharedBookingOneLiner(conv.latest_shared_booking)}
              </p>
            </button>
          ))
        )}
      </div>

      {/* Conversation viewer */}
      <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white overflow-hidden flex flex-col">
        {feedbackBanner ? (
          <div className="px-4 py-2 text-xs text-red-700 bg-red-50 border-b border-red-100">{feedbackBanner}</div>
        ) : null}
        {!selectedSummary ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center px-8 py-16">
            <div className="h-14 w-14 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
              <MessageSquare className="h-6 w-6 text-[#957186]" />
            </div>
            <p className="text-sm font-semibold text-[#241715]">Select a conversation</p>
            <p className="text-xs text-[#957186] mt-1 max-w-xs">
              Pick a conversation the client attached when booking with you.
            </p>
          </div>
        ) : detailLoading ? (
          <div className="flex-1 flex items-center justify-center py-16 text-sm text-[#957186]">Loading conversation…</div>
        ) : detailError ? (
          <div className="flex-1 flex flex-col items-center justify-center px-8 py-16">
            <p className="text-sm text-red-600">{detailError}</p>
          </div>
        ) : detail ? (
          <>
            <div className="px-5 py-4 border-b border-[#d9b8c4]/30 bg-[#f7f0f4]">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-bold text-[#241715]">{detail.client_display_name}</p>
                  <p className="text-xs text-[#957186]">
                    {formatAssessmentConvDate(detail.updated_at)} · {viewMessages.length} messages
                  </p>
                </div>
                <span className="text-xs bg-amber-100 text-amber-700 border border-amber-200 px-2.5 py-1 rounded-full font-semibold">
                  Review mode
                </span>
              </div>
              {detail.shared_bookings.length > 0 ? (
                <div className="mt-3 rounded-xl border border-[#d9b8c4]/50 bg-white/80 px-3 py-2.5">
                  <p className="text-[10px] font-semibold text-[#5a3046] uppercase tracking-wide mb-1.5">
                    Shared via appointment request
                  </p>
                  <ul className="space-y-1.5">
                    {detail.shared_bookings.map((b) => (
                      <li key={b.appointment_id} className="text-[11px] text-[#241715] leading-relaxed">
                        <span className="font-medium text-[#703d57]">{sharedBookingOneLiner(b)}</span>
                        {b.description_preview ? (
                          <span className="block text-[#957186] mt-0.5 line-clamp-2">{b.description_preview}</span>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                </div>
              ) : null}
            </div>

            <div className="flex-1 overflow-y-auto p-5 space-y-4">
              {viewMessages.map((msg) => {
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
                      <div
                        className={cn(
                          "max-w-[78%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap",
                          isAI
                            ? "bg-[#f7f0f4] text-[#241715] rounded-tl-sm"
                            : "bg-[#703d57] text-white rounded-tr-sm",
                        )}
                      >
                        {msg.content}
                      </div>
                      {!isAI && (
                        <div className="h-7 w-7 rounded-full bg-[#957186] flex items-center justify-center shrink-0 mt-0.5">
                          <User className="h-3.5 w-3.5 text-white" />
                        </div>
                      )}
                    </div>

                    {isAI && (
                      <div className="ml-10 mt-2 flex items-center gap-2 flex-wrap">
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
                              type="button"
                              disabled={feedbackBusy}
                              onClick={() => void submitCommend(msg.id)}
                              className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-emerald-200 bg-emerald-50 text-xs font-medium text-emerald-700 hover:bg-emerald-100 transition disabled:opacity-50"
                            >
                              <ThumbsUp className="h-3 w-3" />
                              Commend
                            </button>
                            <button
                              type="button"
                              disabled={feedbackBusy}
                              onClick={() => openReport(msg.id)}
                              className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-red-200 bg-red-50 text-xs font-medium text-red-600 hover:bg-red-100 transition disabled:opacity-50"
                            >
                              <Flag className="h-3 w-3" />
                              Report
                            </button>
                          </>
                        )}
                        {submitted === msg.id && (
                          <span className="text-xs text-[#957186] animate-pulse">Saved ✓</span>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {Object.keys(feedbacks).length > 0 && (
              <div className="px-5 py-3 border-t border-[#d9b8c4]/30 bg-[#f7f0f4] flex items-center gap-4 flex-wrap">
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
        ) : null}
      </div>

      {reportTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div className="w-full max-w-lg rounded-2xl bg-white shadow-2xl">
            <div className="flex items-start justify-between p-6 border-b border-[#d9b8c4]/30">
              <div className="flex items-center gap-3">
                <div className="h-9 w-9 rounded-xl bg-red-100 flex items-center justify-center">
                  <AlertTriangle className="h-5 w-5 text-red-600" />
                </div>
                <div>
                  <h2 className="font-bold text-[#241715]">Report AI Response</h2>
                  <p className="text-xs text-[#957186] mt-0.5">Logged for your QA records</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setReportTarget(null)}
                className="p-1 rounded-lg text-gray-400 hover:text-gray-600 transition"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <p className="text-xs font-semibold text-[#5a3046] uppercase tracking-wide mb-3">
                  What&apos;s wrong with this response? <span className="text-red-500">*</span>
                </p>
                <div className="space-y-2">
                  {REPORT_ISSUES.map((issue) => {
                    const checked = selectedIssues.includes(issue.id);
                    return (
                      <button
                        key={issue.id}
                        type="button"
                        onClick={() => toggleIssue(issue.id)}
                        className={cn(
                          "w-full flex items-start gap-3 p-3 rounded-xl border text-left transition-all",
                          checked
                            ? "border-red-300 bg-red-50"
                            : "border-[#d9b8c4]/40 hover:border-[#703d57]/30 hover:bg-[#f7f0f4]",
                        )}
                      >
                        <div
                          className={cn(
                            "h-4 w-4 rounded border-2 flex items-center justify-center shrink-0 mt-0.5 transition-colors",
                            checked ? "bg-red-500 border-red-500" : "border-[#d9b8c4]",
                          )}
                        >
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

            <div className="flex gap-3 px-6 pb-6">
              <button
                type="button"
                onClick={() => setReportTarget(null)}
                className="flex-1 py-2.5 rounded-xl border border-[#d9b8c4] text-sm font-semibold text-[#957186] hover:bg-[#f7f0f4] transition"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => void submitReport()}
                disabled={selectedIssues.length === 0 || feedbackBusy}
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
