"use client";

import { AnimatePresence, motion } from "framer-motion";
import {
  Banknote,
  Briefcase,
  Clapperboard,
  Coins,
  Delete,
  Gift,
  GraduationCap,
  Heart,
  HeartPulse,
  Home,
  Landmark,
  PiggyBank,
  Plane,
  Receipt,
  Shapes,
  ShoppingBag,
  User,
  UtensilsCrossed,
  Wallet,
  Droplets,
  BookOpen,
  Dumbbell,
  Brain,
  PenLine,
  Footprints,
  MoonStar,
  Salad,
  Music,
  Bike,
  Sun,
  Coffee,
  Camera,
  Sparkles,
  type LucideIcon,
} from "lucide-react";
import { useEffect, useState, type ReactNode } from "react";
import { fmtINR } from "./data";

export const buzz = (ms = 8) => {
  if (typeof navigator !== "undefined" && "vibrate" in navigator)
    navigator.vibrate(ms);
};

/* ------------------------------- Icon system ------------------------------ */

export const HABIT_ICONS: Record<string, LucideIcon> = {
  Droplets,
  BookOpen,
  Dumbbell,
  Brain,
  PenLine,
  Footprints,
  MoonStar,
  Salad,
  Music,
  Bike,
  Heart,
  Sun,
  Coffee,
  Camera,
  Sparkles,
};
export const ACCOUNT_ICONS: Record<string, LucideIcon> = {
  Wallet,
  Heart,
  User,
  GraduationCap,
  Briefcase,
  Home,
  PiggyBank,
  Landmark,
  Coins,
  Gift,
};
export const CATEGORY_ICONS: Record<string, LucideIcon> = {
  Food: UtensilsCrossed,
  Shopping: ShoppingBag,
  Travel: Plane,
  Bills: Receipt,
  Salary: Banknote,
  Health: HeartPulse,
  Education: GraduationCap,
  Entertainment: Clapperboard,
  Other: Shapes,
};
export const MONEY_CATEGORIES = Object.keys(CATEGORY_ICONS);
export const TASK_CATEGORIES: Record<string, LucideIcon> = {
  Personal: User,
  Work: Briefcase,
  Shopping: ShoppingBag,
  Home: Home,
  Bills: Receipt,
  Travel: Plane,
  Health: HeartPulse,
  Other: Shapes,
};

export const PALETTE: Record<string, string> = {
  violet: "var(--brand)",
  amber: "var(--amber)",
  blue: "var(--blue)",
  green: "var(--green)",
  teal: "var(--teal)",
  orange: "var(--orange)",
  pink: "var(--pink)",
  red: "var(--red)",
};
export const PALETTE_NAMES = Object.keys(PALETTE);
export const tint = (color: string, amt = 14) =>
  `color-mix(in srgb, ${PALETTE[color] ?? "var(--brand)"} ${amt}%, transparent)`;

const NOTE_VARS: Record<string, string> = {
  default: "--note-default",
  blue: "--note-blue",
  purple: "--note-purple",
  green: "--note-green",
  yellow: "--note-yellow",
  pink: "--note-pink",
};
export const NOTE_COLORS = Object.keys(NOTE_VARS);
export const noteColor = (c: string) => `var(${NOTE_VARS[c] ?? NOTE_VARS.default})`;

/* ------------------------------ Small pieces ------------------------------ */

export function IconBubble({
  color = "violet",
  size = 40,
  icon: Icon,
  rounded = 14,
}: {
  color?: string;
  size?: number;
  icon: LucideIcon;
  rounded?: number;
}) {
  return (
    <div
      className="flex shrink-0 items-center justify-center"
      style={{
        width: size,
        height: size,
        borderRadius: rounded,
        background: tint(color, 14),
        color: PALETTE[color],
      }}
    >
      <Icon size={size * 0.48} strokeWidth={2.2} />
    </div>
  );
}

export function Money({
  paise,
  sign = false,
  className = "",
}: {
  paise: number;
  sign?: boolean;
  className?: string;
}) {
  return <span className={`tnum ${className}`}>{fmtINR(paise, sign)}</span>;
}

export function Toggle({ on, onChange }: { on: boolean; onChange: () => void }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={on}
      onClick={() => {
        buzz(6);
        onChange();
      }}
      className="relative h-7 w-12 shrink-0 rounded-full transition-colors duration-200"
      style={{ background: on ? "var(--green)" : "var(--surface-3)" }}
    >
      <motion.span
        layout
        transition={{ type: "spring", stiffness: 600, damping: 32 }}
        className="absolute top-1 h-5 w-5 rounded-full bg-white shadow"
        style={{ left: on ? 26 : 4 }}
      />
    </button>
  );
}

