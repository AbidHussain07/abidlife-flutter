"use client";

import { addDays, format } from "date-fns";
import { motion } from "framer-motion";
import {
  Bell,
  Flame,
  MoonStar,
  Plus,
  Sparkles,
  Sun,
  Sunrise,
  Sunset,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import {
  dateStr,
  getStreaks,
  greeting,
  scheduledOn,
  todayStr,
  useData,
  type Habit,
} from "../data";
import {
  buzz,
  Chip,
  ColorRow,
  EmptyState,
  HABIT_ICONS,
  PALETTE,
  PALETTE_NAMES,
  SectionLabel,
  Sheet,
  tint,
  Toggle,
} from "../ui";
import { HabitDetail } from "./habit-detail";

const GREETING_ICONS: [number, LucideIcon][] = [
  [5, Sunrise],
  [12, Sun],
  [17, Sunset],
  [21, MoonStar],
];

/* -------------------------------- Habit card ------------------------------- */

function HabitCard({
  habit,
  onOpen,
}: {
  habit: Habit;
  onOpen: (h: Habit) => void;
}) {
  const { logs, toggleHabitToday } = useData();
  const dates = useMemo(
    () => new Set(logs.filter((l) => l.habitId === habit.id).map((l) => l.date)),
    [logs, habit.id],
  );
  const tStr = todayStr();
  const scheduledToday = scheduledOn(habit, new Date());
  const doneToday = dates.has(tStr);
  const { current } = getStreaks(habit, dates);
  const accent = PALETTE[habit.color] ?? "var(--green)";
  const Icon = HABIT_ICONS[habit.icon] ?? HABIT_ICONS.Sparkles;

  const week = Array.from({ length: 7 }, (_, i) => {
    const d = addDays(new Date(), i - 6);
    const ds = dateStr(d);
    return {
      ds,
      sched: scheduledOn(habit, d),
      done: dates.has(ds),
      today: ds === tStr,
      future: ds > tStr,
    };
  });

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ type: "spring", stiffness: 340, damping: 32 }}
      className="mb-3 rounded-[24px] border border-line bg-surface p-4"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <div className="flex items-center gap-3">
        <button
          type="button"
          onClick={() => {
            buzz(5);
            onOpen(habit);
          }}
          className="flex min-w-0 flex-1 items-center gap-3 text-left"
        >
          <div
            className="grid h-12 w-12 shrink-0 place-items-center rounded-[18px]"
            style={{ background: tint(habit.color, 14), color: accent }}
          >
            <Icon size={22} strokeWidth={2.1} />
          </div>
          <div className="min-w-0">
            <p className="truncate text-[15.5px] font-extrabold tracking-tight text-ink">
              {habit.name}
            </p>
            <div className="mt-0.5 flex items-center gap-2">
              <span className="flex items-center gap-1 text-[12px] font-bold" style={{ color: current > 0 ? "var(--orange)" : "var(--ink-3)" }}>
                <Flame size={12.5} fill={current > 0 ? "currentColor" : "none"} />
                {current} day{current === 1 ? "" : "s"}
              </span>
              <span className="text-[11.5px] font-medium text-ink-3">
                {habit.frequency.type === "daily"
                  ? "Daily"
                  : `${habit.frequency.days.length}x a week`}
              </span>
              {habit.reminder && <Bell size={11} className="text-ink-3" />}
            </div>
          </div>
        </button>

        {/* Check button */}
        {scheduledToday ? (
          <motion.button
            type="button"
            aria-label={doneToday ? `Uncheck ${habit.name}` : `Check ${habit.name}`}
            whileTap={{ scale: 0.85 }}
            onClick={() => {
              buzz(doneToday ? 6 : 14);
              void toggleHabitToday(habit.id);
            }}
            className="grid h-11 w-11 shrink-0 place-items-center rounded-full transition-all duration-200"
            style={{
              background: doneToday ? accent : "transparent",
              border: `2px solid ${doneToday ? accent : "var(--surface-3)"}`,
            }}
          >
            <motion.svg width="17" height="17" viewBox="0 0 12 12" fill="none">
              <motion.path
                d="M2 6.2 4.8 9 10 3.4"
                stroke="white"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
                initial={false}
                animate={{ pathLength: doneToday ? 1 : 0 }}
                transition={{ duration: 0.28, ease: "easeOut" }}
              />
            </motion.svg>
          </motion.button>
        ) : (
          <span className="rounded-full bg-surface-2 px-3 py-1.5 text-[11px] font-bold text-ink-3">
            Rest day
          </span>
        )}
      </div>

      {/* Week strip */}
      <div className="mt-3.5 flex justify-between">
        {week.map((w) => (
          <div key={w.ds} className="flex flex-col items-center gap-1.5">
            <span
              className="text-[9.5px] font-extrabold uppercase"
              style={{ color: w.today ? accent : "var(--ink-3)" }}
            >
              {w.ds === tStr ? "Now" : format(new Date(w.ds + "T12:00:00"), "EEEEE")}
            </span>
            <span
              className="h-2.5 w-2.5 rounded-full transition-all duration-300"
              style={{
                background: w.done
                  ? accent
                  : w.sched && !w.future
                    ? tint(habit.color, 22)
                    : "var(--surface-3)",
                transform: w.today ? "scale(1.35)" : "none",
                boxShadow: w.today ? `0 0 0 3px ${tint(habit.color, 18)}` : "none",
              }}
            />
          </div>
        ))}
      </div>
    </motion.div>
  );
}

