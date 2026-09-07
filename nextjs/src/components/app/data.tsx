"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { ensureNotificationPermission, fireTaskReminder } from "@/lib/notifications";

/* ---------------------------------- Types --------------------------------- */

export type Tab = "insights" | "notes" | "tasks" | "habits" | "money";

export interface Note {
  id: string;
  title: string;
  content: string;
  color: string;
  tags: string[];
  pinned: boolean;
  archived: boolean;
  locked: boolean;
  checklist: boolean;
  createdAt: string;
  updatedAt: string;
}
export interface Task {
  id: string;
  title: string;
  notes: string;
  done: boolean;
  priority: "none" | "low" | "medium" | "high";
  category: string;
  dueDate: string | null;
  dueTime: string | null;
  reminder: boolean;
  recurrence: string;
  /** Weekdays for weekly recurrence (0 = Sunday … 6 = Saturday). */
  repeatDays: number[];
  completedAt: string | null;
  createdAt: string;
}
export type Frequency =
  | { type: "daily" }
  | { type: "days"; days: number[] };
export interface Habit {
  id: string;
  name: string;
  icon: string;
  color: string;
  frequency: Frequency;
  reminder: boolean;
  archived: boolean;
  createdAt: string;
}
export interface HabitLog {
  id: string;
  habitId: string;
  date: string;
}
export interface Account {
  id: string;
  name: string;
  icon: string;
  color: string;
  archived: boolean;
  createdAt: string;
}
export interface Txn {
  id: string;
  accountId: string;
  type: "income" | "expense";
  amount: number; // paise
  note: string;
  category: string;
  occurredAt: string;
  createdAt: string;
}

/* --------------------------------- Helpers -------------------------------- */

