"use client";

import { addDays, format, isToday, isYesterday, parseISO, startOfDay } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
  Bell,
  CalendarDays,
  CheckCircle2,
  ChevronDown,
  MoonStar,
  Plus,
  Repeat,
  Sun,
  Sunrise,
  Sunset,
  Trash2,
  X,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import {
  dateStr,
  greeting,
  nextOccurrenceDate,
  parseD,
  todayStr,
  useData,
  type Task,
} from "./data";
import {
  buzz,
  Chip,
  ConfirmSheet,
  EmptyState,
  Sheet,
  TASK_CATEGORIES,
  tint,
  Toggle,
  PALETTE,
} from "./ui";

/* ------------------------------ Task checkbox ------------------------------ */

function Checkbox({ done, priority }: { done: boolean; priority: Task["priority"] }) {
  const ring =
    priority === "high"
      ? "var(--expense)"
      : priority === "medium"
        ? "var(--amber)"
        : priority === "low"
          ? "var(--blue)"
          : "var(--ink-3)";
  return (
    <motion.span
      initial={false}
      animate={done ? { scale: [1, 1.25, 1] } : {}}
      transition={{ duration: 0.32 }}
      className="grid h-[26px] w-[26px] shrink-0 place-items-center rounded-full transition-colors duration-200"
      style={{
        border: `2px solid ${done ? "var(--green)" : ring}`,
        background: done ? "var(--green)" : "transparent",
      }}
    >
      <motion.svg
        width="13"
        height="13"
        viewBox="0 0 12 12"
        fill="none"
        initial={false}
        animate={{ pathLength: done ? 1 : 0, opacity: done ? 1 : 0 }}
      >
        <motion.path
          d="M2 6.2 4.8 9 10 3.4"
          stroke="white"
          strokeWidth="2.1"
          strokeLinecap="round"
          strokeLinejoin="round"
          initial={false}
          animate={{ pathLength: done ? 1 : 0 }}
          transition={{ duration: 0.28, ease: "easeOut" }}
        />
      </motion.svg>
    </motion.span>
  );
}

function priorityColor(p: Task["priority"]) {
  return p === "high" ? "expense" : p === "medium" ? "amber" : p === "low" ? "blue" : "ink-3";
}

function dueLabel(t: Task) {
  if (!t.dueDate) return null;
  const d = parseD(t.dueDate);
  let base = format(d, "d MMM");
  if (isToday(d)) base = "Today";
  else if (isYesterday(d)) base = "Yesterday";
  const time = t.dueTime
    ? format(
        new Date(2000, 0, 1, Number(t.dueTime.slice(0, 2)), Number(t.dueTime.slice(3))),
        "h:mm a",
      )
    : null;
  return { text: time ? `${base} · ${time}` : base, overdue: startOfDay(d) < startOfDay(new Date()) && !t.done };
}

/* -------------------------------- Task row -------------------------------- */

