"use client";

import { format, parseISO } from "date-fns";
import { motion } from "framer-motion";
import { Check, Delete, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { dateStr, fmtINR, parseD, todayStr, useData, type Txn } from "../data";
import {
  buzz,
  CATEGORY_ICONS,
  MONEY_CATEGORIES,
  Overlay,
  tint,
} from "../ui";

type Props = {
  open: boolean;
  accountId: string | null;
  initialType: "income" | "expense";
  editTxn?: Txn | null;
  onClose: () => void;
};

const DIGITS = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "back"];

export function TxnKeypad({ open, accountId, initialType, editTxn, onClose }: Props) {
  const { addTxn, updateTxn } = useData();
  const [type, setType] = useState<"income" | "expense">(initialType);
  const [amt, setAmt] = useState("0");
  const [note, setNote] = useState("");
  const [category, setCategory] = useState("Other");
  const [date, setDate] = useState(todayStr());
  const [saved, setSaved] = useState(false);
  const noteRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!open) return;
    setSaved(false);
    if (editTxn) {
      setType(editTxn.type);
      const r = editTxn.amount / 100;
      setAmt(Number.isInteger(r) ? String(r) : r.toFixed(2));
      setNote(editTxn.note);
      setCategory(editTxn.category);
      setDate(parseISO(editTxn.occurredAt).toLocaleDateString("en-CA"));
    } else {
      setType(initialType);
      setAmt("0");
      setNote("");
      setCategory("Other");
      setDate(todayStr());
    }
  }, [open, editTxn, initialType]);

  const paise = Math.round(parseFloat(amt || "0") * 100);
  const valid = paise > 0;
  const color = type === "income" ? "var(--income)" : "var(--expense)";

  const press = (k: string) => {
    buzz(6);
    setAmt((a) => {
      if (k === "back") {
        const next = a.slice(0, -1);
        return next === "" ? "0" : next;
      }
      if (k === ".") {
        if (a.includes(".")) return a;
        return `${a}.`;
      }
      const [int, dec] = a.split(".");
      if (dec !== undefined && dec.length >= 2) return a;
      if (int.length >= 7) return a;
      return a === "0" ? k : a + k;
    });
  };

  const displayInt = () => {
    const [int] = amt.split(".");
    const n = Number(int || "0");
    return new Intl.NumberFormat("en-IN").format(n);
  };
  const displayDec = () => {
    const parts = amt.split(".");
    return parts.length > 1 ? `.${parts[1]}` : "";
  };

  const save = async () => {
    if (!valid || saved) return;
    buzz(14);
    setSaved(true);
    try {
      const now = new Date();
      let occurredAt: Date;
      if (date === todayStr()) occurredAt = now;
      else {
        occurredAt = parseD(date);
        if (editTxn) {
          const prev = parseISO(editTxn.occurredAt);
          occurredAt.setHours(prev.getHours(), prev.getMinutes());
        } else occurredAt.setHours(now.getHours(), now.getMinutes());
      }
      const payload = {
        type,
        amount: paise,
        note: note.trim(),
        category,
        occurredAt: occurredAt.toISOString(),
      };
      if (editTxn) await updateTxn(editTxn.id, payload);
      else await addTxn({ ...payload, accountId });
      window.setTimeout(onClose, 480);
    } catch {
      setSaved(false);
    }
  };

  const title = editTxn
    ? "Edit transaction"
    : type === "income"
      ? "Add income"
      : "Add expense";

  return (
    <Overlay show={open}>
      {/* The whole sheet scrolls if the soft keyboard steals vertical space,
          so Continue stays reachable without dismissing the keyboard. The OS
          also resizes the page (viewport interactive-widget=resizes-content). */}
      <div className="flex h-full flex-col overflow-y-auto no-scrollbar">
        {/* Header */}
        <div className="txn-header flex items-center justify-between px-4 pb-1 pt-3">
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 active:bg-[var(--surface-2)]"
          >
            <X size={20} />
          </button>
          <div className="flex rounded-full bg-surface-2 p-1">
            {(["expense", "income"] as const).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => {
                  buzz(6);
                  setType(t);
                }}
                className="rounded-full px-4 py-1.5 text-[12.5px] font-extrabold capitalize transition-all"
                style={{
                  background: type === t ? "var(--surface)" : "transparent",
                  color:
                    type === t
                      ? t === "income"
                        ? "var(--income)"
                        : "var(--expense)"
                      : "var(--ink-3)",
                  boxShadow: type === t ? "var(--shadow-card)" : "none",
                }}
                aria-label={t}
              >
                {t === "income" ? "+ Income" : "− Expense"}
              </button>
            ))}
          </div>
          <span className="w-10" />
        </div>

        {/* Amount */}
        <div className="flex flex-col items-center pb-3 pt-2">
          <p className="text-[11.5px] font-extrabold uppercase tracking-[0.16em] text-ink-3">
            {title}
          </p>
          <p className="txn-amt tnum mt-1 text-[46px] font-extrabold leading-none tracking-[-0.03em]" style={{ color }}>
            ₹{displayInt()}
            <span className="text-[30px]">{displayDec()}</span>
          </p>
          {valid && (
            <p className="mt-1 text-[12px] font-semibold text-ink-3">
              {fmtINR(paise, true)}
            </p>
          )}
        </div>

        {/* Note */}
        <div className="px-6">
          <input
            ref={noteRef}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            onFocus={() => {
              // Keep the field visible above the soft keyboard.
              window.setTimeout(
                () =>
                  noteRef.current?.scrollIntoView({
                    block: "center",
                    behavior: "smooth",
                  }),
                250,
              );
            }}
            placeholder="What was this for?"
            aria-label="Note"
            className="h-11 w-full shrink-0 rounded-2xl border border-line bg-surface px-4 text-center text-[14px] font-semibold text-ink outline-none placeholder:text-ink-3"
          />
        </div>

        {/* Categories */}
        <div className="flex gap-2 overflow-x-auto px-6 py-2.5 no-scrollbar">
          {MONEY_CATEGORIES.map((c) => {
            const Icon = CATEGORY_ICONS[c];
            const active = category === c;
            return (
              <button
                key={c}
                type="button"
                onClick={() => {
                  buzz(5);
                  setCategory(c);
                }}
                className="flex shrink-0 flex-col items-center gap-1"
                aria-label={c}
              >
                <span
                  className="grid h-11 w-11 place-items-center rounded-2xl transition-all active:scale-90"
                  style={{
                    background: active
                      ? type === "income"
                        ? "color-mix(in srgb, var(--income) 15%, transparent)"
                        : "color-mix(in srgb, var(--expense) 12%, transparent)"
                      : "var(--surface-2)",
                    color: active ? color : "var(--ink-3)",
                    boxShadow: active ? `0 0 0 1.6px ${color}` : "none",
                  }}
                >
                  <Icon size={18} strokeWidth={2.1} />
                </span>
                <span
                  className="text-[9.5px] font-bold"
                  style={{ color: active ? color : "var(--ink-3)" }}
                >
                  {c}
                </span>
              </button>
            );
          })}
        </div>

        {/* Date */}
        <div className="flex items-center gap-2 px-6 pb-2">
          {[
            { label: "Today", v: todayStr() },
            { label: "Yesterday", v: dateStr(new Date(Date.now() - 864e5)) },
          ].map((o) => (
            <button
              key={o.label}
              type="button"
              onClick={() => {
                buzz(5);
                setDate(o.v);
              }}
              className="rounded-full px-3.5 py-1.5 text-[12px] font-bold transition-all active:scale-95"
              style={{
                background: date === o.v ? "var(--ink)" : "var(--surface-2)",
                color: date === o.v ? "var(--bg)" : "var(--ink-2)",
              }}
            >
              {o.label}
            </button>
          ))}
          <label className="relative">
            <input
              type="date"
              aria-label="Pick date"
              className="absolute inset-0 opacity-0"
              value={date}
              onChange={(e) => e.target.value && setDate(e.target.value)}
            />
            <span
              className="rounded-full px-3.5 py-1.5 text-[12px] font-bold"
              style={{
                background:
                  date !== todayStr() && date !== dateStr(new Date(Date.now() - 864e5))
                    ? "var(--ink)"
                    : "var(--surface-2)",
                color:
                  date !== todayStr() && date !== dateStr(new Date(Date.now() - 864e5))
                    ? "var(--bg)"
                    : "var(--ink-2)",
              }}
            >
              {date !== todayStr() && date !== dateStr(new Date(Date.now() - 864e5))
                ? format(parseD(date), "d MMM")
                : "Pick…"}
            </span>
          </label>
        </div>

        {/* Keypad */}
        <div className="mt-auto shrink-0 px-6 pb-2">
          <div className="grid grid-cols-3 gap-1">
            {DIGITS.map((k) => (
              <button
                key={k}
                type="button"
                aria-label={k === "back" ? "Backspace" : k}
                onClick={() => press(k)}
                className="txn-pad-key grid h-[54px] place-items-center rounded-2xl text-[24px] font-bold text-ink transition-all duration-100 active:scale-95 active:bg-[var(--surface-2)]"
              >
                {k === "back" ? <Delete size={22} /> : k}
              </button>
            ))}
          </div>
          <motion.button
            type="button"
            disabled={!valid}
            onClick={() => void save()}
            whileTap={{ scale: 0.97 }}
            className="txn-cta mt-2 flex h-[54px] w-full items-center justify-center rounded-2xl text-[15.5px] font-extrabold text-white transition-opacity disabled:opacity-35"
            style={{
              background: saved ? "var(--green)" : color,
              boxShadow: `0 14px 30px -10px ${tint(type === "income" ? "green" : "red", 45)}`,
            }}
          >
            {saved ? (
              <span className="flex items-center gap-2">
                <Check size={19} strokeWidth={3} /> Added
              </span>
            ) : (
              "Continue"
            )}
          </motion.button>
        </div>
      </div>
    </Overlay>
  );
}
