import { NextResponse } from "next/server";
import { db } from "@/db";
import { habits } from "@/db/schema";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  if (typeof body.name !== "string" || !body.name.trim()) {
    return NextResponse.json({ error: "Name is required" }, { status: 400 });
  }
  const frequency =
    body.frequency?.type === "days" && Array.isArray(body.frequency.days)
      ? { type: "days" as const, days: body.frequency.days as number[] }
      : { type: "daily" as const };

  const [row] = await db
    .insert(habits)
    .values({
      name: body.name.trim(),
      icon: typeof body.icon === "string" ? body.icon : "Sparkles",
      color: typeof body.color === "string" ? body.color : "green",
      frequency,
      reminder: !!body.reminder,
    })
    .returning();
  return NextResponse.json(row, { status: 201 });
}