function TaskRow({ task, onEdit }: { task: Task; onEdit: (t: Task) => void }) {
  const { toggleTask, addTask } = useData();
  const due = dueLabel(task);
  const CatIcon = TASK_CATEGORIES[task.category] ?? TASK_CATEGORIES.Other;

  const handleToggle = async () => {
    buzz(task.done ? 5 : 12);
    const wasOpen = !task.done;
    const dueISO = task.dueDate;
    await toggleTask(task.id);
    // Recurring tasks: completing one spawns the next occurrence, honoring
    // multi-weekday schedules ("weekly: Sat + Sun" picks the next match).
    if (wasOpen && task.recurrence !== "none" && dueISO) {
      await addTask({
        title: task.title,
        notes: task.notes,
        priority: task.priority,
        category: task.category,
        dueDate: nextOccurrenceDate({ ...task, dueDate: dueISO }),
        dueTime: task.dueTime,
        reminder: task.reminder,
        recurrence: task.recurrence,
        repeatDays: task.repeatDays,
      });
    }
  };

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, x: -16 }}
      transition={{ type: "spring", stiffness: 380, damping: 34 }}
      className="mb-2 flex items-center gap-3 rounded-[20px] border border-line bg-surface p-3.5"
      style={{ boxShadow: "var(--shadow-card)" }}
    >
      <button
        type="button"
        aria-label={task.done ? "Mark not done" : "Mark done"}
        onClick={() => void handleToggle()}
        className="transition-transform active:scale-90"
      >
        <Checkbox done={task.done} priority={task.priority} />
      </button>
      <button
        type="button"
        onClick={() => {
          buzz(5);
          onEdit(task);
        }}
        className="min-w-0 flex-1 text-left"
      >
        <p
          className="truncate text-[14.5px] font-bold transition-colors duration-300"
          style={{
            color: task.done ? "var(--ink-3)" : "var(--ink)",
            textDecoration: task.done ? "line-through" : "none",
            textDecorationColor: "var(--green)",
          }}
        >
          {task.title}
        </p>
        <div className="mt-1 flex items-center gap-2 overflow-hidden">
          {due && (
            <span
              className="flex shrink-0 items-center gap-1 text-[11px] font-bold"
              style={{ color: due.overdue ? "var(--expense)" : "var(--ink-3)" }}
            >
              {task.reminder ? <Bell size={10.5} fill="currentColor" /> : <CalendarDays size={10.5} />}
              {due.text}
            </span>
          )}
          {task.recurrence !== "none" && (
            <Repeat size={11} className="shrink-0 text-ink-3" />
          )}
          <span
            className="flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-[10.5px] font-bold"
            style={{ background: "var(--surface-2)", color: "var(--ink-2)" }}
          >
            <CatIcon size={10} />
            {task.category}
          </span>
          {task.priority !== "none" && (
            <span
              className="h-1.5 w-1.5 shrink-0 rounded-full"
              style={{
                background:
                  task.priority === "high"
                    ? PALETTE.red
                    : task.priority === "medium"
                      ? PALETTE.amber
                      : PALETTE.blue,
              }}
              aria-label={`Priority ${task.priority}`}
            />
          )}
        </div>
      </button>
    </motion.div>
  );
}

/* --------------------------------- Screen --------------------------------- */

const GREETING_ICONS: [number, LucideIcon][] = [
  [5, Sunrise],
  [12, Sun],
  [17, Sunset],
  [21, MoonStar],
];

