import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bot, User, ExternalLink, Search, ChevronLeft } from "lucide-react";
import { cn } from "@/lib/cn";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
}

interface Conversation {
  id: string;
  clientName: string;
  date: string;
  preview: string;
  messages: ChatMessage[];
}

const CONVERSATIONS: Conversation[] = [
  {
    id: "conv-1",
    clientName: "Maria Santos",
    date: "May 1, 2026",
    preview: "Asked about annulment process in the Philippines",
    messages: [
      { id: "m1", role: "user", content: "Good afternoon. I want to know how to get an annulment here in the Philippines. My husband and I have been separated for 5 years now." },
      { id: "m2", role: "assistant", content: "Good afternoon! I understand this is a difficult situation. In the Philippines, annulment is a legal process that nullifies a marriage. Unlike divorce, which is not available in the Philippines (except for Muslim Filipinos), annulment declares a marriage void or voidable.\n\nThe common legal grounds for annulment under the Family Code include:\n\n1. Lack of parental consent (if either party was 18–21 at the time of marriage)\n2. Psychological incapacity (Article 36) — the most commonly used ground\n3. Fraud\n4. Force, intimidation, or undue influence\n5. Physical incapacity to consummate the marriage\n6. Sexually transmissible disease found to be serious and incurable\n\nThe process typically takes 2–5 years and can be costly. I strongly recommend consulting with a licensed family law attorney who can assess your specific situation." },
      { id: "m3", role: "user", content: "How much does it usually cost?" },
      { id: "m4", role: "assistant", content: "The cost of annulment in the Philippines can vary significantly:\n\n• Attorney's fees: ₱150,000 – ₱500,000+\n• Court filing fees: ₱5,000 – ₱15,000\n• Psychological evaluation: ₱15,000 – ₱40,000\n• Publication fees: ₱10,000 – ₱20,000\n• Miscellaneous: ₱10,000 – ₱30,000\n\nTotal estimated range: ₱200,000 – ₱600,000 or more.\n\nCosts can be lower with public attorneys (PAO) if you qualify based on income." },
    ],
  },
  {
    id: "conv-2",
    clientName: "Juan dela Cruz",
    date: "Apr 29, 2026",
    preview: "Asked about small claims court procedure",
    messages: [
      { id: "m5", role: "user", content: "How do I file a small claims case? My neighbor owes me ₱80,000 and refuses to pay." },
      { id: "m6", role: "assistant", content: "You can file a small claims case at the Metropolitan Trial Court (MeTC) or Municipal Trial Court (MTC) with jurisdiction over where you or the defendant resides.\n\nProcess overview:\n1. Fill out the Statement of Claim form\n2. Attach supporting documents (receipts, contracts, agreements)\n3. Pay the filing fee: ₱1,000 – ₱2,000 for claims up to ₱100,000\n4. Serve summons — the court notifies the defendant\n5. Appear on hearing date — small claims are decided the same day\n\nSmall claims court covers money claims up to ₱400,000 under the 2022 Revised Rules. Your ₱80,000 claim is well within the threshold." },
      { id: "m7", role: "user", content: "Do I need a lawyer?" },
      { id: "m8", role: "assistant", content: "No — in fact, lawyers are not allowed to appear in small claims proceedings in the Philippines. This is by design to make the process faster and more accessible.\n\nYou will represent yourself (pro se). The court will guide you through the hearing. Just bring all your evidence and be prepared to explain your claim clearly.\n\nHowever, you may consult a lawyer beforehand to help you prepare your Statement of Claim and organize your evidence, even if they cannot appear with you in court." },
    ],
  },
  {
    id: "conv-3",
    clientName: "Rosa Reyes",
    date: "Apr 27, 2026",
    preview: "Asked about labor rights after termination",
    messages: [
      { id: "m9", role: "user", content: "I was terminated from my job without any notice. Is this legal?" },
      { id: "m10", role: "assistant", content: "Under Philippine labor law, termination without notice may be illegal depending on the circumstances. The Labor Code requires employers to follow due process before terminating an employee.\n\nFor just causes (serious misconduct, willful disobedience, gross neglect, etc.), the employer must:\n1. Issue a written Notice to Explain (NTE)\n2. Give the employee at least 5 calendar days to respond\n3. Conduct a hearing if requested\n4. Issue a Notice of Termination\n\nFor authorized causes (redundancy, retrenchment, closure), the employer must give 30-day advance written notice to both the employee AND the DOLE, plus separation pay.\n\nIf none of these were followed, your termination may be considered illegal dismissal. You may file a complaint with the NLRC within 4 years from the date of dismissal.\n\nI recommend documenting everything and consulting with a labor lawyer as soon as possible." },
    ],
  },
  {
    id: "conv-4",
    clientName: "Pedro Villanueva",
    date: "Apr 25, 2026",
    preview: "Asked about land title transfer process",
    messages: [
      { id: "m11", role: "user", content: "How do I transfer a land title to my name after my father passed away?" },
      { id: "m12", role: "assistant", content: "To transfer a land title through inheritance in the Philippines, you will need to go through the process of estate settlement. Here are the key steps:\n\n1. Secure an Extrajudicial Settlement of Estate (if all heirs agree and the estate has no debts)\n2. Have the document notarized and published in a newspaper of general circulation once a week for 3 consecutive weeks\n3. Pay estate tax at the BIR within 1 year from the date of death (extensions may apply)\n4. Present the documents to the Register of Deeds for transfer of title\n\nRequired documents typically include: Death certificate, Original land title, Tax declaration, Notarized extrajudicial settlement, BIR estate tax clearance, and payment of transfer tax.\n\nI strongly recommend hiring a lawyer to assist with the process as errors can cause significant delays." },
    ],
  },
];

