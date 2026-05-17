import { useEffect, useState } from "react";
import { cn } from "@/lib/cn";
import clairIcon from "@/assets/images/CLAiR-icon.png";

export function SplashScreen() {
  const [phase, setPhase] = useState<"enter" | "hold" | "exit">("enter");

  useEffect(() => {
    const t1 = setTimeout(() => setPhase("hold"), 600);
    const t2 = setTimeout(() => setPhase("exit"), 2000);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  return (
    <div className={cn(
      "fixed inset-0 z-50 flex flex-col items-center justify-center bg-[#241715] transition-opacity duration-500",
      phase === "exit" ? "opacity-0 pointer-events-none" : "opacity-100"
    )}>
      <div className={cn(
        "flex flex-col items-center gap-5 transition-all duration-700",
        phase === "enter" ? "opacity-0 scale-90 translate-y-4" : "opacity-100 scale-100 translate-y-0"
      )}>
        {/* Logo with glow */}
        <div className="relative flex items-center justify-center">
          {/* Soft glow behind logo */}
          <div className={cn(
            "absolute h-32 w-32 rounded-full bg-[#703d57]/25 blur-2xl transition-all duration-1000",
            phase === "hold" || phase === "exit" ? "scale-150 opacity-100" : "scale-75 opacity-0"
          )} />
          {/* Actual logo — CSS filter makes the dark red match our #d9b8c4 palette on dark bg */}
          <img
            src={clairIcon}
            alt="CLAiR"
            className="relative h-28 w-28 object-contain"
            style={{
              filter:
                "brightness(0) saturate(100%) invert(78%) sepia(18%) saturate(400%) hue-rotate(295deg) brightness(105%) contrast(85%)",
            }}
          />
        </div>

        {/* Wordmark */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-white tracking-widest">CLAiR</h1>
          <p className="text-[#957186] text-xs tracking-[0.25em] uppercase mt-1.5">
            Legal Practice Management
          </p>
        </div>

        {/* Bouncing dots */}
        <div className={cn(
          "flex items-center gap-1.5 mt-1 transition-all duration-500",
          phase === "enter" ? "opacity-0" : "opacity-100"
        )}>
          {[0, 1, 2].map((i) => (
            <div
              key={i}
              className="h-1.5 w-1.5 rounded-full bg-[#703d57] animate-bounce"
              style={{ animationDelay: `${i * 0.18}s`, animationDuration: "0.9s" }}
            />
          ))}
        </div>
      </div>

      {/* Bottom tagline */}
      <p className={cn(
        "absolute bottom-10 text-[10px] text-white/20 tracking-widest uppercase transition-all duration-700",
        phase === "enter" ? "opacity-0" : "opacity-100"
      )}>
        Powered by AI · Built for Filipino Lawyers
      </p>
    </div>
  );
}