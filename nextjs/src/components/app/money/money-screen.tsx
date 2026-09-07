"use client";

import { format, isSameMonth, isSameWeek, parseISO } from "date-fns";
import { motion } from "framer-motion";
import {
  ChevronLeft,
  ChevronRight,
  Pencil,
  Plus,
  Trash2,
  Wallet,
} from "lucide-react";
import { useMemo, useState } from "react";
import { fmtINR, useData, type Account, type Txn } from "../data";
import {
  ACCOUNT_ICONS,
  buzz,
  CATEGORY_ICONS,
  ColorRow,
  ConfirmSheet,
  EmptyState,
  Money,
  PALETTE,
  PALETTE_NAMES,
  SectionLabel,
  Sheet,
  tint,
} from "../ui";
import { TxnKeypad } from "./txn-keypad";

/* --------------------------------- Helpers --------------------------------- */

const sum = (txns: Txn[], type: "income" | "expense") =>
  txns.filter((t) => t.type === type).reduce((s, t) => s + t.amount, 0);
const balance = (txns: Txn[]) => sum(txns, "income") - sum(txns, "expense");

function dayLabel(iso: string) {
  const d = parseISO(iso);
  const today = new Date();
  const diff = Math.floor(
    (new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime() -
      new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()) / 864e5,
  );
  if (diff === 0) return "Today";
  if (diff === 1) return "Yesterday";
  return format(d, "EEEE, d MMM");
}

function TxnRow({ txn, onTap }: { txn: Txn; onTap: (t: Txn) => void }) {
  const Icon = CATEGORY_ICONS[txn.category] ?? CATEGORY_ICONS.Other;
  const income = txn.type === "income";
  return (
    <motion.button
      layout
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      type="button"
      onClick={() => {
        buzz(5);
        onTap(txn);
      }}
      className="flex w-full items-center gap-3 rounded-2xl px-2 py-2.5 text-left transition-transform active:scale-[0.985]"
    >
      <span
        className="grid h-10 w-10 shrink-0 place-items-center rounded-2xl"
        style={{
          background: income
            ? "color-mix(in srgb, var(--income) 12%, transparent)"
            : "var(--surface-2)",
          color: income ? "var(--income)" : "var(--ink-2)",
        }}
      >
        <Icon size={17} strokeWidth={2.1} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block truncate text-[14px] font-bold text-ink">
          {txn.note || txn.category}
        </span>
        <span className="text-[11.5px] font-medium text-ink-3">
          {txn.category} · {format(parseISO(txn.occurredAt), "h:mm a")}
        </span>
      </span>
      <span
        className="tnum shrink-0 text-[14.5px] font-extrabold"
        style={{ color: income ? "var(--income)" : "var(--expense)" }}
      >
        {fmtINR(income ? txn.amount : -txn.amount, true)}
      </span>
    </motion.button>
  );
}

function groupByDay(txns: Txn[]) {
  const groups: { label: string; items: Txn[] }[] = [];
  txns.forEach((t) => {
    const label = dayLabel(t.occurredAt);
    const g = groups.find((x) => x.label === label);
    if (g) g.items.push(t);
    else groups.push({ label, items: [t] });
  });
  return groups;
}

/* ---------------------------------- Screen --------------------------------- */

