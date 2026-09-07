import { NextResponse } from "next/server";
import { db } from "@/db";
import { moneyAccounts } from "@/db/schema";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  if (typeof body.name !== "string" || !body.name.trim()) {
    return NextResponse.json({ error: "Name is required" }, { status: 400 });
  }
  const [row] = await db
    .insert(moneyAccounts)
    .values({
      name: body.name.trim(),
      icon: typeof body.icon === "string" ? body.icon : "Wallet",
      color: typeof body.color === "string" ? body.color : "violet",
    })
    .returning();
  return NextResponse.json(row, { status: 201 });
}
