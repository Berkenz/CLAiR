import ReactMarkdown from "react-markdown";
import type { Components } from "react-markdown";

interface ChatMarkdownProps {
  content: string;
  variant?: "assistant" | "user";
}

function buildComponents(variant: "assistant" | "user"): Components {
  const linkClass =
    variant === "user"
      ? "underline underline-offset-2 text-white/95 hover:text-white"
      : "underline underline-offset-2 text-[#703d57] hover:text-[#5a3046]";

  return {
    p: ({ children }) => <p className="mb-2 last:mb-0">{children}</p>,
    strong: ({ children }) => <strong className="font-semibold">{children}</strong>,
    em: ({ children }) => <em className="italic">{children}</em>,
    ul: ({ children }) => (
      <ul className="mb-2 last:mb-0 list-disc pl-5 space-y-1">{children}</ul>
    ),
    ol: ({ children }) => (
      <ol className="mb-2 last:mb-0 list-decimal pl-5 space-y-1">{children}</ol>
    ),
    li: ({ children }) => <li>{children}</li>,
    h1: ({ children }) => <p className="mb-2 font-semibold">{children}</p>,
    h2: ({ children }) => <p className="mb-2 font-semibold">{children}</p>,
    h3: ({ children }) => <p className="mb-2 font-semibold">{children}</p>,
    a: ({ href, children }) => (
      <a href={href} target="_blank" rel="noopener noreferrer" className={linkClass}>
        {children}
      </a>
    ),
    blockquote: ({ children }) => (
      <blockquote
        className={
          variant === "user"
            ? "border-l-2 border-white/40 pl-3 my-2 opacity-95"
            : "border-l-2 border-[#703d57]/40 pl-3 my-2"
        }
      >
        {children}
      </blockquote>
    ),
    code: ({ children }) => (
      <code
        className={
          variant === "user"
            ? "rounded bg-white/15 px-1 py-0.5 font-mono text-[0.85em]"
            : "rounded bg-[#241715]/8 px-1 py-0.5 font-mono text-[0.85em] text-[#5a3046]"
        }
      >
        {children}
      </code>
    ),
    pre: ({ children }) => (
      <pre
        className={
          variant === "user"
            ? "rounded-lg bg-white/10 p-3 my-2 overflow-x-auto text-xs font-mono"
            : "rounded-lg bg-[#241715]/5 border border-[#d9b8c4]/60 p-3 my-2 overflow-x-auto text-xs font-mono"
        }
      >
        {children}
      </pre>
    ),
  };
}

export function ChatMarkdown({ content, variant = "assistant" }: ChatMarkdownProps) {
  return (
    <ReactMarkdown components={buildComponents(variant)}>{content}</ReactMarkdown>
  );
}
