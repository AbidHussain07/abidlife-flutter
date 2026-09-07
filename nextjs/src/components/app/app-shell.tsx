"use client";

import { AnimatePresence, motion } from "framer-motion";
import { CheckCircle2 } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { BottomNav } from "./bottom-nav";
import { DataProvider, useData, type Tab } from "./data";
import { LumaLogo } from "./logo";
import { InsightsScreen } from "./insights-screen";
import { MoneyScreen } from "./money/money-screen";
import { NotesScreen } from "./notes/notes-screen";
import { Onboarding } from "./onboarding";
import { TasksScreen } from "./tasks-screen";
import { HabitsScreen } from "./habits/habits-screen";
import { ThemeProvider, useTheme } from "./theme";

/* ------------------------------- Toasts ---------------------------------- */

function Toasts() {
  const { toasts } = useData();
  return (
    <div className="pointer-events-none absolute inset-x-0 top-4 z-[70] flex flex-col items-center gap-2 px-6">
      <AnimatePresence>
        {toasts.map((t) => (
          <motion.div
            key={t.id}
            initial={{ opacity: 0, y: -12, scale: 0.92 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -8, scale: 0.95 }}
            transition={{ type: "spring", stiffness: 500, damping: 34 }}
            className="flex items-center gap-2 rounded-full border border-line px-4 py-2 text-[12.5px] font-bold text-ink"
            style={{
              background: "color-mix(in srgb, var(--surface) 92%, transparent)",
              backdropFilter: "blur(14px)",
              boxShadow: "var(--shadow-pop)",
            }}
          >
            <CheckCircle2 size={14} style={{ color: "var(--green)" }} />
            {t.msg}
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

/* ------------------------------ Splash ---------------------------------- */

function Splash() {
  return (
    <div className="flex h-full flex-col items-center justify-center bg-app">
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ type: "spring", stiffness: 260, damping: 18 }}
      >
        <LumaLogo size={64} />
      </motion.div>
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="mt-4 text-[17px] font-extrabold tracking-tight text-ink"
      >
        ABIDLIFE
      </motion.p>
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.32 }}
        className="mt-1 text-[12.5px] font-medium text-ink-3"
      >
        Everything you need, in one place
      </motion.p>
    </div>
  );
}

/* ------------------------------ Screens ---------------------------------- */

const SCREENS: Record<Tab, React.ComponentType> = {
  notes: NotesScreen,
  tasks: TasksScreen,
  habits: HabitsScreen,
  money: MoneyScreen,
  insights: InsightsScreen,
};

function Screens() {
  const { tab } = useData();
  const Active = SCREENS[tab];
  return (
    <div className="relative min-h-0 flex-1 overflow-hidden">
      <AnimatePresence mode="wait">
        <motion.div
          key={tab}
          initial={{ opacity: 0, y: 14, scale: 0.995 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -10, scale: 0.995 }}
          transition={{ duration: 0.26, ease: [0.22, 1, 0.36, 1] }}
          className="h-full"
        >
          <Active />
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

/* ------------------------------- Stage ----------------------------------- */

function Stage() {
  const { loading } = useData();
  const { resolved } = useTheme();
  const [onboarded, setOnboarded] = useState<boolean | null>(null);

  useEffect(() => {
    setOnboarded(window.localStorage.getItem("abidlife.onboarded") === "1");
    const replay = () => setOnboarded(false);
    window.addEventListener("abidlife:replay", replay);
    return () => window.removeEventListener("abidlife:replay", replay);
  }, []);

  const finishOnboarding = useCallback(() => {
    window.localStorage.setItem("abidlife.onboarded", "1");
    setOnboarded(true);
  }, []);

  return (
    <div className="relative min-h-[100dvh] w-full overflow-hidden bg-[#05060a] sm:grid sm:place-items-center">
      {/* Desktop ambient scene */}
      <div aria-hidden className="pointer-events-none absolute inset-0 hidden sm:block">
        <div
          className="absolute -left-40 -top-40 h-[560px] w-[560px] rounded-full opacity-25 blur-[130px]"
          style={{ background: "radial-gradient(circle, #6e5bff, transparent 65%)" }}
        />
        <div
          className="absolute -bottom-48 -right-32 h-[520px] w-[520px] rounded-full opacity-20 blur-[130px]"
          style={{ background: "radial-gradient(circle, #11a598, transparent 65%)" }}
        />
        <div
          className="absolute left-1/2 top-1/2 h-[700px] w-[700px] -translate-x-1/2 -translate-y-1/2 opacity-[0.04]"
          style={{
            backgroundImage:
              "radial-gradient(circle, white 1px, transparent 1px)",
            backgroundSize: "26px 26px",
          }}
        />
      </div>
      <div
        aria-hidden
        className="pointer-events-none absolute bottom-7 left-8 hidden select-none lg:block"
      >
        <p className="text-[13px] font-extrabold tracking-tight text-white/60">
          ABIDLIFE
        </p>
        <p className="mt-1 max-w-[220px] text-[11.5px] leading-relaxed text-white/30">
          Notes · Tasks · Habits · Money · Insights — everything you need, in
          one place.
        </p>
      </div>
      <div
        aria-hidden
        className="pointer-events-none absolute bottom-7 right-8 hidden select-none text-right lg:block"
      >
        <p className="text-[11.5px] text-white/30">
          Tip: press <span className="font-bold text-white/50">1–5</span> to
          switch sections
        </p>
      </div>

      {/* Phone frame */}
      <div
        className="relative mx-auto h-[100dvh] w-full max-w-[430px] overflow-hidden sm:h-[min(880px,94dvh)] sm:rounded-[46px] sm:border sm:border-white/10"
        style={{ boxShadow: "0 60px 140px -30px rgba(0,0,0,0.8)" }}
      >
        <div
          className={`${resolved === "dark" ? "dark" : ""} relative flex h-full flex-col bg-app text-ink`}
        >
          {onboarded === null ? null : !onboarded ? (
            <Onboarding onDone={finishOnboarding} />
          ) : loading ? (
            <Splash />
          ) : (
            <>
              <Screens />
              <BottomNav />
              <Toasts />
            </>
          )}
        </div>
      </div>
    </div>
  );
}

export function AppShell() {
  return (
    <ThemeProvider>
      <DataProvider>
        <Stage />
      </DataProvider>
    </ThemeProvider>
  );
}
