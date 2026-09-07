import { NextResponse } from "next/server";
import { db } from "@/db";
import { notes } from "@/db/schema";

export async function POST(req: Request) {
  const body = await req.json().catch(() => ({}));
  const [row] = await db
    .insert(notes)
    .values({
      title: typeof body.title === "string" ? body.title : "",
      content: typeof body.content === "string" ? body.content : "",
      color: typeof body.color === "string" ? body.color : "default",
      checklist: !!body.checklist,
      tags: Array.isArray(body.tags) ? body.tags : [],
    })
    .returning();
  return NextResponse.json({ ...row, pinHash: undefined }, { status: 201 });
}
