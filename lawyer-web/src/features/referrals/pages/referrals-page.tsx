import { FileText } from "lucide-react";

export function ReferralsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Referrals</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage incoming client referrals and consultation summaries.
        </p>
      </div>

      <div className="flex flex-col items-center justify-center rounded-xl border border-dashed border-gray-300 bg-white py-16">
        <FileText className="h-12 w-12 text-gray-300" />
        <h3 className="mt-4 text-sm font-semibold text-gray-900">
          No referrals yet
        </h3>
        <p className="mt-1 max-w-sm text-center text-sm text-gray-500">
          When clients generate a consultation PDF and request a lawyer referral,
          their cases will appear here.
        </p>
      </div>
    </div>
  );
}
