import { NextResponse } from "next/server";
import { db } from "@/db";
import { moneyAccounts } from "@/db/schema";
import { eq } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const patch: Record<string, unknown> = {};
  if (typeof body.name === "string") patch.name = body.name;
  if (typeof body.icon === "string") patch.icon = body.icon;
  if (typeof body.color === "string") patch.color = body.color;
  if (typeof body.archived === "boolean") patch.archived = body.archived;

  const [row] = await db
    .update(moneyAccounts)
    .set(patch)
    .where(eq(moneyAccounts.id, id))
    .returning();
  if (!row)
    return NextResponse.json({ error: "Account not found" }, { status: 404 });
  return NextResponse.json(row);
}

export async function DELETE(_req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  await db.delete(moneyAccounts).where(eq(moneyAccounts.id, id));
  return NextResponse.json({ ok: true });
}
