import { NextResponse } from "next/server";
import { db } from "@/db";
import { notes } from "@/db/schema";
import { hashPin } from "@/lib/crypto";
import { eq } from "drizzle-orm";

type Ctx = { params: Promise<{ id: string }> };

/** Verifies a lock PIN and returns the full note content on success. */
export async function POST(req: Request, ctx: Ctx) {
  const { id } = await ctx.params;
  const body = await req.json().catch(() => ({}));
  const pin = typeof body.pin === "string" ? body.pin : "";
  if (!pin) return NextResponse.json({ ok: false }, { status: 400 });

  const [row] = await db.select().from(notes).where(eq(notes.id, id)).limit(1);
  if (!row) return NextResponse.json({ ok: false }, { status: 404 });

  if (!row.locked || !row.pinHash) {
    return NextResponse.json({ ok: true, note: { ...row, pinHash: undefined } });
  }
  if (hashPin(pin) !== row.pinHash) {
    return NextResponse.json({ ok: false }, { status: 401 });
  }
  return NextResponse.json({ ok: true, note: { ...row, pinHash: undefined } });
}