export function MoneyScreen() {
  const { accounts, txns } = useData();
  const [accountId, setAccountId] = useState<string | null>(null);
  const [keypad, setKeypad] = useState<{
    accountId: string;
    type: "income" | "expense";
  } | null>(null);
  const [editTxn, setEditTxn] = useState<Txn | null>(null);
  const [accountSheet, setAccountSheet] = useState<Account | "new" | null>(null);

  const live = accounts.filter((a) => !a.archived);
  const active = accountId ? live.find((a) => a.id === accountId) : null;

  return (
    <div className="relative flex h-full flex-col">
      {active ? (
        <AccountView
          account={active}
          txns={txns.filter((t) => t.accountId === active.id)}
          onBack={() => setAccountId(null)}
          onAdd={(type) => setKeypad({ accountId: active.id, type })}
          onEdit={(t) => setEditTxn(t)}
          onSettings={() => setAccountSheet(active)}
        />
      ) : (
        <MoneyHome
          accounts={live}
          txns={txns}
          onOpen={(id) => setAccountId(id)}
          onAddAccount={() => setAccountSheet("new")}
        />
      )}

      <TxnKeypad
        open={!!keypad}
        accountId={keypad?.accountId ?? null}
        initialType={keypad?.type ?? "expense"}
        onClose={() => setKeypad(null)}
      />
      <TxnKeypad
        open={!!editTxn}
        accountId={editTxn?.accountId ?? null}
        initialType={editTxn?.type ?? "expense"}
        editTxn={editTxn}
        onClose={() => setEditTxn(null)}
      />
      <AccountSheet account={accountSheet} onClose={() => setAccountSheet(null)} />
    </div>
  );
}

/* --------------------------------- Home ----------------------------------- */

function activityLabel(txns: Txn[]) {
  if (txns.length === 0) return "No activity yet";
  const latest = txns
    .map((t) => t.occurredAt)
    .sort((a, b) => new Date(b).getTime() - new Date(a).getTime())[0];
  return `Last activity · ${dayLabel(latest)}`;
}

