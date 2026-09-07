"use client";

import { AnimatePresence, motion } from "framer-motion";
import {
  ArrowRight,
  Flame,
  IndianRupee,
  NotebookPen,
  Sparkles,
} from "lucide-react";
import { useState } from "react";
import { LumaLogo } from "./logo";
import { buzz, tint } from "./ui";

const SLIDES = [
  {
    title: "Everything you need, in one place.",
    sub: "Notes, tasks, habits and money — one calm home for your whole day.",
    art: (
      <div className="relative h-44 w-64">
        {[
          { r: -7, y: 6, c: "var(--note-yellow)", x: -18 },
          { r: 5, y: 2, c: "var(--note-purple)", x: 16 },
          { r: -2, y: 26, c: "var(--surface)", x: 0 },
        ].map((k, i) => (
          <motion.div
            key={i}
            initial={{ opacity: 0, y: 24, rotate: k.r - 4 }}
            animate={{ opacity: 1, y: k.y, rotate: k.r }}
            transition={{ delay: 0.15 + i * 0.12, type: "spring", stiffness: 200, damping: 20 }}
            className="absolute left-1/2 top-8 h-28 w-36 -translate-x-1/2 rounded-3xl border border-line p-3"
            style={{ background: k.c, marginLeft: k.x, boxShadow: "var(--shadow-card)" }}
          >
            <div className="h-2 w-14 rounded-full" style={{ background: tint("violet", 30) }} />
            <div className="mt-2 space-y-1.5">
              <div className="h-1.5 w-full rounded-full bg-[var(--surface-3)]" />
              <div className="h-1.5 w-4/5 rounded-full bg-[var(--surface-3)]" />
              <div className="h-1.5 w-3/5 rounded-full bg-[var(--surface-3)]" />
            </div>
          </motion.div>
        ))}
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.6, type: "spring", stiffness: 300, damping: 16 }}
          className="absolute right-2 top-2 grid h-11 w-11 place-items-center rounded-2xl text-white"
          style={{ background: "var(--brand)" }}
        >
          <Sparkles size={19} />
        </motion.div>
      </div>
    ),
  },
  {
    title: "Organize your thoughts, tasks and habits.",
    sub: "Capture ideas in seconds, finish what matters, and build streaks that stick.",
    art: (
      <div className="relative flex h-44 w-64 items-center justify-center gap-3.5">
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.15, type: "spring", stiffness: 220, damping: 20 }}
          className="flex h-36 w-28 flex-col gap-2 rounded-3xl border border-line bg-surface p-3"
          style={{ boxShadow: "var(--shadow-card)" }}
        >
          {[1, 0.75, 0.55].map((o, i) => (
            <div key={i} className="flex items-center gap-2" style={{ opacity: o }}>
              <span
                className="grid h-4.5 w-4.5 place-items-center rounded-full"
                style={{ background: i === 0 ? "var(--green)" : "var(--surface-3)" }}
              >
                {i === 0 && (
                  <svg width="9" height="9" viewBox="0 0 12 12" fill="none">
                    <path d="M2 6.2 4.8 9 10 3.4" stroke="white" strokeWidth="2" strokeLinecap="round" />
                  </svg>
                )}
              </span>
              <div className="h-1.5 flex-1 rounded-full bg-[var(--surface-3)]" />
            </div>
          ))}
          <div className="mt-auto h-1.5 w-10 rounded-full" style={{ background: tint("blue", 40) }} />
        </motion.div>
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3, type: "spring", stiffness: 220, damping: 20 }}
          className="grid h-36 w-28 place-items-center rounded-3xl border border-line bg-surface"
          style={{ boxShadow: "var(--shadow-card)" }}
        >
          <div
            className="grid h-16 w-16 place-items-center rounded-full"
            style={{ background: tint("green", 14), color: "var(--green)" }}
          >
            <Flame size={28} fill="currentColor" />
          </div>
          <p className="-mt-4 text-[12px] font-extrabold text-ink">8 day streak</p>
        </motion.div>
      </div>
    ),
  },
  {
    title: "Keep track of your money and progress.",
    sub: "A friendly money dashboard and insights that connect the dots of your life.",
    art: (
      <div className="relative flex h-44 w-64 items-center justify-center">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15, type: "spring", stiffness: 220, damping: 20 }}
          className="w-48 rounded-3xl border border-line bg-surface p-4"
          style={{ boxShadow: "var(--shadow-card)" }}
        >
          <div className="flex items-center gap-2">
            <span className="grid h-8 w-8 place-items-center rounded-xl" style={{ background: tint("teal", 14), color: "var(--teal)" }}>
              <IndianRupee size={16} />
            </span>
            <div className="h-1.5 w-14 rounded-full bg-[var(--surface-3)]" />
          </div>
          <p className="tnum mt-3 text-[24px] font-extrabold tracking-tight text-ink">₹42,500</p>
          <div className="mt-3 flex h-12 items-end gap-1.5">
            {[35, 55, 42, 70, 58, 86].map((h, i) => (
              <motion.div
                key={i}
                initial={{ height: 4 }}
                animate={{ height: `${h}%` }}
                transition={{ delay: 0.4 + i * 0.07, type: "spring", stiffness: 200, damping: 22 }}
                className="flex-1 rounded-md"
                style={{ background: i === 5 ? "var(--teal)" : tint("teal", 25) }}
              />
            ))}
          </div>
        </motion.div>
      </div>
    ),
  },
];

