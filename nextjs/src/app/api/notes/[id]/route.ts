import { NextResponse } from "next/server";
import { db } from "@/db";
import { notes } from "@/db/schema";
import { hashPin } from "@/lib/crypto";
import { eq } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const patch: Record<string, unknown> = { updatedAt: new Date() };

  if (typeof body.title === "string") patch.title = body.title;
  if (typeof body.content === "string") patch.content = body.content;
  if (typeof body.color === "string") patch.color = body.color;
  if (typeof body.pinned === "boolean") patch.pinned = body.pinned;
  if (typeof body.archived === "boolean") patch.archived = body.archived;
  if (typeof body.checklist === "boolean") patch.checklist = body.checklist;
  if (Array.isArray(body.tags))
    patch.tags = body.tags.filter((t: unknown) => typeof t === "string");

  if (body.lock === true && typeof body.pin === "string" && body.pin) {
    patch.locked = true;
    patch.pinHash = hashPin(body.pin);
  }
  if (body.lock === false) {
    patch.locked = false;
    patch.pinHash = null;
  }

  const [row] = await db
    .update(notes)
    .set(patch)
    .where(eq(notes.id, id))
    .returning();
  if (!row)
    return NextResponse.json({ error: "Note not found" }, { status: 404 });
  return NextResponse.json({ ...row, pinHash: undefined });
}

export async function DELETE(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  await db.delete(notes).where(eq(notes.id, id));
  return NextResponse.json({ ok: true });
}
