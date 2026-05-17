import { AlertTriangle, Check, Flag, ThumbsUp, X } from "lucide-react";
import { cn } from "@/lib/cn";

export interface MessageFeedback {
  messageId: string;
  type: "commend" | "report";
  issues?: string[];
  comment?: string;
}

export const REPORT_ISSUES = [
  { id: "incorrect", label: "Incorrect information", desc: "The AI stated facts that are legally inaccurate" },
  { id: "misleading", label: "Misleading advice", desc: "The response could lead the client to wrong conclusions" },
  { id: "outdated", label: "Outdated law cited", desc: "References repealed or amended legislation" },
  { id: "incomplete", label: "Incomplete answer", desc: "Important aspects of the legal question were omitted" },
  { id: "jurisdiction", label: "Wrong jurisdiction", desc: "Advice does not apply to Philippine law or the relevant region" },
  { id: "overconfident", label: "Overly confident tone", desc: "Presented uncertain information as definitive legal fact" },
  { id: "harmful", label: "Potentially harmful", desc: "Could cause legal or financial harm if followed" },
  { id: "other", label: "Other concern", desc: "Something else not listed above" },
];

interface AssistantMessageFeedbackBarProps {
  messageId: string;
  feedback?: MessageFeedback;
  submitted: string | null;
  feedbackBusy: boolean;
  onCommend: (messageId: string) => void;
  onReport: (messageId: string) => void;
}

export function AssistantMessageFeedbackBar({
  messageId,
  feedback,
  submitted,
  feedbackBusy,
  onCommend,
  onReport,
}: AssistantMessageFeedbackBarProps) {
  return (
    <div className="ml-10 mt-2 flex items-center gap-2 flex-wrap">
      {feedback?.type === "commend" ? (
        <span className="flex items-center gap-1 text-xs text-emerald-600 font-medium">
          <Check className="h-3.5 w-3.5" /> Commended
        </span>
      ) : feedback?.type === "report" ? (
        <span className="flex items-center gap-1 text-xs text-red-500 font-medium">
          <Flag className="h-3.5 w-3.5" /> Reported
        </span>
      ) : (
        <>
          <button
            type="button"
            disabled={feedbackBusy}
            onClick={() => onCommend(messageId)}
            className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-emerald-200 bg-emerald-50 text-xs font-medium text-emerald-700 hover:bg-emerald-100 transition disabled:opacity-50"
          >
            <ThumbsUp className="h-3 w-3" />
            Commend
          </button>
          <button
            type="button"
            disabled={feedbackBusy}
            onClick={() => onReport(messageId)}
            className="flex items-center gap-1.5 px-3 py-1 rounded-lg border border-red-200 bg-red-50 text-xs font-medium text-red-600 hover:bg-red-100 transition disabled:opacity-50"
          >
            <Flag className="h-3 w-3" />
            Report
          </button>
        </>
      )}
      {submitted === messageId && (
        <span className="text-xs text-[#957186] animate-pulse">Saved ✓</span>
      )}
    </div>
  );
}

interface ReportFeedbackModalProps {
  reportTarget: string | null;
  selectedIssues: string[];
  comment: string;
  feedbackBusy: boolean;
  onClose: () => void;
  onToggleIssue: (id: string) => void;
  onCommentChange: (value: string) => void;
  onSubmit: () => void;
}

export function ReportFeedbackModal({
  reportTarget,
  selectedIssues,
  comment,
  feedbackBusy,
  onClose,
  onToggleIssue,
  onCommentChange,
  onSubmit,
}: ReportFeedbackModalProps) {
  if (!reportTarget) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/40 p-4 overflow-y-auto"
      role="presentation"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="report-modal-title"
        className="w-full max-w-lg max-h-[min(90dvh,calc(100vh-2rem))] flex flex-col rounded-2xl bg-white shadow-2xl my-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between p-5 sm:p-6 border-b border-[#d9b8c4]/30 shrink-0">
          <div className="flex items-center gap-3 min-w-0">
            <div className="h-9 w-9 rounded-xl bg-red-100 flex items-center justify-center shrink-0">
              <AlertTriangle className="h-5 w-5 text-red-600" />
            </div>
            <div className="min-w-0">
              <h2 id="report-modal-title" className="font-bold text-[#241715]">
                Report AI Response
              </h2>
              <p className="text-xs text-[#957186] mt-0.5">Logged for your QA records</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1 rounded-lg text-gray-400 hover:text-gray-600 transition shrink-0"
            aria-label="Close"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto min-h-0 p-5 sm:p-6 space-y-4">
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
                    onClick={() => onToggleIssue(issue.id)}
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
              onChange={(e) => onCommentChange(e.target.value)}
              placeholder="Describe the specific error or provide the correct information…"
              className="w-full rounded-xl border border-[#d9b8c4] bg-[#fdf9fb] px-3.5 py-2.5 text-sm text-[#241715] placeholder-[#c490aa] outline-none focus:border-[#703d57] focus:bg-white transition resize-none"
            />
          </div>
        </div>

        <div className="flex gap-3 px-5 sm:px-6 py-4 border-t border-[#d9b8c4]/30 bg-white rounded-b-2xl shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 py-2.5 rounded-xl border border-[#d9b8c4] text-sm font-semibold text-[#957186] hover:bg-[#f7f0f4] transition"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onSubmit}
            disabled={selectedIssues.length === 0 || feedbackBusy}
            className="flex-1 py-2.5 rounded-xl bg-red-600 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition flex items-center justify-center gap-2"
          >
            <Flag className="h-4 w-4" />
            Send report
          </button>
        </div>
      </div>
    </div>
  );
}
