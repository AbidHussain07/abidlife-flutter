import { NextResponse } from "next/server";
import { db } from "@/db";
import { transactions } from "@/db/schema";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  if (
    typeof body.accountId !== "string" ||
    !["income", "expense"].includes(body.type) ||
    typeof body.amount !== "number" ||
    !(body.amount > 0)
  ) {
    return NextResponse.json({ error: "Invalid transaction" }, { status: 400 });
  }
  const [row] = await db
    .insert(transactions)
    .values({
      accountId: body.accountId,
      type: body.type,
      amount: Math.round(body.amount),
      note: typeof body.note === "string" ? body.note : "",
      category: typeof body.category === "string" ? body.category : "Other",
      occurredAt: body.occurredAt ? new Date(body.occurredAt) : new Date(),
    })
    .returning();
  return NextResponse.json(row, { status: 201 });
}
