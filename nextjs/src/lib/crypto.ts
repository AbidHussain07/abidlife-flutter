import { createHash } from "crypto";

/** One-way hash for note-lock PINs. PINs are never stored or logged. */
export function hashPin(pin: string) {
  return createHash("sha256").update(`abidlife:${pin}`).digest("hex");
}