export function Chip({
  active,
  onClick,
  children,
  color,
}: {
  active?: boolean;
  onClick?: () => void;
  children: ReactNode;
  color?: string;
}) {
  return (
    <button
      type="button"
      onClick={() => {
        buzz(6);
        onClick?.();
      }}
      className="shrink-0 rounded-full px-3.5 py-2 text-[13px] font-semibold transition-all duration-200 active:scale-95"
      style={{
        background: active
          ? color
            ? tint(color, 16)
            : "var(--ink)"
          : "var(--surface-2)",
        color: active
          ? color
            ? PALETTE[color]
            : "var(--bg)"
          : "var(--ink-2)",
      }}
    >
      {children}
    </button>
  );
}

export function ColorRow({
  value,
  onChange,
  colors = PALETTE_NAMES,
}: {
  value: string;
  onChange: (c: string) => void;
  colors?: string[];
}) {
  return (
    <div className="flex flex-wrap items-center gap-2.5">
      {colors.map((c) => (
        <button
          key={c}
          type="button"
          aria-label={`Color ${c}`}
          onClick={() => {
            buzz(6);
            onChange(c);
          }}
          className="grid h-9 w-9 place-items-center rounded-full transition-transform active:scale-90"
          style={{
            background: PALETTE[c] ?? "var(--surface-3)",
            boxShadow:
              value === c
                ? `0 0 0 2px var(--bg), 0 0 0 4.5px ${PALETTE[c] ?? "var(--ink-3)"}`
                : "none",
          }}
        >
          {value === c && (
            <motion.span
              layoutId="color-check"
              className="h-2 w-2 rounded-full bg-white"
            />
          )}
        </button>
      ))}
    </div>
  );
}

export function EmptyState({
  icon: Icon,
  color = "violet",
  title,
  sub,
  action,
  onAction,
}: {
  icon: LucideIcon;
  color?: string;
  title: string;
  sub: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="rise flex flex-col items-center px-8 py-14 text-center">
      <div
        className="mb-4 grid h-16 w-16 place-items-center rounded-[22px]"
        style={{ background: tint(color, 12), color: PALETTE[color] }}
      >
        <Icon size={26} strokeWidth={1.9} />
      </div>
      <p className="text-[17px] font-bold tracking-tight text-ink">{title}</p>
      <p className="mt-1.5 max-w-[250px] text-[13.5px] leading-relaxed text-ink-3">
        {sub}
      </p>
      {action && onAction && (
        <button
          type="button"
          onClick={() => {
            buzz(8);
            onAction();
          }}
          className="mt-5 rounded-full px-5 py-2.5 text-[13.5px] font-bold transition-transform active:scale-95"
          style={{ background: tint(color, 14), color: PALETTE[color] }}
        >
          {action}
        </button>
      )}
    </div>
  );
}

export function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <p className="px-1 pb-2 text-[11.5px] font-bold uppercase tracking-[0.14em] text-ink-3">
      {children}
    </p>
  );
}

/* ---------------------------------- Sheet --------------------------------- */

