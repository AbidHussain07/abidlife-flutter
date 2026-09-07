import { NextResponse } from "next/server";
import { db } from "@/db";
import { transactions } from "@/db/schema";
import { eq } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const patch: Record<string, unknown> = {};
  if (["income", "expense"].includes(body.type)) patch.type = body.type;
  if (typeof body.amount === "number" && body.amount > 0)
    patch.amount = Math.round(body.amount);
  if (typeof body.note === "string") patch.note = body.note;
  if (typeof body.category === "string") patch.category = body.category;
  if (body.occurredAt) patch.occurredAt = new Date(body.occurredAt);

  const [row] = await db
    .update(transactions)
    .set(patch)
    .where(eq(transactions.id, id))
    .returning();
  if (!row)
    return NextResponse.json({ error: "Transaction not found" }, { status: 404 });
  return NextResponse.json(row);
}

export async function DELETE(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  await db.delete(transactions).where(eq(transactions.id, id));
  return NextResponse.json({ ok: true });
}