export function Onboarding({ onDone }: { onDone: () => void }) {
  const [i, setI] = useState(0);
  const last = i === SLIDES.length - 1;

  const next = () => {
    buzz(8);
    if (last) onDone();
    else setI((x) => x + 1);
  };

  return (
    <div className="relative flex h-full flex-col bg-app px-7 pb-8 pt-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <LumaLogo size={30} />
          <span className="text-[15px] font-extrabold tracking-tight text-ink">
            ABIDLIFE
          </span>
        </div>
        <button
          type="button"
          onClick={() => {
            buzz(6);
            onDone();
          }}
          className="rounded-full px-3 py-1.5 text-[13px] font-bold text-ink-3 transition-colors active:bg-[var(--surface-2)]"
        >
          Skip
        </button>
      </div>

      <div className="flex-1 overflow-hidden">
        <AnimatePresence mode="wait">
          <motion.div
            key={i}
            initial={{ opacity: 0, x: 34 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -34 }}
            transition={{ duration: 0.34, ease: [0.22, 1, 0.36, 1] }}
            className="flex h-full flex-col items-center justify-center text-center"
          >
            {SLIDES[i].art}
            <h1 className="mt-10 max-w-[310px] text-[26px] font-extrabold leading-[1.18] tracking-[-0.02em] text-ink">
              {SLIDES[i].title}
            </h1>
            <p className="mt-3 max-w-[290px] text-[14px] leading-relaxed text-ink-3">
              {SLIDES[i].sub}
            </p>
          </motion.div>
        </AnimatePresence>
      </div>

      <div className="flex items-center justify-between">
        <div className="flex gap-1.5">
          {SLIDES.map((_, d) => (
            <motion.span
              key={d}
              layout
              className="h-1.5 rounded-full"
              animate={{
                width: d === i ? 24 : 7,
                background: d === i ? "var(--brand)" : "var(--surface-3)",
              }}
            />
          ))}
        </div>
        <motion.button
          type="button"
          whileTap={{ scale: 0.94 }}
          onClick={next}
          className="flex items-center gap-2 rounded-full py-3 pl-6 pr-3 text-[14.5px] font-bold text-white"
          style={{ background: "var(--brand)", boxShadow: "0 10px 24px -8px color-mix(in srgb, var(--brand) 60%, transparent)" }}
        >
          {last ? "Get started" : "Next"}
          <span className="grid h-7 w-7 place-items-center rounded-full bg-white/20">
            <ArrowRight size={14} strokeWidth={2.6} />
          </span>
        </motion.button>
      </div>
    </div>
  );
}