export function TasksScreen() {
  const { tasks, addTask, deleteTask, quick, consumeQuick } = useData();
  const [sheetTask, setSheetTask] = useState<Task | "new" | null>(null);
  const [quickTitle, setQuickTitle] = useState("");
  const [showDone, setShowDone] = useState(false);
  const [confirmDel, setConfirmDel] = useState<Task | null>(null);
  const hour = new Date().getHours();

  useEffect(() => {
    if (quick?.tab === "tasks") {
      setSheetTask("new");
      consumeQuick();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quick]);

  const GIcon = GREETING_ICONS.reduce((acc, [h, icon]) => (hour >= h ? icon : acc), MoonStar);

  const groups = useMemo(() => {
    const today = todayStr();
    const open = tasks.filter((t) => !t.done);
    const done = tasks
      .filter((t) => t.done)
      .sort((a, b) => new Date(b.completedAt ?? 0).getTime() - new Date(a.completedAt ?? 0).getTime());
    const overdue = open.filter((t) => t.dueDate && t.dueDate < today);
    const todayL = open.filter((t) => t.dueDate === today);
    const upcoming = open
      .filter((t) => t.dueDate && t.dueDate > today)
      .sort((a, b) => (a.dueDate! < b.dueDate! ? -1 : 1));
    const anytime = open.filter((t) => !t.dueDate);
    return { overdue, todayL, upcoming, anytime, done };
  }, [tasks]);

  const remainingToday = groups.overdue.length + groups.todayL.length;

  const quickAdd = async () => {
    const title = quickTitle.trim();
    if (!title) return;
    buzz(10);
    await addTask({ title, dueDate: todayStr() });
    setQuickTitle("");
  };

  // Requested order: Today first, then Overdue, Upcoming, Anytime.
  const sections: { label: string; color?: string; items: Task[] }[] = [
    { label: "Today", items: groups.todayL },
    { label: "Overdue", color: "var(--expense)", items: groups.overdue },
    { label: "Upcoming", items: groups.upcoming },
    { label: "Anytime", items: groups.anytime },
  ];

  return (
    <div className="relative flex h-full flex-col">
      {/* Header */}
      <div className="px-5 pb-2 pt-5">
        <div className="flex items-center gap-2">
          <GIcon size={17} style={{ color: "var(--amber)" }} />
          <p className="text-[13px] font-bold text-ink-2">
            {greeting(hour)} — {format(new Date(), "EEEE, d MMM")}
          </p>
        </div>
        <h1 className="mt-1 text-[26px] font-extrabold tracking-[-0.02em] text-ink">
          {remainingToday > 0 ? "Let's get things done." : "All clear today."}
        </h1>
      </div>

      {/* Quick add */}
      <div className="px-5 pb-3">
        <div className="flex items-center gap-2 rounded-2xl border border-line bg-surface px-3.5" style={{ boxShadow: "var(--shadow-card)" }}>
          <Plus size={17} className="text-ink-3" />
          <input
            value={quickTitle}
            onChange={(e) => setQuickTitle(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && void quickAdd()}
            placeholder="Quick add — e.g. Buy groceries"
            className="h-11 flex-1 bg-transparent text-[14px] font-semibold text-ink outline-none placeholder:text-ink-3"
            aria-label="Quick add task for today"
          />
          {quickTitle.trim() && (
            <button
              type="button"
              onClick={() => void quickAdd()}
              className="rounded-full px-3 py-1.5 text-[12px] font-bold text-white"
              style={{ background: "var(--blue)" }}
            >
              Add
            </button>
          )}
        </div>
      </div>

      {/* List */}
      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {tasks.length === 0 ? (
          <EmptyState
            icon={CheckCircle2}
            color="blue"
            title="You're all caught up"
            sub="Add a task and it will show up here, neatly organized by day."
            action="Add a task"
            onAction={() => setSheetTask("new")}
          />
        ) : (
          <>
            {sections.map(
              (s) =>
                s.items.length > 0 && (
                  <div key={s.label} className="pt-3">
                    <p
                      className="px-1 pb-2 text-[11.5px] font-extrabold uppercase tracking-[0.14em]"
                      style={{ color: s.color ?? "var(--ink-3)" }}
                    >
                      {s.label} · {s.items.length}
                    </p>
                    <AnimatePresence mode="popLayout">
                      {s.items.map((t) => (
                        <TaskRow key={t.id} task={t} onEdit={setSheetTask} />
                      ))}
                    </AnimatePresence>
                  </div>
                ),
            )}
            {groups.done.length > 0 && (
              <div className="pt-3">
                <button
                  type="button"
                  onClick={() => {
                    buzz(6);
                    setShowDone((x) => !x);
                  }}
                  className="flex w-full items-center gap-1.5 px-1 pb-2 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3"
                >
                  <motion.span animate={{ rotate: showDone ? 180 : 0 }}>
                    <ChevronDown size={14} />
                  </motion.span>
                  Completed · {groups.done.length}
                </button>
                <AnimatePresence>
                  {showDone &&
                    groups.done.map((t) => (
                      <TaskRow key={t.id} task={t} onEdit={setSheetTask} />
                    ))}
                </AnimatePresence>
              </div>
            )}
          </>
        )}
      </div>

      {/* FAB */}
      {tasks.length > 0 && (
        <motion.button
          type="button"
          aria-label="New task"
          whileTap={{ scale: 0.88 }}
          onClick={() => setSheetTask("new")}
          className="fab grid h-14 w-14 place-items-center rounded-[20px] text-white"
          style={{
            background: "var(--blue)",
            boxShadow: "0 14px 30px -8px color-mix(in srgb, var(--blue) 60%, transparent)",
          }}
        >
          <Plus size={24} strokeWidth={2.6} />
        </motion.button>
      )}

      {/* Composer / editor sheet */}
      <TaskSheet
        task={sheetTask}
        onClose={() => setSheetTask(null)}
        onDelete={(t) => {
          setSheetTask(null);
          setConfirmDel(t);
        }}
      />
      <ConfirmSheet
        open={!!confirmDel}
        onClose={() => setConfirmDel(null)}
        title="Delete this task?"
        sub={confirmDel ? `"${confirmDel.title}" will be removed.` : ""}
        onConfirm={() => confirmDel && void deleteTask(confirmDel.id)}
      />
    </div>
  );
}

/* ------------------------------ Task sheet -------------------------------- */

const WEEKDAY_OPS = [
  { d: 1, short: "M", full: "Monday" },
  { d: 2, short: "T", full: "Tuesday" },
  { d: 3, short: "W", full: "Wednesday" },
  { d: 4, short: "T", full: "Thursday" },
  { d: 5, short: "F", full: "Friday" },
  { d: 6, short: "S", full: "Saturday" },
  { d: 0, short: "S", full: "Sunday" },
];

function TaskSheet({
  task,
  onClose,
  onDelete,
}: {
  task: Task | "new" | null;
  onClose: () => void;
  onDelete: (t: Task) => void;
}) {
  const { addTask, updateTask } = useData();
  const editing = task !== "new" && task !== null ? task : null;

  const [title, setTitle] = useState("");
  const [notes, setNotes] = useState("");
  const [due, setDue] = useState<string | null>(null);
  const [time, setTime] = useState<string | null>(null);
  const [priority, setPriority] = useState<Task["priority"]>("none");
  const [category, setCategory] = useState("Personal");
  const [recurrence, setRecurrence] = useState("none");
  const [repeatDays, setRepeatDays] = useState<number[]>([]);
  const [reminder, setReminder] = useState(false);

  useEffect(() => {
    if (!task) return;
    if (editing) {
      setTitle(editing.title);
      setNotes(editing.notes);
      setDue(editing.dueDate);
      setTime(editing.dueTime);
      setPriority(editing.priority);
      setCategory(editing.category);
      setRecurrence(editing.recurrence);
      setRepeatDays(editing.repeatDays ?? []);
      setReminder(editing.reminder);
    } else {
      setTitle("");
      setNotes("");
      setDue(todayStr());
      setTime(null);
      setPriority("none");
      setCategory("Personal");
      setRecurrence("none");
      setRepeatDays([]);
      setReminder(false);
    }
  }, [task, editing]);

  const save = async () => {
    if (!title.trim()) return;
    buzz(10);
    const payload = {
      title: title.trim(),
      notes,
      dueDate: due,
      dueTime: time,
      priority,
      category,
      recurrence,
      repeatDays: recurrence === "weekly" ? repeatDays : [],
      reminder,
    };
    if (editing) await updateTask(editing.id, payload);
    else await addTask(payload);
    onClose();
  };

  const dueOptions: { label: string; value: string }[] = [
    { label: "Today", value: todayStr() },
    { label: "Tomorrow", value: dateStr(addDays(new Date(), 1)) },
    { label: "Next week", value: dateStr(addDays(new Date(), 7)) },
  ];

  return (
    <Sheet open={task !== null} onClose={onClose} maxH="92%">
      <div className="flex items-center justify-between px-5 pb-1">
        <p className="text-[16px] font-extrabold tracking-tight text-ink">
          {editing ? "Edit task" : "New task"}
        </p>
        {editing && (
          <button
            type="button"
            aria-label="Delete task"
            onClick={() => onDelete(editing)}
            className="grid h-9 w-9 place-items-center rounded-xl text-expense transition-colors active:bg-[color-mix(in_srgb,var(--expense)_10%,transparent)]"
          >
            <Trash2 size={17} />
          </button>
        )}
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-8 no-scrollbar">
        <input
          autoFocus={!editing}
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && void save()}
          placeholder="What needs doing?"
          className="w-full bg-transparent py-2 text-[20px] font-extrabold tracking-[-0.01em] text-ink outline-none placeholder:text-ink-3"
        />
        <input
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Add a note (optional)"
          className="w-full bg-transparent pb-1 text-[13.5px] font-medium text-ink-2 outline-none placeholder:text-ink-3"
        />

        <p className="pb-2 pt-4 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Due date
        </p>
        <div className="flex gap-2 overflow-x-auto no-scrollbar">
          {dueOptions.map((o) => (
            <Chip key={o.label} color="blue" active={due === o.value} onClick={() => setDue(o.value)}>
              {o.label}
            </Chip>
          ))}
          <Chip active={due === null} color="blue" onClick={() => setDue(null)}>
            No date
          </Chip>
          <label className="relative shrink-0">
            <input
              type="date"
              aria-label="Pick a date"
              className="absolute inset-0 opacity-0"
              value={due ?? ""}
              onChange={(e) => setDue(e.target.value || null)}
            />
            <span
              className="flex h-full items-center rounded-full px-3.5 text-[13px] font-semibold"
              style={{
                background:
                  due && !dueOptions.some((o) => o.value === due)
                    ? tint("blue", 16)
                    : "var(--surface-2)",
                color:
                  due && !dueOptions.some((o) => o.value === due)
                    ? "var(--blue)"
                    : "var(--ink-2)",
              }}
            >
              {due && !dueOptions.some((o) => o.value === due)
                ? format(parseD(due), "d MMM")
                : "Pick…"}
            </span>
          </label>
        </div>

        <div className="flex items-center justify-between pt-4">
          <div>
            <p className="text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
              Time
            </p>
            <div className="mt-2 flex items-center gap-2">
              <input
                type="time"
                aria-label="Time"
                value={time ?? ""}
                onChange={(e) => setTime(e.target.value || null)}
                className="rounded-xl border border-line bg-surface-2 px-3 py-2 text-[13px] font-bold text-ink outline-none"
              />
              {time && (
                <button type="button" aria-label="Clear time" onClick={() => setTime(null)}>
                  <X size={15} className="text-ink-3" />
                </button>
              )}
            </div>
          </div>
          <div className="flex items-center gap-2.5 pt-5">
            <Bell size={16} className="text-ink-3" />
            <span className="text-[13px] font-bold text-ink-2">Reminder</span>
            <Toggle on={reminder} onChange={() => setReminder((r) => !r)} />
          </div>
        </div>

        <p className="pb-2 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Priority
        </p>
        <div className="flex gap-2">
          {(["none", "low", "medium", "high"] as const).map((p) => (
            <Chip
              key={p}
              active={priority === p}
              color={p === "high" ? "red" : p === "medium" ? "amber" : p === "low" ? "blue" : undefined}
              onClick={() => setPriority(p)}
            >
              {p[0].toUpperCase() + p.slice(1)}
            </Chip>
          ))}
        </div>

        <p className="pb-2 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Category
        </p>
        <div className="flex flex-wrap gap-2">
          {Object.entries(TASK_CATEGORIES).map(([name, Icon]) => (
            <Chip key={name} color="violet" active={category === name} onClick={() => setCategory(name)}>
              <span className="flex items-center gap-1.5">
                <Icon size={13} />
                {name}
              </span>
            </Chip>
          ))}
        </div>

        <p className="pb-2 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
          Repeats
        </p>
        <div className="flex gap-2">
          {[
            ["none", "Doesn't repeat"],
            ["daily", "Daily"],
            ["weekly", "Weekly"],
            ["monthly", "Monthly"],
          ].map(([k, label]) => (
            <Chip key={k} color="teal" active={recurrence === k} onClick={() => setRecurrence(k)}>
              {label}
            </Chip>
          ))}
        </div>

        {/* Weekly: multi-weekday selector (Mon…Sun). */}
        {recurrence === "weekly" && (
          <div className="pt-3">
            <div className="flex justify-between gap-1.5">
              {WEEKDAY_OPS.map((w) => {
                const on = repeatDays.includes(w.d);
                return (
                  <button
                    key={w.d}
                    type="button"
                    aria-pressed={on}
                    aria-label={`Repeat on ${w.full}`}
                    onClick={() => {
                      buzz(5);
                      setRepeatDays((ds) =>
                        on ? ds.filter((x) => x !== w.d) : [...ds, w.d].sort(),
                      );
                    }}
                    className="flex h-11 w-11 items-center justify-center rounded-2xl text-[12px] font-extrabold transition-all active:scale-90"
                    style={{
                      background: on ? tint("teal", 16) : "var(--surface-2)",
                      color: on ? "var(--teal)" : "var(--ink-3)",
                      boxShadow: on
                        ? "0 0 0 1.6px color-mix(in srgb, var(--teal) 55%, transparent)"
                        : "none",
                    }}
                  >
                    {w.short}
                  </button>
                );
              })}
            </div>
            <p className="pt-1.5 text-[11px] font-medium text-ink-3">
              {repeatDays.length === 0
                ? "No days picked — repeats on the weekday of its due date."
                : `Repeats every ${repeatDays
                    .sort()
                    .map((d) => WEEKDAY_OPS.find((w) => w.d === d)!.full)
                    .join(", ")}.`}
            </p>
          </div>
        )}

        <button
          type="button"
          disabled={!title.trim()}
          onClick={() => void save()}
          className="mt-6 w-full rounded-2xl py-4 text-[15px] font-extrabold text-white transition-all active:scale-[0.98] disabled:opacity-40"
          style={{
            background: "var(--blue)",
            boxShadow: "0 12px 26px -10px color-mix(in srgb, var(--blue) 60%, transparent)",
          }}
        >
          {editing ? "Save changes" : "Add task"}
        </button>
      </div>
    </Sheet>
  );
}
