import { NextResponse } from "next/server";
import { db } from "@/db";
import { habitLogs, habits } from "@/db/schema";
import { and, eq, gte, lt } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

/**
 * Toggles completion for a given date. To keep streaks honest, only today
 * can be toggled — past days are read-only.
 */
export async function POST(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const date = typeof body.date === "string" ? body.date : "";
  const today = body.today as string;
  if (!date || !today || date !== today) {
    return NextResponse.json(
      { error: "Only today can be checked off" },
      { status: 400 },
    );
  }

  const [habit] = await db
    .select()
    .from(habits)
    .where(eq(habits.id, id))
    .limit(1);
  if (!habit)
    return NextResponse.json({ error: "Habit not found" }, { status: 404 });

  const [existing] = await db
    .select()
    .from(habitLogs)
    .where(and(eq(habitLogs.habitId, id), eq(habitLogs.date, date)))
    .limit(1);

  if (existing) {
    await db.delete(habitLogs).where(eq(habitLogs.id, existing.id));
    return NextResponse.json({ ok: true, completed: false, date });
  }
  await db.insert(habitLogs).values({ habitId: id, date });
  return NextResponse.json({ ok: true, completed: true, date });
}

/** Returns all logs for a habit (used after toggles). */
export async function GET(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const rows = await db
    .select()
    .from(habitLogs)
    .where(and(eq(habitLogs.habitId, id), gte(habitLogs.date, "2000-01-01"), lt(habitLogs.date, "3000-01-01")));
  return NextResponse.json(rows);
}