/* --------------------------------- Screen --------------------------------- */

export function HabitsScreen() {
  const { habits, logs, quick, consumeQuick } = useData();
  const [createOpen, setCreateOpen] = useState(false);
  const [detailId, setDetailId] = useState<string | null>(null);
  const hour = new Date().getHours();

  useEffect(() => {
    if (quick?.tab === "habits") {
      setCreateOpen(true);
      consumeQuick();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quick]);

  const tStr = todayStr();
  const active = habits.filter((h) => !h.archived);
  const scheduledToday = active.filter((h) => scheduledOn(h, new Date()));
  const doneToday = scheduledToday.filter((h) =>
    logs.some((l) => l.habitId === h.id && l.date === tStr),
  ).length;
  const pct = scheduledToday.length
    ? doneToday / scheduledToday.length
    : 0;
  const bestCurrent = active.reduce((m, h) => {
    const dates = new Set(
      logs.filter((l) => l.habitId === h.id).map((l) => l.date),
    );
    return Math.max(m, getStreaks(h, dates).current);
  }, 0);

  const GIcon = GREETING_ICONS.reduce((a, [h, i]) => (hour >= h ? i : a), MoonStar);
  const R = 30;
  const CIRC = 2 * Math.PI * R;

  return (
    <div className="relative flex h-full flex-col">
      {/* Header */}
      <div className="px-5 pb-3 pt-5">
        <div className="flex items-center gap-2">
          <GIcon size={17} style={{ color: "var(--amber)" }} />
          <p className="text-[13px] font-bold text-ink-2">
            {greeting(hour)} — {format(new Date(), "EEEE, d MMM")}
          </p>
        </div>
        <h1 className="mt-1 text-[26px] font-extrabold tracking-[-0.02em] text-ink">
          Today's habits
        </h1>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {active.length > 0 && (
          <>
            {/* Today summary */}
            <div
              className="mb-4 flex items-center gap-4 rounded-[24px] border border-line bg-surface p-4"
              style={{ boxShadow: "var(--shadow-card)" }}
            >
              <div className="relative grid h-[76px] w-[76px] place-items-center">
                <svg width="76" height="76" className="-rotate-90">
                  <circle cx="38" cy="38" r={R} fill="none" stroke="var(--surface-3)" strokeWidth="7" />
                  <motion.circle
                    cx="38"
                    cy="38"
                    r={R}
                    fill="none"
                    stroke="var(--green)"
                    strokeWidth="7"
                    strokeLinecap="round"
                    strokeDasharray={CIRC}
                    initial={{ strokeDashoffset: CIRC }}
                    animate={{ strokeDashoffset: CIRC * (1 - pct) }}
                    transition={{ type: "spring", stiffness: 90, damping: 22 }}
                  />
                </svg>
                <div className="absolute text-center">
                  <p className="tnum text-[16px] font-extrabold text-ink">
                    {doneToday}/{scheduledToday.length}
                  </p>
                  <p className="text-[8.5px] font-extrabold uppercase tracking-wider text-ink-3">
                    done
                  </p>
                </div>
              </div>
              <div className="flex-1">
                <p className="text-[14.5px] font-extrabold tracking-tight text-ink">
                  {pct === 1
                    ? "Perfect day — all done"
                    : doneToday === 0
                      ? "Fresh start — tap to check in"
                      : "Nice momentum, keep going"}
                </p>
                <p className="mt-1 flex items-center gap-1 text-[12px] font-bold" style={{ color: bestCurrent > 0 ? "var(--orange)" : "var(--ink-3)" }}>
                  <Flame size={13} fill={bestCurrent > 0 ? "currentColor" : "none"} />
                  Longest active streak: {bestCurrent} day{bestCurrent === 1 ? "" : "s"}
                </p>
              </div>
            </div>

            <SectionLabel>{active.length} habit{active.length === 1 ? "" : "s"}</SectionLabel>
            {active.map((h) => (
              <HabitCard key={h.id} habit={h} onOpen={(x) => setDetailId(x.id)} />
            ))}
          </>
        )}
        {active.length === 0 && (
          <EmptyState
            icon={Flame}
            color="green"
            title="Start your first habit"
            sub="Small steps, every day. Streaks keep you honest — and motivated."
            action="Create habit"
            onAction={() => setCreateOpen(true)}
          />
        )}
      </div>

      {/* FAB */}
      {active.length > 0 && (
        <motion.button
          type="button"
          aria-label="New habit"
          whileTap={{ scale: 0.88 }}
          onClick={() => setCreateOpen(true)}
          className="fab grid h-14 w-14 place-items-center rounded-[20px] text-white"
          style={{
            background: "var(--green)",
            boxShadow: "0 14px 30px -8px color-mix(in srgb, var(--green) 55%, transparent)",
          }}
        >
          <Plus size={24} strokeWidth={2.6} />
        </motion.button>
      )}

      <CreateHabitSheet open={createOpen} onClose={() => setCreateOpen(false)} />
      <HabitDetail habitId={detailId} onClose={() => setDetailId(null)} />
    </div>
  );
}

/* ------------------------------ Create sheet ------------------------------- */

const SUGGESTIONS = ["Drink Water", "Read", "Exercise", "Meditation", "Study", "Walk", "Sleep Early", "No Sugar"];
const WEEKDAYS = ["S", "M", "T", "W", "T", "F", "S"];

function CreateHabitSheet({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { addHabit, toast } = useData();
  const [name, setName] = useState("");
  const [icon, setIcon] = useState("Sparkles");
  const [color, setColor] = useState("green");
  const [mode, setMode] = useState<"daily" | "days">("daily");
  const [days, setDays] = useState<number[]>([1, 3, 5]);
  const [reminder, setReminder] = useState(false);

  useEffect(() => {
    if (open) {
      setName("");
      setIcon("Sparkles");
      setColor("green");
      setMode("daily");
      setDays([1, 3, 5]);
      setReminder(false);
    }
  }, [open]);

  const valid = name.trim().length > 0 && (mode === "daily" || days.length > 0);

  const save = async () => {
    if (!valid) return;
    buzz(10);
    await addHabit({
      name: name.trim(),
      icon,
      color,
      frequency: mode === "daily" ? { type: "daily" } : { type: "days", days: [...days].sort() },
      reminder,
    });
    toast("Habit created — day one starts now");
    onClose();
  };

  return (
    <Sheet open={open} onClose={onClose} maxH="94%">
      <p className="px-5 pb-1 text-[16px] font-extrabold tracking-tight text-ink">
        New habit
      </p>
      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-8 no-scrollbar">
        <input
          autoFocus
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="e.g. Drink Water"
          className="w-full bg-transparent py-2 text-[20px] font-extrabold tracking-[-0.01em] text-ink outline-none placeholder:text-ink-3"
        />
        <div className="flex flex-wrap gap-1.5 pt-1">
          {SUGGESTIONS.map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => {
                buzz(5);
                setName(s);
              }}
              className="rounded-full bg-surface-2 px-2.5 py-1 text-[11.5px] font-bold text-ink-2 transition-all active:scale-95"
            >
              {s}
            </button>
          ))}
        </div>

        <p className="pb-2.5 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Icon
        </p>
        <div className="grid grid-cols-5 gap-2">
          {Object.entries(HABIT_ICONS).map(([k, Icon]) => (
            <button
              key={k}
              type="button"
              aria-label={k}
              onClick={() => {
                buzz(5);
                setIcon(k);
              }}
              className="grid aspect-square place-items-center rounded-2xl transition-all active:scale-90"
              style={{
                background: icon === k ? tint(color, 16) : "var(--surface-2)",
                color: icon === k ? (PALETTE[color] ?? "var(--green)") : "var(--ink-3)",
              }}
            >
              <Icon size={19} strokeWidth={2.1} />
            </button>
          ))}
        </div>

        <p className="pb-2.5 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Color
        </p>
        <ColorRow value={color} onChange={setColor} colors={PALETTE_NAMES.filter((c) => c !== "red")} />

        <p className="pb-2.5 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Frequency
        </p>
        <div className="flex gap-2">
          <Chip color="green" active={mode === "daily"} onClick={() => setMode("daily")}>
            Every day
          </Chip>
          <Chip color="green" active={mode === "days"} onClick={() => setMode("days")}>
            Specific days
          </Chip>
        </div>
        {mode === "days" && (
          <div className="mt-3 flex justify-between gap-1.5">
            {WEEKDAYS.map((wd, i) => (
              <button
                key={i}
                type="button"
                onClick={() => {
                  buzz(5);
                  setDays((d) =>
                    d.includes(i) ? d.filter((x) => x !== i) : [...d, i],
                  );
                }}
                className="flex h-11 w-11 items-center justify-center rounded-2xl text-[13px] font-extrabold transition-all active:scale-90"
                style={{
                  background: days.includes(i) ? tint(color, 16) : "var(--surface-2)",
                  color: days.includes(i) ? (PALETTE[color] ?? "var(--green)") : "var(--ink-3)",
                }}
              >
                {wd}
              </button>
            ))}
          </div>
        )}

        <div className="mt-5 flex items-center justify-between rounded-2xl bg-surface-2 px-4 py-3.5">
          <span className="flex items-center gap-2 text-[13.5px] font-bold text-ink-2">
            <Bell size={15} />
            Daily reminder
          </span>
          <Toggle on={reminder} onChange={() => setReminder((r) => !r)} />
        </div>

        <button
          type="button"
          disabled={!valid}
          onClick={() => void save()}
          className="mt-5 w-full rounded-2xl py-4 text-[15px] font-extrabold text-white transition-all active:scale-[0.98] disabled:opacity-40"
          style={{
            background: "var(--green)",
            boxShadow: "0 12px 26px -10px color-mix(in srgb, var(--green) 55%, transparent)",
          }}
        >
          Start habit
        </button>
      </div>
    </Sheet>
  );
}
