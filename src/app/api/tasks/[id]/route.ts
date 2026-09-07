import { NextResponse } from "next/server";
import { db } from "@/db";
import { tasks } from "@/db/schema";
import { eq } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const patch: Record<string, unknown> = {};

  if (typeof body.title === "string") patch.title = body.title;
  if (typeof body.notes === "string") patch.notes = body.notes;
  if (typeof body.priority === "string") patch.priority = body.priority;
  if (typeof body.category === "string") patch.category = body.category;
  if (typeof body.dueDate === "string" || body.dueDate === null)
    patch.dueDate = body.dueDate;
  if (typeof body.dueTime === "string" || body.dueTime === null)
    patch.dueTime = body.dueTime;
  if (typeof body.reminder === "boolean") patch.reminder = body.reminder;
  if (typeof body.recurrence === "string") patch.recurrence = body.recurrence;
  if (Array.isArray(body.repeatDays))
    patch.repeatDays = body.repeatDays.filter(
      (d: unknown) => typeof d === "number" && d >= 0 && d <= 6,
    );
  if (typeof body.done === "boolean") {
    patch.done = body.done;
    patch.completedAt = body.done ? new Date() : null;
  }

  const [row] = await db
    .update(tasks)
    .set(patch)
    .where(eq(tasks.id, id))
    .returning();
  if (!row)
    return NextResponse.json({ error: "Task not found" }, { status: 404 });
  return NextResponse.json(row);
}

export async function DELETE(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  await db.delete(tasks).where(eq(tasks.id, id));
  return NextResponse.json({ ok: true });
}
