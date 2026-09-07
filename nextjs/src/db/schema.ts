import {
  boolean,
  index,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";

/* ---------------------------------- Notes --------------------------------- */

export const notes = pgTable(
  "notes",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    title: text("title").notNull().default(""),
    content: text("content").notNull().default(""), // rich HTML from editor
    color: text("color").notNull().default("default"),
    tags: jsonb("tags").$type<string[]>().notNull().default([]),
    pinned: boolean("pinned").notNull().default(false),
    archived: boolean("archived").notNull().default(false),
    locked: boolean("locked").notNull().default(false),
    pinHash: text("pin_hash"), // sha256, never plain text
    checklist: boolean("checklist").notNull().default(false),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [index("notes_updated_idx").on(t.updatedAt)],
);

/* ---------------------------------- Tasks --------------------------------- */

export const tasks = pgTable(
  "tasks",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    title: text("title").notNull(),
    notes: text("notes").notNull().default(""),
    done: boolean("done").notNull().default(false),
    priority: text("priority").notNull().default("none"), // none|low|medium|high
    category: text("category").notNull().default("Personal"),
    dueDate: text("due_date"), // yyyy-mm-dd or null
    dueTime: text("due_time"), // HH:mm or null
    reminder: boolean("reminder").notNull().default(false),
    recurrence: text("recurrence").notNull().default("none"), // none|daily|weekly|monthly
    // Weekdays (0 = Sunday … 6 = Saturday) for weekly recurrence.
    repeatDays: jsonb("repeat_days").$type<number[]>().notNull().default([]),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [index("tasks_done_idx").on(t.done)],
);

/* --------------------------------- Habits --------------------------------- */

export const habits = pgTable("habits", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  icon: text("icon").notNull().default("Sparkles"),
  color: text("color").notNull().default("green"),
  // { type: "daily" } | { type: "days", days: number[] } (0 = Sunday)
  frequency: jsonb("frequency")
    .$type<{ type: "daily" } | { type: "days"; days: number[] }>()
    .notNull()
    .default({ type: "daily" }),
  reminder: boolean("reminder").notNull().default(false),
  archived: boolean("archived").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

export const habitLogs = pgTable(
  "habit_logs",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    habitId: uuid("habit_id")
      .notNull()
      .references(() => habits.id, { onDelete: "cascade" }),
    date: text("date").notNull(), // yyyy-mm-dd
  },
  (t) => [uniqueIndex("habit_logs_habit_date_idx").on(t.habitId, t.date)],
);

/* ---------------------------------- Money --------------------------------- */

export const moneyAccounts = pgTable("money_accounts", {
  id: uuid("id").defaultRandom().primaryKey(),
  name: text("name").notNull(),
  icon: text("icon").notNull().default("Wallet"),
  color: text("color").notNull().default("violet"),
  archived: boolean("archived").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});

export const transactions = pgTable(
  "transactions",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    accountId: uuid("account_id")
      .notNull()
      .references(() => moneyAccounts.id, { onDelete: "cascade" }),
    type: text("type").notNull(), // income | expense
    amount: integer("amount").notNull(), // integer paise (₹1 = 100) — no float money
    note: text("note").notNull().default(""),
    category: text("category").notNull().default("Other"),
    occurredAt: timestamp("occurred_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
    createdAt: timestamp("created_at", { withTimezone: true })
      .notNull()
      .defaultNow(),
  },
  (t) => [index("txn_account_idx").on(t.accountId, t.occurredAt)],
);
