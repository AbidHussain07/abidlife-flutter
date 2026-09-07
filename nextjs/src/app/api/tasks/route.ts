import { NextResponse } from "next/server";
import { db } from "@/db";
import { tasks } from "@/db/schema";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  if (typeof body.title !== "string" || !body.title.trim()) {
    return NextResponse.json({ error: "Title is required" }, { status: 400 });
  }
  const [row] = await db
    .insert(tasks)
    .values({
      title: body.title.trim(),
      notes: typeof body.notes === "string" ? body.notes : "",
      priority: ["none", "low", "medium", "high"].includes(body.priority)
        ? body.priority
        : "none",
      category: typeof body.category === "string" ? body.category : "Personal",
      dueDate: typeof body.dueDate === "string" ? body.dueDate : null,
      dueTime: typeof body.dueTime === "string" ? body.dueTime : null,
      reminder: !!body.reminder,
      recurrence: ["none", "daily", "weekly", "monthly"].includes(
        body.recurrence,
      )
        ? body.recurrence
        : "none",
      repeatDays: Array.isArray(body.repeatDays)
        ? body.repeatDays.filter(
            (d: unknown) => typeof d === "number" && d >= 0 && d <= 6,
          )
        : [],
    })
    .returning();
  return NextResponse.json(row, { status: 201 });
}
