"use client";

import { motion } from "framer-motion";
import {
  CheckCircle2,
  Flame,
  NotebookPen,
  Sparkles,
  Wallet,
  type LucideIcon,
} from "lucide-react";
import { useEffect } from "react";
import { useData, type Tab } from "./data";
import { buzz, tint, PALETTE } from "./ui";

const ITEMS: { key: Tab; label: string; icon: LucideIcon; color: string }[] = [
  { key: "notes", label: "Notes", icon: NotebookPen, color: "amber" },
  { key: "tasks", label: "Tasks", icon: CheckCircle2, color: "blue" },
  { key: "habits", label: "Habits", icon: Flame, color: "green" },
  { key: "money", label: "Money", icon: Wallet, color: "teal" },
  { key: "insights", label: "Insights", icon: Sparkles, color: "violet" },
];

export function BottomNav() {
  const { tab, setTab } = useData();

  // Desktop nicety: press 1–5 to jump between sections.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      const idx = ["1", "2", "3", "4", "5"].indexOf(e.key);
      if (idx >= 0) {
        setTab(ITEMS[idx].key);
        buzz(6);
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [setTab]);

  return (
    <div className="pointer-events-none absolute inset-x-3 bottom-3 z-40">
      <nav
        aria-label="Main navigation"
        className="pointer-events-auto flex items-center rounded-[26px] border border-line p-1.5"
        style={{
          background: "color-mix(in srgb, var(--surface) 82%, transparent)",
          backdropFilter: "blur(18px)",
          WebkitBackdropFilter: "blur(18px)",
          boxShadow: "var(--shadow-pop)",
        }}
      >
        {ITEMS.map((it) => {
          const active = tab === it.key;
          return (
            <button
              key={it.key}
              type="button"
              aria-label={it.label}
              aria-current={active ? "page" : undefined}
              onClick={() => {
                buzz(7);
                setTab(it.key);
              }}
              className="relative flex h-12 flex-1 items-center justify-center rounded-[19px]"
            >
              {active && (
                <motion.span
                  layoutId="nav-pill"
                  transition={{ type: "spring", stiffness: 500, damping: 38 }}
                  className="absolute inset-0 rounded-[19px]"
                  style={{ background: tint(it.color, 15) }}
                />
              )}
              <span className="relative flex items-center gap-1.5">
                <it.icon
                  size={20}
                  strokeWidth={active ? 2.4 : 2}
                  style={{
                    color: active ? PALETTE[it.color] : "var(--ink-3)",
                    transition: "color .25s",
                  }}
                />
                {active && (
                  <motion.span
                    initial={{ opacity: 0, width: 0 }}
                    animate={{ opacity: 1, width: "auto" }}
                    exit={{ opacity: 0, width: 0 }}
                    className="overflow-hidden text-[12.5px] font-extrabold"
                    style={{ color: PALETTE[it.color] }}
                  >
                    {it.label}
                  </motion.span>
                )}
              </span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}