export function ConversationsPage() {
  const navigate = useNavigate();
  const [selected, setSelected] = useState<Conversation | null>(null);
  const [search, setSearch] = useState("");

  const filtered = CONVERSATIONS.filter(
    (c) =>
      c.clientName.toLowerCase().includes(search.toLowerCase()) ||
      c.preview.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="mb-5">
        <h1 className="text-2xl font-bold text-[#241715]">Client Conversations</h1>
        <p className="mt-0.5 text-sm text-[#957186]">
          Browse client–AI conversations. Click a conversation to read it in full, then assess it in the AI Assessment tab.
        </p>
      </div>

      <div className="grid gap-4 lg:grid-cols-[320px_1fr]" style={{ minHeight: "calc(100vh - 220px)" }}>

        {/* ── Left: conversation list ── */}
        <div className="flex flex-col gap-3">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[#c490aa]" />
            <input
              type="text"
              placeholder="Search conversations…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full rounded-xl border border-[#d9b8c4] bg-white pl-9 pr-4 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] transition"
            />
          </div>

          {/* List */}
          <div className="space-y-2 overflow-y-auto">
            {filtered.length === 0 && (
              <p className="text-sm text-[#957186] text-center py-8">No conversations found.</p>
            )}
            {filtered.map((conv) => (
              <button
                key={conv.id}
                onClick={() => setSelected(conv)}
                className={cn(
                  "w-full text-left p-4 rounded-2xl border transition-all",
                  selected?.id === conv.id
                    ? "border-[#703d57] bg-[#f7f0f4]"
                    : "border-[#d9b8c4]/40 bg-white hover:border-[#703d57]/40 hover:bg-[#f7f0f4]"
                )}
              >
                <div className="flex items-center gap-3">
                  <div className="h-9 w-9 rounded-full bg-[#eedde8] flex items-center justify-center text-xs font-bold text-[#703d57] shrink-0">
                    {conv.clientName.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-1 mb-0.5">
                      <p className="text-sm font-semibold text-[#241715] truncate">{conv.clientName}</p>
                      <span className="text-[10px] text-[#957186] shrink-0">{conv.date}</span>
                    </div>
                    <p className="text-xs text-[#957186] truncate">{conv.preview}</p>
                    <p className="text-[11px] text-gray-400 mt-0.5">{conv.messages.length} messages</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* ── Right: full conversation view ── */}
        <div className="rounded-2xl border border-[#d9b8c4]/40 bg-white flex flex-col overflow-hidden">
          {!selected ? (
            <div className="flex-1 flex flex-col items-center justify-center text-center px-8 py-16">
              <div className="h-14 w-14 rounded-2xl bg-[#f7f0f4] border border-[#d9b8c4]/40 flex items-center justify-center mb-4">
                <Bot className="h-6 w-6 text-[#957186]" />
              </div>
              <p className="text-sm font-semibold text-[#241715]">Select a conversation</p>
              <p className="text-xs text-[#957186] mt-1 max-w-xs leading-relaxed">
                Choose a conversation from the left to read it in full view.
              </p>
            </div>
          ) : (
            <>
              {/* Conversation header */}
              <div className="flex items-center justify-between px-5 py-4 border-b border-[#d9b8c4]/30 bg-[#f7f0f4] shrink-0">
                <div className="flex items-center gap-3">
                  <button
                    onClick={() => setSelected(null)}
                    className="lg:hidden p-1 rounded-lg text-[#957186] hover:text-[#241715] transition"
                  >
                    <ChevronLeft className="h-5 w-5" />
                  </button>
                  <div className="h-9 w-9 rounded-full bg-[#eedde8] flex items-center justify-center text-xs font-bold text-[#703d57]">
                    {selected.clientName.split(" ").map((n) => n[0]).join("").slice(0, 2)}
                  </div>
                  <div>
                    <p className="text-sm font-bold text-[#241715]">{selected.clientName}</p>
                    <p className="text-xs text-[#957186]">{selected.date} · {selected.messages.length} messages</p>
                  </div>
                </div>
                {/* Assess this conversation button */}
                <button
                  onClick={() => navigate("/ai-assessment?tab=assessment")}
                  className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] transition"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  Assess this conversation
                </button>
              </div>

              {/* Messages — view only, no input */}
              <div className="flex-1 overflow-y-auto p-5 space-y-4">
                {selected.messages.map((msg) => (
                  <div key={msg.id} className={cn("flex gap-3", msg.role === "user" && "justify-end")}>
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
              </div>

              {/* Bottom bar with assess CTA */}
              <div className="px-5 py-3 border-t border-[#d9b8c4]/30 bg-[#f7f0f4] shrink-0 flex items-center justify-between gap-3">
                <p className="text-xs text-[#957186]">View only — no replies can be sent from this panel.</p>
                <button
                  onClick={() => navigate("/ai-assessment?tab=assessment")}
                  className="flex items-center gap-2 px-4 py-2 rounded-xl bg-[#703d57] text-xs font-semibold text-white hover:bg-[#5a3046] transition"
                >
                  <ExternalLink className="h-3.5 w-3.5" />
                  Assess in AI Assessment
                </button>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}