export function Sheet({
  open,
  onClose,
  children,
  maxH = "92%",
}: {
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  maxH?: string;
}) {
  return (
    <AnimatePresence>
      {open && (
        <div className="absolute inset-0 z-50">
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={onClose}
            className="absolute inset-0 bg-black/45 backdrop-blur-[2px]"
          />
          <motion.div
            initial={{ y: "104%" }}
            animate={{ y: 0 }}
            exit={{ y: "104%" }}
            transition={{ type: "spring", stiffness: 420, damping: 40 }}
            drag="y"
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0, bottom: 0.6 }}
            onDragEnd={(_, info) => {
              if (info.offset.y > 110 || info.velocity.y > 600) onClose();
            }}
            className="absolute inset-x-0 bottom-0 flex flex-col overflow-hidden rounded-t-[28px] border-t border-line bg-surface"
            style={{ maxHeight: maxH, boxShadow: "var(--shadow-pop)" }}
          >
            <div className="grid place-items-center pb-1 pt-2.5">
              <div className="h-1.5 w-10 rounded-full bg-surface-3" />
            </div>
            {children}
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}

export function Overlay({
  show,
  children,
  from = "bottom",
}: {
  show: boolean;
  children: ReactNode;
  from?: "bottom" | "right";
}) {
  const axis = from === "bottom" ? { y: 44, x: 0 } : { x: 44, y: 0 };
  return (
    <AnimatePresence>
      {show && (
        <motion.div
          initial={{ opacity: 0, ...axis }}
          animate={{ opacity: 1, x: 0, y: 0 }}
          exit={{ opacity: 0, ...axis }}
          transition={{ type: "spring", stiffness: 380, damping: 38 }}
          className="absolute inset-0 z-40 flex flex-col bg-app"
        >
          {children}
        </motion.div>
      )}
    </AnimatePresence>
  );
}

export function RowButton({
  onClick,
  icon: Icon,
  color = "violet",
  label,
  sub,
  danger,
}: {
  onClick: () => void;
  icon: LucideIcon;
  color?: string;
  label: string;
  sub?: string;
  danger?: boolean;
}) {
  const c = danger ? "var(--expense)" : PALETTE[color];
  return (
    <button
      type="button"
      onClick={() => {
        buzz(6);
        onClick();
      }}
      className="flex w-full items-center gap-3.5 rounded-2xl px-2.5 py-3 text-left transition-colors active:bg-[var(--surface-2)]"
    >
      <div
        className="grid h-10 w-10 place-items-center rounded-2xl"
        style={{
          background: danger ? "color-mix(in srgb, var(--expense) 12%, transparent)" : tint(color, 13),
          color: c,
        }}
      >
        <Icon size={19} strokeWidth={2.1} />
      </div>
      <div className="min-w-0 flex-1">
        <p
          className="text-[14.5px] font-bold"
          style={{ color: danger ? "var(--expense)" : "var(--ink)" }}
        >
          {label}
        </p>
        {sub && <p className="truncate text-[12px] text-ink-3">{sub}</p>}
      </div>
    </button>
  );
}

/* --------------------------------- PIN pad -------------------------------- */

export function PinPad({
  title,
  sub,
  error,
  resetKey,
  onComplete,
  onCancel,
}: {
  title: string;
  sub?: string;
  error?: string;
  /** Bump this after every failed submission: the input clears instantly and
   *  the pad is ready for a brand-new PIN without pressing backspace. */
  resetKey?: number;
  onComplete: (pin: string) => void;
  onCancel?: () => void;
}) {
  const [pin, setPinState] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const setPin = (updater: (p: string) => string) => {
    setPinState((p) => updater(p));
  };

  // Hard reset after a failed attempt — input empties immediately and a new
  // attempt can start typing right away (even if the error text is identical).
  useEffect(() => {
    if (resetKey === undefined) return;
    setPinState("");
    setSubmitting(false);
  }, [resetKey]);

  useEffect(() => {
    if (pin.length === 4 && !submitting) {
      setSubmitting(true);
      const t = window.setTimeout(() => onComplete(pin), 160);
      return () => window.clearTimeout(t);
    }
  }, [pin, submitting, onComplete]);

  const press = (k: string) => {
    buzz(6);
    if (k === "back") setPin((p) => p.slice(0, -1));
    else if (pin.length < 4) setPin((p) => p + k);
  };

  return (
    <div className="flex flex-col items-center px-6 pb-8 pt-3">
      <p className="text-[17px] font-bold tracking-tight text-ink">{title}</p>
      {sub && <p className="mt-1 text-[13px] text-ink-3">{sub}</p>}
      <motion.div
        key={resetKey ?? 0}
        animate={resetKey ? { x: [0, -9, 9, -6, 6, 0] } : {}}
        transition={{ duration: 0.4 }}
        className="mt-6 flex gap-4"
      >
        {[0, 1, 2, 3].map((i) => (
          <span
            key={i}
            className="h-3.5 w-3.5 rounded-full transition-all duration-150"
            style={{
              background:
                i < pin.length ? "var(--brand)" : "var(--surface-3)",
              transform: i < pin.length ? "scale(1.12)" : "none",
            }}
          />
        ))}
      </motion.div>
      {error && (
        <p className="mt-3 text-[12.5px] font-semibold text-expense">{error}</p>
      )}
      <div className="mt-7 grid w-full max-w-[270px] grid-cols-3 gap-2.5">
        {["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "back"].map(
          (k) =>
            k === "" ? (
              <span key="spacer" />
            ) : (
              <button
                key={k}
                type="button"
                aria-label={k === "back" ? "Backspace" : k}
                onClick={() => press(k)}
                className="grid h-[60px] place-items-center rounded-2xl text-[22px] font-bold text-ink transition-all duration-100 active:scale-95 active:bg-[var(--surface-2)]"
              >
                {k === "back" ? <Delete size={22} /> : k}
              </button>
            ),
        )}
      </div>
      {onCancel && (
        <button
          type="button"
          onClick={onCancel}
          className="mt-5 text-[13.5px] font-bold text-ink-3"
        >
          Cancel
        </button>
      )}
    </div>
  );
}

export function ConfirmSheet({
  open,
  onClose,
  title,
  sub,
  confirm = "Delete",
  onConfirm,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  sub: string;
  confirm?: string;
  onConfirm: () => void;
}) {
  return (
    <Sheet open={open} onClose={onClose} maxH="60%">
      <div className="px-6 pb-9 pt-2 text-center">
        <p className="text-[17px] font-bold tracking-tight text-ink">{title}</p>
        <p className="mx-auto mt-1.5 max-w-[270px] text-[13.5px] leading-relaxed text-ink-3">
          {sub}
        </p>
        <div className="mt-6 flex gap-3">
          <button
            type="button"
            onClick={onClose}
            className="flex-1 rounded-2xl bg-surface-2 py-3.5 text-[14px] font-bold text-ink-2 transition-transform active:scale-[0.97]"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={() => {
              buzz(10);
              onConfirm();
              onClose();
            }}
            className="flex-1 rounded-2xl py-3.5 text-[14px] font-bold text-white transition-transform active:scale-[0.97]"
            style={{ background: "var(--expense)" }}
          >
            {confirm}
          </button>
        </div>
      </div>
    </Sheet>
  );
}
