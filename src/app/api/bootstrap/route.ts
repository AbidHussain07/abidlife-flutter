import { NextResponse } from "next/server";
import { db } from "@/db";
import {
  habitLogs,
  habits,
  moneyAccounts,
  notes,
  tasks,
  transactions,
} from "@/db/schema";
import { asc, desc } from "drizzle-orm";

export const dynamic = "force-dynamic";

/**
 * Returns the whole workspace (single-user, local-first app).
 * No demo/seed data — fresh installs start completely empty and every
 * number in the app is derived from real user-created records.
 */
export async function GET() {
  const [allNotes, allTasks, allHabits, allLogs, allAccounts, allTxns] =
    await Promise.all([
      db.select().from(notes).orderBy(desc(notes.updatedAt)),
      db.select().from(tasks).orderBy(desc(tasks.createdAt)),
      db.select().from(habits).orderBy(asc(habits.createdAt)),
      db.select().from(habitLogs),
      db.select().from(moneyAccounts).orderBy(asc(moneyAccounts.createdAt)),
      db.select().from(transactions).orderBy(desc(transactions.occurredAt)),
    ]);

  return NextResponse.json({
    notes: allNotes.map((n) =>
      n.locked
        ? // Titles are shown on locked cards by design; the body, tags and
          // PIN hash never leave protected.
          { ...n, content: "", pinHash: undefined, tags: [] }
        : { ...n, pinHash: undefined },
    ),
    tasks: allTasks,
    habits: allHabits,
    logs: allLogs,
    accounts: allAccounts,
    transactions: allTxns,
  });
}
