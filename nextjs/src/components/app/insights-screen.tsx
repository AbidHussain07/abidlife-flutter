"use client";

import {
  addDays,
  format,
  isSameMonth,
  isSameWeek,
  parseISO,
  startOfDay,
  subMonths,
} from "date-fns";
import { motion } from "framer-motion";
import {
  CheckCircle2,
  Flame,
  Lightbulb,
  ListPlus,
  Monitor,
  MoonStar,
  NotebookPen,
  Plus,
  RotateCcw,
  Settings2,
  Sun,
  Sunrise,
  Sunset,
  TrendingDown,
  TrendingUp,
  Wallet,
  Zap,
  type LucideIcon,
} from "lucide-react";
import { useMemo, useState } from "react";
import { LumaLogo } from "./logo";
import {
  dateStr,
  fmtINR,
  getStreaks,
  greeting,
  scheduledOn,
  todayStr,
  useData,
} from "./data";
import { buzz, Money, noteColor, Sheet, tint, PALETTE, ACCOUNT_ICONS } from "./ui";
import { useTheme, type ThemeMode } from "./theme";

const GREETING_ICONS: [number, LucideIcon][] = [
  [5, Sunrise],
  [12, Sun],
  [17, Sunset],
  [21, MoonStar],
];

export function InsightsScreen() {
  const { notes, tasks, habits, logs, accounts, txns, setTab, requestQuick } = useData();
  const [settingsOpen, setSettingsOpen] = useState(false);
  const hour = new Date().getHours();
  const GIcon = GREETING_ICONS.reduce((a, [h, i]) => (hour >= h ? i : a), MoonStar);
  const tStr = todayStr();
  const now = new Date();

  /* ------------------------------ Derivations ------------------------------ */

  const scheduledToday = habits.filter((h) => !h.archived && scheduledOn(h, now));
  const habitsDone = scheduledToday.filter((h) =>
    logs.some((l) => l.habitId === h.id && l.date === tStr),
  ).length;

  const bestStreak = habits.reduce(
    (m, h) => {
      const dates = new Set(logs.filter((l) => l.habitId === h.id).map((l) => l.date));
      const s = getStreaks(h, dates);
      return s.current > m.current ? { current: s.current, name: h.name } : m;
    },
    { current: 0, name: "" },
  );

  const openTasks = tasks.filter((t) => !t.done);
  const dueToday = openTasks.filter((t) => t.dueDate && t.dueDate <= tStr);
  const weekDone = tasks.filter(
    (t) => t.done && t.completedAt && isSameWeek(parseISO(t.completedAt), now, { weekStartsOn: 1 }),
  );
  const weekDue = tasks.filter(
    (t) => t.dueDate && isSameWeek(parseD2(t.dueDate), now, { weekStartsOn: 1 }),
  );
  const weekPct = weekDue.length > 0 ? Math.round((weekDue.filter((t) => t.done).length / weekDue.length) * 100) : null;

  const balanceAll = txns.reduce(
    (s, t) => s + (t.type === "income" ? t.amount : -t.amount),
    0,
  );
  const monthTxns = txns.filter((t) => isSameMonth(parseISO(t.occurredAt), now));
  const monthOut = monthTxns.filter((t) => t.type === "expense").reduce((s, t) => s + t.amount, 0);
  const lastMonthOut = txns
    .filter((t) => t.type === "expense" && isSameMonth(parseISO(t.occurredAt), subMonths(now, 1)))
    .reduce((s, t) => s + t.amount, 0);
  const momDelta =
    lastMonthOut > 0 && monthOut > 0
      ? Math.round(((monthOut - lastMonthOut) / lastMonthOut) * 100)
      : null;

  const notesLive = notes.filter((n) => !n.archived);
  const notesThisWeek = notesLive.filter((n) =>
    isSameWeek(parseISO(n.updatedAt), now, { weekStartsOn: 1 }),
  ).length;

  const insights: { icon: LucideIcon; color: string; text: string }[] = [];
  if (bestStreak.current >= 3)
    insights.push({
      icon: Flame,
      color: "orange",
      text: `You're on a ${bestStreak.current}-day ${bestStreak.name.toLowerCase()} streak. Protect it today.`,
    });
  if (weekPct !== null)
    insights.push({
      icon: CheckCircle2,
      color: "blue",
      text: `You've completed ${weekPct}% of this week's tasks${weekPct >= 80 ? " — excellent pace" : ""}.`,
    });
  if (momDelta !== null && Math.abs(momDelta) >= 5)
    insights.push({
      icon: momDelta <= 0 ? TrendingDown : TrendingUp,
      color: momDelta <= 0 ? "green" : "pink",
      text:
        momDelta <= 0
          ? `Your spending is ${Math.abs(momDelta)}% lower than last month.`
          : `Your spending is ${momDelta}% higher than last month.`,
    });
  if (notesThisWeek >= 2)
    insights.push({
      icon: NotebookPen,
      color: "amber",
      text: `${notesThisWeek} notes touched this week — your second brain is active.`,
    });

  const weekDays = useMemo(
    () =>
      Array.from({ length: 7 }, (_, i) =>
        dateStr(addDays(startOfDay(now), i - 6)),
      ),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [tStr],
  );

  const recentNotes = [...notesLive]
    .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
    .slice(0, 4);

  return (
    <div className="relative flex h-full flex-col">
      {/* Header */}
      <div className="flex items-start px-5 pb-2 pt-5">
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <GIcon size={17} style={{ color: "var(--amber)" }} />
            <p className="text-[13px] font-bold text-ink-2">
              {greeting(hour)}
            </p>
          </div>
          <h1 className="mt-1 text-[26px] font-extrabold tracking-[-0.02em] text-ink">
            Here's your day.
          </h1>
          <p className="text-[12.5px] font-medium text-ink-3">
            {format(now, "EEEE, d MMMM yyyy")}
          </p>
        </div>
        <button
          type="button"
          aria-label="Settings"
          onClick={() => {
            buzz(6);
            setSettingsOpen(true);
          }}
          className="mt-1 grid h-10 w-10 place-items-center rounded-2xl border border-line bg-surface text-ink-2 transition-transform active:scale-92"
        >
          <Settings2 size={17} />
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {/* Stat grid */}
        <div className="grid grid-cols-2 gap-3 pt-2">
          <StatCard
            color="green"
            icon={Flame}
            label="Habits"
            big={habits.length === 0 ? "—" : `${habitsDone}/${scheduledToday.length}`}
            sub={
              habits.length === 0
                ? "Create your first habit"
                : bestStreak.current > 0
                  ? `${bestStreak.current} day streak`
                  : "No streak yet"
            }
            onClick={() => setTab("habits")}
          />
          <StatCard
            color="blue"
            icon={CheckCircle2}
            label="Tasks"
            big={`${dueToday.length}`}
            sub={dueToday.length === 0 ? "Nothing due today" : `task${dueToday.length === 1 ? "" : "s"} left today`}
            onClick={() => setTab("tasks")}
          />
          <StatCard
            color="teal"
            icon={Wallet}
            label="Money"
            big={accounts.length === 0 ? "—" : fmtINR(balanceAll)}
            sub={
              accounts.length === 0
                ? "Add your first account"
                : monthOut > 0
                  ? `${fmtINR(monthOut)} spent in ${format(now, "MMM")}`
                  : "No spending yet"
            }
            onClick={() => setTab("money")}
            small
          />
          <StatCard
            color="amber"
            icon={NotebookPen}
            label="Notes"
            big={`${notesLive.length}`}
            sub={notesThisWeek > 0 ? `${notesThisWeek} updated this week` : "Capture an idea"}
            onClick={() => setTab("notes")}
          />
        </div>

        {/* Quick actions */}
        <div className="flex gap-2 overflow-x-auto pt-4 no-scrollbar">
          {[
            { label: "New note", icon: NotebookPen, tab: "notes" as const },
            { label: "New task", icon: ListPlus, tab: "tasks" as const },
            { label: "New habit", icon: Plus, tab: "habits" as const },
            { label: "Find note", icon: Zap, tab: "notes" as const, action: "search" },
          ].map((qa) => (
            <button
              key={qa.label}
              type="button"
              onClick={() => {
                buzz(7);
                requestQuick(qa.tab, qa.action ?? "new");
              }}
              className="flex shrink-0 items-center gap-1.5 rounded-full border border-line bg-surface px-3.5 py-2 text-[12.5px] font-bold text-ink-2 transition-transform active:scale-95"
            >
              <qa.icon size={13.5} style={{ color: "var(--brand)" }} />
              {qa.label}
            </button>
          ))}
        </div>

        {/* Smart insights */}
        {insights.length > 0 && (
          <div className="pt-5">
            <p className="flex items-center gap-1.5 px-1 pb-2.5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
              <Lightbulb size={13} style={{ color: "var(--amber)" }} />
              Smart insights
            </p>
            <div className="space-y-2">
              {insights.map((ins, i) => (
                <motion.div
                  key={ins.text}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.07 }}
                  className="flex items-center gap-3 rounded-[20px] border border-line bg-surface p-3.5"
                  style={{ boxShadow: "var(--shadow-card)" }}
                >
                  <span
                    className="grid h-9 w-9 shrink-0 place-items-center rounded-xl"
                    style={{ background: tint(ins.color, 13), color: PALETTE[ins.color] }}
                  >
                    <ins.icon size={16} />
                  </span>
                  <p className="text-[13px] font-semibold leading-snug text-ink-2">
                    {ins.text}
                  </p>
                </motion.div>
              ))}
            </div>
          </div>
        )}

        {/* Week at a glance */}
        {habits.length > 0 && (
          <div className="pt-5">
            <p className="px-1 pb-2.5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
              This week · habits
            </p>
            <div
              className="rounded-[22px] border border-line bg-surface p-3.5"
              style={{ boxShadow: "var(--shadow-card)" }}
            >
              <div className="flex justify-between px-[52px] pb-2">
                {weekDays.map((d) => (
                  <span key={d} className="w-4 text-center text-[9px] font-extrabold uppercase text-ink-3">
                    {format(new Date(d + "T12:00:00"), "EEEEE")}
                  </span>
                ))}
              </div>
              {habits
                .filter((h) => !h.archived)
                .map((h) => {
                  const dates = new Set(
                    logs.filter((l) => l.habitId === h.id).map((l) => l.date),
                  );
                  return (
                    <div key={h.id} className="flex items-center justify-between py-1.5">
                      <span className="w-[52px] truncate text-[11.5px] font-bold text-ink-2">
                        {h.name}
                      </span>
                      {weekDays.map((d) => (
                        <span
                          key={d}
                          className="h-4 w-4 rounded-full transition-colors"
                          style={{
                            background: dates.has(d)
                              ? PALETTE[h.color] ?? "var(--green)"
                              : d > tStr || !scheduledOn(h, new Date(d + "T12:00:00"))
                                ? "var(--surface-2)"
                                : tint(h.color, 20),
                          }}
                        />
                      ))}
                    </div>
                  );
                })}
            </div>
          </div>
        )}

        {/* Recent notes */}
        {recentNotes.length > 0 && (
          <div className="pt-5">
            <div className="flex items-center justify-between px-1 pb-2.5">
              <p className="text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
                Recent notes
              </p>
              <button
                type="button"
                onClick={() => setTab("notes")}
                className="text-[11.5px] font-bold text-brand"
              >
                View all
              </button>
            </div>
            <div className="flex gap-2.5 overflow-x-auto pb-1 no-scrollbar">
              {recentNotes.map((n) => (
                <button
                  key={n.id}
                  type="button"
                  onClick={() => setTab("notes")}
                  className="w-[132px] shrink-0 rounded-[20px] border border-line p-3 text-left transition-transform active:scale-95"
                  style={{ background: noteColor(n.color), boxShadow: "var(--shadow-card)" }}
                >
                  <p className="line-clamp-2 text-[12.5px] font-extrabold leading-snug tracking-tight text-ink">
                    {n.locked ? "Private note" : n.title || "Untitled"}
                  </p>
                  <p className="mt-2 text-[10px] font-bold text-ink-3">
                    {format(parseISO(n.updatedAt), "d MMM")}
                  </p>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Accounts mini strip */}
        {accounts.length > 0 && (
          <div className="pt-5">
            <p className="px-1 pb-2.5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
              Accounts
            </p>
            <button
              type="button"
              onClick={() => setTab("money")}
              className="flex w-full items-center gap-3 rounded-[22px] border border-line bg-surface p-3.5 text-left transition-transform active:scale-[0.985]"
              style={{ boxShadow: "var(--shadow-card)" }}
            >
              <div className="flex -space-x-2">
                {accounts.filter((a) => !a.archived).slice(0, 4).map((a) => {
                  const Icon = ACCOUNT_ICONS[a.icon] ?? ACCOUNT_ICONS.Wallet;
                  return (
                    <span
                      key={a.id}
                      className="grid h-9 w-9 place-items-center rounded-full border-2"
                      style={{
                        background: tint(a.color, 14),
                        color: PALETTE[a.color],
                        borderColor: "var(--surface)",
                      }}
                    >
                      <Icon size={14} />
                    </span>
                  );
                })}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[13px] font-bold text-ink">
                  {accounts.filter((a) => !a.archived).map((a) => a.name).join(" · ")}
                </p>
                <p className="text-[11.5px] font-medium text-ink-3">
                  Combined balance <Money paise={balanceAll} className="font-extrabold text-ink-2" />
                </p>
              </div>
            </button>
          </div>
        )}
      </div>

      <SettingsSheet open={settingsOpen} onClose={() => setSettingsOpen(false)} />
    </div>
  );
}

function parseD2(s: string) {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function StatCard({
  color,
  icon: Icon,
  label,
  big,
  sub,
  onClick,
  small,
}: {
  color: string;
  icon: LucideIcon;
  label: string;
  big: string;
  sub: string;
  onClick: () => void;
  small?: boolean;
}) {
  return (
    <motion.button
      type="button"
      whileTap={{ scale: 0.96 }}
      onClick={() => {
        buzz(6);
        onClick();
      }}
      className="rounded-[24px] border border-line bg-surface p-4 text-left"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <div className="flex items-center gap-1.5">
        <Icon size={14} style={{ color: PALETTE[color] }} />
        <span className="text-[11px] font-extrabold uppercase tracking-wider text-ink-3">
          {label}
        </span>
      </div>
      <p
        className={`tnum mt-2 font-extrabold tracking-[-0.02em] text-ink ${small ? "text-[21px]" : "text-[26px]"}`}
      >
        {big}
      </p>
      <p className="mt-0.5 truncate text-[11.5px] font-semibold text-ink-3">{sub}</p>
    </motion.button>
  );
}

/* ----------------------------- Settings sheet ------------------------------ */

function SettingsSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { mode, setMode } = useTheme();

  const options: { key: ThemeMode; label: string; icon: LucideIcon }[] = [
    { key: "system", label: "System", icon: Monitor },
    { key: "light", label: "Light", icon: Sun },
    { key: "dark", label: "Dark", icon: MoonStar },
  ];

  return (
    <Sheet open={open} onClose={onClose} maxH="72%">
      <div className="px-5 pb-8 pt-1">
        <div className="flex items-center gap-3 px-1 pb-4">
          <LumaLogo size={34} />
          <div>
            <p className="text-[15px] font-extrabold tracking-tight text-ink">ABIDLIFE</p>
            <p className="text-[11.5px] font-medium text-ink-3">Everything you need, in one place</p>
          </div>
        </div>

        <p className="px-1 pb-2 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Appearance
        </p>
        <div className="grid grid-cols-3 gap-2">
          {options.map((o) => (
            <button
              key={o.key}
              type="button"
              onClick={() => {
                buzz(7);
                setMode(o.key);
              }}
              className="flex flex-col items-center gap-1.5 rounded-2xl border py-3.5 transition-all active:scale-95"
              style={{
                borderColor: mode === o.key ? "var(--brand)" : "var(--line)",
                background: mode === o.key ? tint("violet", 10) : "var(--surface-2)",
                color: mode === o.key ? "var(--brand)" : "var(--ink-2)",
              }}
            >
              <o.icon size={18} strokeWidth={2.1} />
              <span className="text-[12px] font-extrabold">{o.label}</span>
            </button>
          ))}
        </div>

        <button
          type="button"
          onClick={() => {
            buzz(8);
            window.dispatchEvent(new Event("abidlife:replay"));
            onClose();
          }}
          className="mt-4 flex w-full items-center gap-3 rounded-2xl bg-surface-2 px-4 py-3.5 text-left text-[13.5px] font-bold text-ink-2 transition-transform active:scale-[0.98]"
        >
          <RotateCcw size={15} />
          Replay onboarding
        </button>

        <p className="pt-5 text-center text-[10.5px] font-semibold text-ink-3">
          Local-first · Your data stays with you · v1.0
        </p>
      </div>
    </Sheet>
  );
}