function MoneyHome({
  accounts,
  txns,
  onOpen,
  onAddAccount,
}: {
  accounts: Account[];
  txns: Txn[];
  onOpen: (id: string) => void;
  onAddAccount: () => void;
}) {
  return (
    <>
      <div className="flex items-center px-5 pb-2 pt-5">
        <div className="flex-1">
          <h1 className="text-[26px] font-extrabold tracking-[-0.02em] text-ink">Money</h1>
          <p className="text-[12.5px] font-medium text-ink-3">
            {accounts.length === 0
              ? "Your accounts"
              : `${accounts.length} account${accounts.length === 1 ? "" : "s"}`}
          </p>
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {/* Accounts first — pick one to see its own dashboard. */}
        {accounts.length > 0 && (
          <div className="pt-1">
            <SectionLabel>Accounts</SectionLabel>
            <div
              className="overflow-hidden rounded-[24px] border border-line bg-surface"
              style={{ boxShadow: "var(--shadow-card)" }}
            >
              {accounts.map((a, i) => {
                const accTxns = txns.filter((t) => t.accountId === a.id);
                const bal = balance(accTxns);
                const Icon = ACCOUNT_ICONS[a.icon] ?? ACCOUNT_ICONS.Wallet;
                return (
                  <motion.button
                    key={a.id}
                    type="button"
                    initial={{ opacity: 0, y: 8 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.04 }}
                    onClick={() => {
                      buzz(6);
                      onOpen(a.id);
                    }}
                    className="flex w-full items-center gap-3.5 border-b border-line px-4 py-4 text-left transition-colors last:border-b-0 active:bg-[var(--surface-2)]"
                  >
                    <span
                      className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl"
                      style={{ background: tint(a.color, 14), color: PALETTE[a.color] }}
                    >
                      <Icon size={19} strokeWidth={2.1} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[15px] font-extrabold tracking-tight text-ink">
                        {a.name}
                      </span>
                      <span className="text-[11.5px] font-medium text-ink-3">
                        {activityLabel(accTxns)}
                      </span>
                    </span>
                    <span className="shrink-0 text-right">
                      <Money
                        paise={bal}
                        className="block text-[16px] font-extrabold tracking-tight text-ink"
                      />
                      <ChevronRight size={13} className="ml-auto mt-0.5 text-ink-3" />
                    </span>
                  </motion.button>
                );
              })}
            </div>
            <button
              type="button"
              onClick={() => {
                buzz(6);
                onAddAccount();
              }}
              className="mt-3 flex w-full items-center justify-center gap-2 rounded-[22px] border-[1.6px] border-dashed border-line py-4 text-[13px] font-bold text-ink-3 transition-transform active:scale-[0.98]"
            >
              <Plus size={16} />
              Add account
            </button>
          </div>
        )}

        {/* Recent */}
        {txns.length > 0 && (
          <div className="pt-4">
            <SectionLabel>Recent activity</SectionLabel>
            <div className="rounded-[22px] border border-line bg-surface p-2" style={{ boxShadow: "var(--shadow-card)" }}>
              {txns.slice(0, 5).map((t) => (
                <div key={t.id} className="flex items-center gap-3 px-2 py-2">
                  <TxnGlyph txn={t} accounts={accounts} />
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-[13.5px] font-bold text-ink">
                      {t.note || t.category}
                    </span>
                    <span className="text-[11px] font-medium text-ink-3">
                      {accounts.find((a) => a.id === t.accountId)?.name ?? "Account"} · {dayLabel(t.occurredAt)}
                    </span>
                  </span>
                  <span
                    className="tnum text-[13.5px] font-extrabold"
                    style={{ color: t.type === "income" ? "var(--income)" : "var(--expense)" }}
                  >
                    {fmtINR(t.type === "income" ? t.amount : -t.amount, true)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {accounts.length === 0 && (
          <EmptyState
            icon={Wallet}
            color="teal"
            title="No accounts yet"
            sub="Create one for yourself — or for Mom, Dad, anyone you track money for."
            action="Add account"
            onAction={onAddAccount}
          />
        )}
      </div>
    </>
  );
}

function TxnGlyph({ txn, accounts }: { txn: Txn; accounts: Account[] }) {
  const a = accounts.find((x) => x.id === txn.accountId);
  const Icon = ACCOUNT_ICONS[a?.icon ?? "Wallet"] ?? ACCOUNT_ICONS.Wallet;
  return (
    <span
      className="grid h-9 w-9 shrink-0 place-items-center rounded-xl"
      style={{ background: tint(a?.color ?? "teal", 14), color: PALETTE[a?.color ?? "teal"] }}
    >
      <Icon size={15} />
    </span>
  );
}


/* ------------------------------- Account view ------------------------------ */

function AccountView({
  account,
  txns,
  onBack,
  onAdd,
  onEdit,
  onSettings,
}: {
  account: Account;
  txns: Txn[];
  onBack: () => void;
  onAdd: (t: "income" | "expense") => void;
  onEdit: (t: Txn) => void;
  onSettings: () => void;
}) {
  const [filter, setFilter] = useState<"all" | "income" | "expense">("all");
  const bal = balance(txns);
  const now = new Date();
  const month = txns.filter((t) => isSameMonth(parseISO(t.occurredAt), now));
  const week = txns.filter((t) => isSameWeek(parseISO(t.occurredAt), now, { weekStartsOn: 1 }));

  const filtered = txns.filter((t) => filter === "all" || t.type === filter);
  const groups = groupByDay(filtered);
  const Icon = ACCOUNT_ICONS[account.icon] ?? ACCOUNT_ICONS.Wallet;

  return (
    <>
      {/* Header */}
      <div className="flex items-center gap-2 px-4 pb-2 pt-4">
        <button
          type="button"
          aria-label="Back"
          onClick={onBack}
          className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 active:bg-[var(--surface-2)]"
        >
          <ChevronLeft size={22} />
        </button>
        <div className="flex flex-1 items-center gap-3">
          <span
            className="grid h-10 w-10 place-items-center rounded-2xl"
            style={{ background: tint(account.color, 14), color: PALETTE[account.color] }}
          >
            <Icon size={18} />
          </span>
          <p className="text-[17px] font-extrabold tracking-tight text-ink">{account.name}</p>
        </div>
        <button
          type="button"
          aria-label="Edit account"
          onClick={onSettings}
          className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 active:bg-[var(--surface-2)]"
        >
          <Pencil size={16} />
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {/* Balance hero */}
        <div
          className="relative mt-1 overflow-hidden rounded-[26px] border border-line bg-surface p-5"
          style={{ boxShadow: "var(--shadow-card)" }}
        >
          <div
            aria-hidden
            className="absolute -right-12 -top-14 h-40 w-40 rounded-full opacity-[0.13]"
            style={{ background: `radial-gradient(circle, ${PALETTE[account.color]}, transparent 68%)` }}
          />
          <p className="text-[12px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
            Total balance
          </p>
          <Money paise={bal} className="mt-0.5 block text-[34px] font-extrabold tracking-[-0.03em] text-ink" />
          <div className="mt-4 grid grid-cols-2 gap-2.5">
            <button
              type="button"
              onClick={() => {
                buzz(8);
                onAdd("income");
              }}
              className="flex items-center justify-center gap-2 rounded-2xl py-3.5 text-[14.5px] font-extrabold text-white transition-transform active:scale-[0.97]"
              style={{ background: "var(--income)", boxShadow: "0 10px 22px -8px color-mix(in srgb, var(--income) 55%, transparent)" }}
            >
              <Plus size={16} strokeWidth={3} /> Income
            </button>
            <button
              type="button"
              onClick={() => {
                buzz(8);
                onAdd("expense");
              }}
              className="flex items-center justify-center gap-2 rounded-2xl py-3.5 text-[14.5px] font-extrabold text-white transition-transform active:scale-[0.97]"
              style={{ background: "var(--expense)", boxShadow: "0 10px 22px -8px color-mix(in srgb, var(--expense) 50%, transparent)" }}
            >
              − Expense
            </button>
          </div>
        </div>

        {/* Mini stats */}
        <div className="mt-3 grid grid-cols-2 gap-2.5">
          <div className="rounded-[20px] border border-line bg-surface p-3.5">
            <p className="text-[10.5px] font-extrabold uppercase tracking-wider text-ink-3">This month</p>
            <div className="mt-1 flex items-baseline gap-2">
              <Money paise={sum(month, "income")} sign className="text-[14px] font-extrabold" />
              <Money paise={-sum(month, "expense")} className="text-[12px] font-bold text-ink-3" />
            </div>
          </div>
          <div className="rounded-[20px] border border-line bg-surface p-3.5">
            <p className="text-[10.5px] font-extrabold uppercase tracking-wider text-ink-3">Spent this week</p>
            <Money paise={sum(week, "expense")} className="mt-1 block text-[14px] font-extrabold text-ink" />
          </div>
        </div>

        {/* Spending breakdown section intentionally removed — transactions and
            categories themselves are untouched (request #15). */}

        {/* Statement */}
        <div className="flex gap-2 pt-4 pb-2">
          {(["all", "income", "expense"] as const).map((f) => (
            <button
              key={f}
              type="button"
              onClick={() => {
                buzz(5);
                setFilter(f);
              }}
              className="rounded-full px-4 py-2 text-[12.5px] font-extrabold capitalize transition-all active:scale-95"
              style={{
                background: filter === f ? "var(--ink)" : "var(--surface-2)",
                color: filter === f ? "var(--bg)" : "var(--ink-2)",
              }}
            >
              {f === "all" ? "All" : f}
            </button>
          ))}
        </div>

        {filtered.length === 0 ? (
          <EmptyState
            icon={Wallet}
            color="teal"
            title="No transactions yet"
            sub="Start tracking your money — add an income or expense above."
          />
        ) : (
          groups.map((g) => (
            <div key={g.label} className="pb-1">
              <p className="px-1 pb-1.5 pt-2 text-[10.5px] font-extrabold uppercase tracking-[0.16em] text-ink-3">
                {g.label}
              </p>
              <div className="rounded-[22px] border border-line bg-surface px-2 py-1" style={{ boxShadow: "var(--shadow-card)" }}>
                {g.items.map((t) => (
                  <TxnRow key={t.id} txn={t} onTap={onEdit} />
                ))}
              </div>
            </div>
          ))
        )}
      </div>
    </>
  );
}

/* ------------------------------ Account sheet ------------------------------ */

function AccountSheet({
  account,
  onClose,
}: {
  account: Account | "new" | null;
  onClose: () => void;
}) {
  const { addAccount, updateAccount, deleteAccount } = useData();
  const editing = account !== null && account !== "new" ? account : null;
  const [name, setName] = useState("");
  const [icon, setIcon] = useState("Wallet");
  const [color, setColor] = useState("violet");
  const [confirm, setConfirm] = useState(false);

  useMemo(() => {
    if (editing) {
      setName(editing.name);
      setIcon(editing.icon);
      setColor(editing.color);
    } else {
      setName("");
      setIcon("Wallet");
      setColor("violet");
    }
  }, [account, editing]);

  const save = async () => {
    if (!name.trim()) return;
    buzz(10);
    if (editing) await updateAccount(editing.id, { name: name.trim(), icon, color });
    else await addAccount({ name: name.trim(), icon, color });
    onClose();
  };

  return (
    <>
      <Sheet open={account !== null} onClose={onClose} maxH="88%">
        <p className="px-5 pb-1 text-[16px] font-extrabold tracking-tight text-ink">
          {editing ? "Edit account" : "New account"}
        </p>
        <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-8 no-scrollbar">
          <input
            autoFocus={!editing}
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g. My Account, Mom, Savings…"
            className="w-full bg-transparent py-2 text-[20px] font-extrabold tracking-[-0.01em] text-ink outline-none placeholder:text-ink-3"
          />
          <p className="pb-2.5 pt-4 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
            Icon
          </p>
          <div className="grid grid-cols-5 gap-2">
            {Object.entries(ACCOUNT_ICONS).map(([k, Icon]) => (
              <button
                key={k}
                type="button"
                aria-label={k}
                onClick={() => {
                  buzz(5);
                  setIcon(k);
                }}
                className="grid aspect-square place-items-center rounded-2xl transition-all active:scale-90"
                style={{
                  background: icon === k ? tint(color, 16) : "var(--surface-2)",
                  color: icon === k ? PALETTE[color] : "var(--ink-3)",
                }}
              >
                <Icon size={19} strokeWidth={2.1} />
              </button>
            ))}
          </div>
          <p className="pb-2.5 pt-5 text-[11.5px] font-extrabold uppercase tracking-[0.14em] text-ink-3">
            Color
          </p>
          <ColorRow value={color} onChange={setColor} colors={PALETTE_NAMES.filter((c) => c !== "red")} />
          <button
            type="button"
            disabled={!name.trim()}
            onClick={() => void save()}
            className="mt-6 w-full rounded-2xl py-4 text-[15px] font-extrabold text-white transition-all active:scale-[0.98] disabled:opacity-40"
            style={{
              background: "var(--teal)",
              boxShadow: "0 12px 26px -10px color-mix(in srgb, var(--teal) 55%, transparent)",
            }}
          >
            {editing ? "Save changes" : "Create account"}
          </button>
          {editing && (
            <button
              type="button"
              onClick={() => setConfirm(true)}
              className="mt-3 flex w-full items-center justify-center gap-2 rounded-2xl py-3.5 text-[13.5px] font-bold text-expense"
            >
              <Trash2 size={15} /> Delete account & transactions
            </button>
          )}
        </div>
      </Sheet>
      <ConfirmSheet
        open={confirm}
        onClose={() => setConfirm(false)}
        title="Delete this account?"
        sub={editing ? `"${editing.name}" and all its transactions will be removed.` : ""}
        onConfirm={() => {
          if (editing) void deleteAccount(editing.id);
          onClose();
        }}
      />
    </>
  );
}
