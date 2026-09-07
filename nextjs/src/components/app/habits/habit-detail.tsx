"use client";

import {
  addMonths,
  eachDayOfInterval,
  endOfMonth,
  endOfWeek,
  format,
  isSameMonth,
  startOfMonth,
  startOfWeek,
} from "date-fns";
import {
  CalendarDays,
  ChevronLeft,
  ChevronRight,
  Flame,
  Info,
  Trash2,
  Trophy,
} from "lucide-react";
import { useMemo, useState } from "react";
import {
  completionRate,
  dateStr,
  getStreaks,
  parseD,
  scheduledOn,
  todayStr,
  useData,
  type Habit,
} from "../data";
import { buzz, ConfirmSheet, HABIT_ICONS, Overlay, PALETTE, tint } from "../ui";

const WD = ["M", "T", "W", "T", "F", "S", "S"];

export function HabitDetail({
  habitId,
  onClose,
}: {
  habitId: string | null;
  onClose: () => void;
}) {
  const { habits, logs, toggleHabitToday, deleteHabit } = useData();
  const habit = habits.find((h) => h.id === habitId);
  const [cursor, setCursor] = useState(() => new Date());
  const [status, setStatus] = useState<string | null>(null);
  const [confirmDel, setConfirmDel] = useState(false);

  const dates = useMemo(
    () => new Set(logs.filter((l) => l.habitId === habitId).map((l) => l.date)),
    [logs, habitId],
  );

  if (!habit) return <Overlay show={false}>{null}</Overlay>;

  const accent = PALETTE[habit.color] ?? "var(--green)";
  const { current, best } = getStreaks(habit, dates);
  const rate = completionRate(habit, dates);
  const tStr = todayStr();
  const Icon = HABIT_ICONS[habit.icon] ?? HABIT_ICONS.Sparkles;

  const cells = eachDayOfInterval({
    start: startOfWeek(startOfMonth(cursor), { weekStartsOn: 1 }),
    end: endOfWeek(endOfMonth(cursor), { weekStartsOn: 1 }),
  });

  const describe = (d: Date) => {
    const ds = dateStr(d);
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    if (!scheduledOn(habit, d)) return "Not scheduled — rest day";
    if (dates.has(ds)) return "Completed. Nice work.";
    if (ds === tStr) return "Scheduled today — tap again to check off";
    if (d.getTime() > today.getTime()) return "Coming up";
    return "Missed";
  };

  return (
    <Overlay show={!!habitId}>
      <div className="flex h-full flex-col">
        {/* Header */}
        <div className="flex items-center gap-2 px-4 pb-2 pt-4">
          <button
            type="button"
            aria-label="Back"
            onClick={onClose}
            className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 transition-colors active:bg-[var(--surface-2)]"
          >
            <ChevronLeft size={22} />
          </button>
          <div className="flex flex-1 items-center gap-3">
            <div
              className="grid h-11 w-11 place-items-center rounded-2xl"
              style={{ background: tint(habit.color, 14), color: accent }}
            >
              <Icon size={20} />
            </div>
            <div>
              <p className="text-[16px] font-extrabold tracking-tight text-ink">
                {habit.name}
              </p>
              <p className="text-[11.5px] font-semibold text-ink-3">
                {habit.frequency.type === "daily"
                  ? "Every day"
                  : `${habit.frequency.days.length} days a week`}
              </p>
            </div>
          </div>
          <button
            type="button"
            aria-label="Delete habit"
            onClick={() => setConfirmDel(true)}
            className="grid h-10 w-10 place-items-center rounded-2xl text-expense transition-colors active:bg-[color-mix(in_srgb,var(--expense)_10%,transparent)]"
          >
            <Trash2 size={17} />
          </button>
        </div>

        <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-10 no-scrollbar">
          {/* Stats */}
          <div className="grid grid-cols-3 gap-2.5 pt-2">
            <Stat
              label="Current streak"
              value={`${current}`}
              suffix={current === 1 ? "day" : "days"}
              icon={<Flame size={15} fill="currentColor" />}
              color={accent}
            />
            <Stat
              label="Best streak"
              value={`${best}`}
              suffix={best === 1 ? "day" : "days"}
              icon={<Trophy size={14} />}
              color="var(--amber)"
            />
            <Stat
              label="30-day rate"
              value={`${rate}`}
              suffix="%"
              icon={<CalendarDays size={14} />}
              color="var(--blue)"
            />
          </div>

          {/* Calendar */}
          <div
            className="mt-4 rounded-[24px] border border-line bg-surface p-4"
            style={{ boxShadow: "var(--shadow-card)" }}
          >
            <div className="flex items-center justify-between px-1 pb-3">
              <button
                type="button"
                aria-label="Previous month"
                onClick={() => setCursor((c) => addMonths(c, -1))}
                className="grid h-8 w-8 place-items-center rounded-xl text-ink-2 active:bg-[var(--surface-2)]"
              >
                <ChevronLeft size={17} />
              </button>
              <p className="text-[14px] font-extrabold tracking-tight text-ink">
                {format(cursor, "MMMM yyyy")}
              </p>
              <button
                type="button"
                aria-label="Next month"
                onClick={() => setCursor((c) => addMonths(c, 1))}
                className="grid h-8 w-8 place-items-center rounded-xl text-ink-2 active:bg-[var(--surface-2)]"
              >
                <ChevronRight size={17} />
              </button>
            </div>
            <div className="grid grid-cols-7 gap-1">
              {WD.map((d, i) => (
                <p
                  key={i}
                  className="pb-1 text-center text-[10.5px] font-extrabold uppercase tracking-wider text-ink-3"
                >
                  {d}
                </p>
              ))}
              {cells.map((d) => {
                const ds = dateStr(d);
                const inMonth = isSameMonth(d, cursor);
                const sched = scheduledOn(habit, d);
                const done = dates.has(ds);
                const today = ds === tStr;
                const pastDate = parseD(ds) < parseD(tStr);
                const missed = sched && pastDate && !done && inMonth;
                return (
                  <button
                    key={ds}
                    type="button"
                    onClick={() => {
                      if (today && sched) {
                        buzz(10);
                        void toggleHabitToday(habit.id);
                        setStatus(done ? "Unchecked" : "Checked — streak going");
                      } else if (inMonth) {
                        buzz(5);
                        setStatus(`${format(d, "d MMM")} — ${describe(d)}`);
                      }
                    }}
                    className="relative grid aspect-square place-items-center rounded-xl text-[12.5px] font-bold transition-transform active:scale-90"
                    style={{
                      background: done
                        ? accent
                        : missed
                          ? "color-mix(in srgb, var(--expense) 12%, transparent)"
                          : "transparent",
                      color: done
                        ? "white"
                        : missed
                          ? "var(--expense)"
                          : !inMonth
                            ? "color-mix(in srgb, var(--ink-3) 40%, transparent)"
                            : sched
                              ? "var(--ink)"
                              : "var(--ink-3)",
                      border: today
                        ? `2px solid ${accent}`
                        : "2px solid transparent",
                      opacity: !inMonth ? 0.4 : 1,
                    }}
                    aria-label={format(d, "PPPP")}
                  >
                    {d.getDate()}
                  </button>
                );
              })}
            </div>
            <div className="flex items-center gap-4 px-1 pt-3">
              <Legend swatch={accent} label="Done" />
              <Legend swatch="color-mix(in srgb, var(--expense) 50%, transparent)" label="Missed" />
              <Legend swatch="var(--surface-3)" label="Rest" />
            </div>
          </div>

          <div className="mt-3 flex items-start gap-2.5 rounded-2xl border border-line bg-surface p-3.5">
            <Info size={15} className="mt-0.5 shrink-0 text-ink-3" />
            <p className="text-[12px] leading-relaxed text-ink-3">
              {status ??
                "Only today can be checked off — your streak stays honest. Tap a day to see its status."}
            </p>
          </div>
        </div>
      </div>

      <ConfirmSheet
        open={confirmDel}
        onClose={() => setConfirmDel(false)}
        title="Remove this habit?"
        sub={`"${habit.name}" and its ${current}-day streak history will be deleted.`}
        confirm="Remove"
        onConfirm={() => {
          void deleteHabit(habit.id);
          onClose();
        }}
      />
    </Overlay>
  );
}

function Stat({
  label,
  value,
  suffix,
  icon,
  color,
}: {
  label: string;
  value: string;
  suffix: string;
  icon: React.ReactNode;
  color: string;
}) {
  return (
    <div
      className="rounded-[20px] border border-line bg-surface p-3.5"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <div className="flex items-center gap-1" style={{ color }}>
        {icon}
        <span className="text-[10.5px] font-extrabold uppercase tracking-wide text-ink-3">
          {label.split(" ")[0]}
        </span>
      </div>
      <p className="tnum mt-1.5 text-[22px] font-extrabold tracking-tight text-ink">
        {value}
        <span className="ml-1 text-[11px] font-bold text-ink-3">{suffix}</span>
      </p>
      <p className="text-[10.5px] font-semibold text-ink-3">{label}</p>
    </div>
  );
}

function Legend({ swatch, label }: { swatch: string; label: string }) {
  return (
    <span className="flex items-center gap-1.5 text-[10.5px] font-bold text-ink-3">
      <span
        className="h-2.5 w-2.5 rounded-full"
        style={{ background: swatch }}
      />
      {label}
    </span>
  );
}