export const dateStr = (d: Date) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(
    d.getDate(),
  ).padStart(2, "0")}`;
export const todayStr = () => dateStr(new Date());
export const parseD = (s: string) => {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y, m - 1, d);
};

export function fmtINR(paise: number, sign = false) {
  const neg = paise < 0;
  const abs = Math.abs(paise);
  const hasPaise = abs % 100 !== 0;
  const str = new Intl.NumberFormat("en-IN", {
    minimumFractionDigits: hasPaise ? 2 : 0,
    maximumFractionDigits: hasPaise ? 2 : 0,
  }).format(abs / 100);
  return `${neg ? "−" : sign ? "+" : ""}₹${str}`;
}

export function greeting(hour: number) {
  if (hour >= 5 && hour < 12) return "Good Morning";
  if (hour >= 12 && hour < 17) return "Good Afternoon";
  if (hour >= 17 && hour < 21) return "Good Evening";
  return "Good Night";
}

export function scheduledOn(h: Habit, d: Date) {
  return h.frequency.type === "days"
    ? h.frequency.days.includes(d.getDay())
    : true;
}

/** Next recurrence date after a task's current due date. */
export function nextOccurrenceDate(task: {
  dueDate: string;
  recurrence: string;
  repeatDays: number[];
}): string {
  const due = parseD(task.dueDate);
  if (task.recurrence === "daily") {
    due.setDate(due.getDate() + 1);
    return dateStr(due);
  }
  if (task.recurrence === "monthly") {
    due.setMonth(due.getMonth() + 1);
    return dateStr(due);
  }
  if (task.recurrence === "weekly") {
    const days =
      task.repeatDays.length > 0 ? [...task.repeatDays].sort() : [due.getDay()];
    for (let i = 1; i <= 7; i++) {
      const cand = new Date(due);
      cand.setDate(cand.getDate() + i);
      if (days.includes(cand.getDay())) return dateStr(cand);
    }
  }
  return task.dueDate;
}

export function getStreaks(habit: Habit, dates: Set<string>, now = new Date()) {
  // current streak
  let cur = 0;
  let d = new Date(now);
  let guard = 0;
  if (scheduledOn(habit, d) && !dates.has(dateStr(d))) d.setDate(d.getDate() - 1);
  while (guard++ < 2000) {
    if (!scheduledOn(habit, d)) {
      d.setDate(d.getDate() - 1);
      continue;
    }
    if (!dates.has(dateStr(d))) break;
    cur++;
    d.setDate(d.getDate() - 1);
  }
  // best streak — walk from creation (or first log) to now
  const start = new Date(habit.createdAt);
  start.setHours(0, 0, 0, 0);
  let run = 0;
  let best = 0;
  const cursor = new Date(start);
  const end = new Date(now);
  guard = 0;
  while (cursor <= end && guard++ < 2000) {
    if (scheduledOn(habit, cursor)) {
      if (dates.has(dateStr(cursor))) {
        run++;
        best = Math.max(best, run);
      } else {
        run = 0;
      }
    }
    cursor.setDate(cursor.getDate() + 1);
  }
  return { current: cur, best: Math.max(best, cur) };
}

export function completionRate(habit: Habit, dates: Set<string>, days = 30) {
  const end = new Date();
  let scheduled = 0;
  let doneCount = 0;
  for (let i = 0; i < days; i++) {
    const d = new Date(end);
    d.setDate(d.getDate() - i);
    if (d < new Date(habit.createdAt)) continue;
    if (!scheduledOn(habit, d)) continue;
    scheduled++;
    if (dates.has(dateStr(d))) doneCount++;
  }
  return scheduled === 0 ? 0 : Math.round((doneCount / scheduled) * 100);
}

/* ------------------------------ API + context ------------------------------ */

async function call<T>(url: string, method: string, body?: unknown): Promise<T> {
  const res = await fetch(url, {
    method,
    headers: body ? { "Content-Type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`${method} ${url} failed`);
  return res.json();
}

interface Toast {
  id: number;
  msg: string;
}

interface DataValue {
  loading: boolean;
  tab: Tab;
  setTab: (t: Tab) => void;
  notes: Note[];
  tasks: Task[];
  habits: Habit[];
  logs: HabitLog[];
  accounts: Account[];
  txns: Txn[];
  toasts: Toast[];
  toast: (msg: string) => void;
  // notes
  addNote: (partial?: Partial<Note>) => Promise<Note>;
  updateNote: (id: string, patch: Record<string, unknown>) => Promise<void>;
  deleteNote: (id: string) => Promise<void>;
  verifyUnlock: (id: string, pin: string) => Promise<boolean>;
  // tasks
  addTask: (input: Record<string, unknown>) => Promise<void>;
  toggleTask: (id: string) => Promise<void>;
  updateTask: (id: string, patch: Record<string, unknown>) => Promise<void>;
  deleteTask: (id: string) => Promise<void>;
  // habits
  addHabit: (input: Record<string, unknown>) => Promise<void>;
  deleteHabit: (id: string) => Promise<void>;
  toggleHabitToday: (id: string) => Promise<void>;
  // money
  addAccount: (input: Record<string, unknown>) => Promise<void>;
  updateAccount: (id: string, patch: Record<string, unknown>) => Promise<void>;
  deleteAccount: (id: string) => Promise<void>;
  addTxn: (input: Record<string, unknown>) => Promise<void>;
  updateTxn: (id: string, patch: Record<string, unknown>) => Promise<void>;
  deleteTxn: (id: string) => Promise<void>;
  // cross-module quick actions
  quick: { tab: Tab; action: string } | null;
  requestQuick: (tab: Tab, action: string) => void;
  consumeQuick: () => void;
}

const DataCtx = createContext<DataValue | null>(null);

export function DataProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<Tab>("insights");
  const [notes, setNotes] = useState<Note[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [habits, setHabits] = useState<Habit[]>([]);
  const [logs, setLogs] = useState<HabitLog[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [txns, setTxns] = useState<Txn[]>([]);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [quick, setQuick] = useState<{ tab: Tab; action: string } | null>(null);
  const toastId = useRef(0);
  const reminderTimers = useRef<Map<string, number>>(new Map());

  /* Real local reminders: re-arm timers whenever the task list changes so
     edits/deletes can't leave stale or duplicate notifications. */
  useEffect(() => {
    const timers = reminderTimers.current;
    timers.forEach((id) => window.clearTimeout(id));
    timers.clear();
    if (typeof window === "undefined" || !("Notification" in window)) return;
    if (Notification.permission !== "granted") return;

    const now = Date.now();
    const today = todayStr();
    tasks.forEach((t) => {
      if (t.done || !t.reminder || t.dueDate !== today || !t.dueTime) return;
      const dt = parseD(today);
      dt.setHours(Number(t.dueTime.slice(0, 2)), Number(t.dueTime.slice(3)), 0, 0);
      const delay = dt.getTime() - now;
      if (delay <= 0 || delay > 24 * 60 * 60 * 1000) return;
      timers.set(
        t.id,
        window.setTimeout(() => fireTaskReminder(t.title), delay),
      );
    });
    return () => {
      timers.forEach((id) => window.clearTimeout(id));
      timers.clear();
    };
  }, [tasks]);

  const toast = useCallback((msg: string) => {
    const id = ++toastId.current;
    setToasts((t) => [...t.slice(-2), { id, msg }]);
    window.setTimeout(
      () => setToasts((t) => t.filter((x) => x.id !== id)),
      2600,
    );
  }, []);

  useEffect(() => {
    let alive = true;
    fetch("/api/bootstrap")
      .then((r) => r.json())
      .then((d) => {
        if (!alive) return;
        setNotes(d.notes);
        setTasks(d.tasks);
        setHabits(d.habits);
        setLogs(d.logs);
        setAccounts(d.accounts);
        setTxns(d.transactions);
        setLoading(false);
      })
      .catch(() => alive && setLoading(false));
    return () => {
      alive = false;
    };
  }, []);

  /* ------------------------------- Notes ------------------------------- */

  const addNote = useCallback(
    async (partial: Partial<Note> = {}) => {
      const temp: Note = {
        id: `temp-${Date.now()}`,
        title: "",
        content: "",
        color: partial.color ?? "default",
        tags: [],
        pinned: false,
        archived: false,
        locked: false,
        checklist: !!partial.checklist,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      setNotes((n) => [temp, ...n]);
      try {
        const row = await call<Note>("/api/notes", "POST", {
          checklist: temp.checklist,
          color: temp.color,
        });
        setNotes((n) => n.map((x) => (x.id === temp.id ? row : x)));
        return row;
      } catch {
        setNotes((n) => n.filter((x) => x.id !== temp.id));
        toast("Your note couldn't be created. Try again.");
        throw new Error("create failed");
      }
    },
    [toast],
  );

  const updateNote = useCallback(
    async (id: string, patch: Record<string, unknown>) => {
      let prev: Note | undefined;
      setNotes((all) => {
        prev = all.find((x) => x.id === id);
        return all.map((x) =>
          x.id === id
            ? { ...x, ...(patch as Partial<Note>), updatedAt: new Date().toISOString() }
            : x,
        );
      });
      try {
        const row = await call<Note>(`/api/notes/${id}`, "PATCH", patch);
        setNotes((all) => all.map((x) => (x.id === id ? row : x)));
      } catch {
        if (prev) setNotes((all) => all.map((x) => (x.id === id ? prev! : x)));
        toast("Your note couldn't be saved. Try again.");
      }
    },
    [toast],
  );

  const deleteNote = useCallback(
    async (id: string) => {
      let prev: Note[] = [];
      setNotes((all) => {
        prev = all;
        return all.filter((x) => x.id !== id);
      });
      try {
        await call(`/api/notes/${id}`, "DELETE");
        toast("Note deleted");
      } catch {
        setNotes(prev);
        toast("Couldn't delete this note. Try again.");
      }
    },
    [toast],
  );

  const verifyUnlock = useCallback(async (id: string, pin: string) => {
    try {
      const r = await call<{ ok: boolean; note?: Note }>(
        `/api/notes/${id}/verify`,
        "POST",
        { pin },
      );
      if (r.ok && r.note) {
        setNotes((all) => all.map((x) => (x.id === id ? r.note! : x)));
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }, []);

  /* ------------------------------- Tasks ------------------------------- */

  const addTask = useCallback(
    async (input: Record<string, unknown>) => {
      if (input.reminder) void ensureNotificationPermission();
      try {
        const row = await call<Task>("/api/tasks", "POST", input);
        setTasks((t) => [row, ...t]);
      } catch {
        toast("Couldn't add this task. Try again.");
      }
    },
    [toast],
  );

  const toggleTask = useCallback(
    async (id: string) => {
      let prev: Task | undefined;
      setTasks((all) => {
        prev = all.find((x) => x.id === id);
        return all.map((x) =>
          x.id === id
            ? {
                ...x,
                done: !x.done,
                completedAt: !x.done ? new Date().toISOString() : null,
              }
            : x,
        );
      });
      try {
        if (prev) await call(`/api/tasks/${id}`, "PATCH", { done: !prev.done });
      } catch {
        if (prev) setTasks((all) => all.map((x) => (x.id === id ? prev! : x)));
        toast("Couldn't update this task. Try again.");
      }
    },
    [toast],
  );

  const updateTask = useCallback(
    async (id: string, patch: Record<string, unknown>) => {
      if (patch.reminder === true) void ensureNotificationPermission();
      let prev: Task | undefined;
      setTasks((all) => {
        prev = all.find((x) => x.id === id);
        return all.map((x) =>
          x.id === id ? { ...x, ...(patch as Partial<Task>) } : x,
        );
      });
      try {
        const row = await call<Task>(`/api/tasks/${id}`, "PATCH", patch);
        setTasks((all) => all.map((x) => (x.id === id ? row : x)));
      } catch {
        if (prev) setTasks((all) => all.map((x) => (x.id === id ? prev! : x)));
        toast("Couldn't update this task. Try again.");
      }
    },
    [toast],
  );

  const deleteTask = useCallback(
    async (id: string) => {
      let prev: Task[] = [];
      setTasks((all) => {
        prev = all;
        return all.filter((x) => x.id !== id);
      });
      try {
        await call(`/api/tasks/${id}`, "DELETE");
        toast("Task deleted");
      } catch {
        setTasks(prev);
        toast("Couldn't delete this task. Try again.");
      }
    },
    [toast],
  );

  /* ------------------------------- Habits ------------------------------ */

  const addHabit = useCallback(
    async (input: Record<string, unknown>) => {
      try {
        const row = await call<Habit>("/api/habits", "POST", input);
        setHabits((h) => [...h, row]);
      } catch {
        toast("Couldn't create this habit. Try again.");
      }
    },
    [toast],
  );

  const deleteHabit = useCallback(
    async (id: string) => {
      const prevH = habits;
      const prevL = logs;
      setHabits((h) => h.filter((x) => x.id !== id));
      setLogs((l) => l.filter((x) => x.habitId !== id));
      try {
        await call(`/api/habits/${id}`, "DELETE");
        toast("Habit removed");
      } catch {
        setHabits(prevH);
        setLogs(prevL);
        toast("Couldn't remove this habit. Try again.");
      }
    },
    [habits, logs, toast],
  );

  const toggleHabitToday = useCallback(
    async (id: string) => {
      const date = todayStr();
      const existing = logs.find((l) => l.habitId === id && l.date === date);
      setLogs((l) =>
        existing
          ? l.filter((x) => x.id !== existing.id)
          : [...l, { id: `temp-${date}-${id}`, habitId: id, date }],
      );
      try {
        const r = await call<{ completed: boolean }>(
          `/api/habits/${id}/toggle`,
          "POST",
          { date, today: date },
        );
        setLogs((l) => {
          const withoutTemp = l.filter(
            (x) =>
              !(x.habitId === id && x.date === date && x.id.startsWith("temp")),
          );
          const has = withoutTemp.some(
            (x) => x.habitId === id && x.date === date,
          );
          if (r.completed && !has)
            return [
              ...withoutTemp,
              { id: `srv-${date}-${id}`, habitId: id, date },
            ];
          if (!r.completed)
            return withoutTemp.filter(
              (x) => !(x.habitId === id && x.date === date),
            );
          return withoutTemp;
        });
      } catch {
        setLogs((l) =>
          existing
            ? [...l.filter((x) => x.id !== existing.id), existing].filter(
                (x) => !x.id.startsWith("temp"),
              )
            : l.filter((x) => !(x.habitId === id && x.date === date)),
        );
        toast("Couldn't update this habit. Try again.");
      }
    },
    [logs, toast],
  );

  /* ------------------------------- Money ------------------------------- */

  const addAccount = useCallback(
    async (input: Record<string, unknown>) => {
      try {
        const row = await call<Account>("/api/accounts", "POST", input);
        setAccounts((a) => [...a, row]);
      } catch {
        toast("Couldn't create this account. Try again.");
      }
    },
    [toast],
  );

  const updateAccount = useCallback(
    async (id: string, patch: Record<string, unknown>) => {
      let prev: Account | undefined;
      setAccounts((all) => {
        prev = all.find((x) => x.id === id);
        return all.map((x) =>
          x.id === id ? { ...x, ...(patch as Partial<Account>) } : x,
        );
      });
      try {
        const row = await call<Account>(`/api/accounts/${id}`, "PATCH", patch);
        setAccounts((all) => all.map((x) => (x.id === id ? row : x)));
      } catch {
        if (prev)
          setAccounts((all) => all.map((x) => (x.id === id ? prev! : x)));
        toast("Couldn't update this account. Try again.");
      }
    },
    [toast],
  );

  const deleteAccount = useCallback(
    async (id: string) => {
      const prevA = accounts;
      const prevT = txns;
      setAccounts((a) => a.filter((x) => x.id !== id));
      setTxns((t) => t.filter((x) => x.accountId !== id));
      try {
        await call(`/api/accounts/${id}`, "DELETE");
        toast("Account deleted");
      } catch {
        setAccounts(prevA);
        setTxns(prevT);
        toast("Couldn't delete this account. Try again.");
      }
    },
    [accounts, txns, toast],
  );

  const addTxn = useCallback(
    async (input: Record<string, unknown>) => {
      try {
        const row = await call<Txn>("/api/transactions", "POST", input);
        setTxns((t) =>
          [...t, row].sort(
            (a, b) =>
              new Date(b.occurredAt).getTime() -
              new Date(a.occurredAt).getTime(),
          ),
        );
      } catch {
        toast("Unable to save this transaction. Try again.");
        throw new Error("txn failed");
      }
    },
    [toast],
  );

  const updateTxn = useCallback(
    async (id: string, patch: Record<string, unknown>) => {
      let prev: Txn | undefined;
      setTxns((all) => {
        prev = all.find((x) => x.id === id);
        return all.map((x) =>
          x.id === id ? { ...x, ...(patch as Partial<Txn>) } : x,
        );
      });
      try {
        const row = await call<Txn>(`/api/transactions/${id}`, "PATCH", patch);
        setTxns((all) => all.map((x) => (x.id === id ? row : x)));
      } catch {
        if (prev) setTxns((all) => all.map((x) => (x.id === id ? prev! : x)));
        toast("Unable to save this transaction. Try again.");
        throw new Error("txn update failed");
      }
    },
    [toast],
  );

  const deleteTxn = useCallback(
    async (id: string) => {
      let prev: Txn[] = [];
      setTxns((all) => {
        prev = all;
        return all.filter((x) => x.id !== id);
      });
      try {
        await call(`/api/transactions/${id}`, "DELETE");
        toast("Transaction deleted");
      } catch {
        setTxns(prev);
        toast("Couldn't delete this transaction. Try again.");
      }
    },
    [toast],
  );

  const requestQuick = useCallback((t: Tab, action: string) => {
    setTab(t);
    setQuick({ tab: t, action });
  }, []);
  const consumeQuick = useCallback(() => setQuick(null), []);

  const value = useMemo<DataValue>(
    () => ({
      loading,
      tab,
      setTab,
      notes,
      tasks,
      habits,
      logs,
      accounts,
      txns,
      toasts,
      toast,
      addNote,
      updateNote,
      deleteNote,
      verifyUnlock,
      addTask,
      toggleTask,
      updateTask,
      deleteTask,
      addHabit,
      deleteHabit,
      toggleHabitToday,
      addAccount,
      updateAccount,
      deleteAccount,
      addTxn,
      updateTxn,
      deleteTxn,
      quick,
      requestQuick,
      consumeQuick,
    }),
    [
      loading,
      tab,
      notes,
      tasks,
      habits,
      logs,
      accounts,
      txns,
      toasts,
      toast,
      addNote,
      updateNote,
      deleteNote,
      verifyUnlock,
      addTask,
      toggleTask,
      updateTask,
      deleteTask,
      addHabit,
      deleteHabit,
      toggleHabitToday,
      addAccount,
      updateAccount,
      deleteAccount,
      addTxn,
      updateTxn,
      deleteTxn,
      quick,
      requestQuick,
      consumeQuick,
    ],
  );

  return <DataCtx.Provider value={value}>{children}</DataCtx.Provider>;
}

export function useData() {
  const v = useContext(DataCtx);
  if (!v) throw new Error("useData must be used inside DataProvider");
  return v;
}
