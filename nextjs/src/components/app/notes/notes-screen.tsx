"use client";

import { format, isToday, isYesterday, parseISO } from "date-fns";
import { AnimatePresence, motion } from "framer-motion";
import {
  Archive,
  ArchiveRestore,
  ArrowUpDown,
  Image as ImageIcon,
  Lock,
  LockOpen,
  NotebookPen,
  Pin,
  Plus,
  Search,
  ListChecks,
  StickyNote,
  Trash2,
  X,
} from "lucide-react";
import { useEffect, useMemo, useRef, useState } from "react";
import { useData, type Note } from "../data";
import {
  buzz,
  ConfirmSheet,
  EmptyState,
  noteColor,
  Overlay,
  PinPad,
  RowButton,
  Sheet,
  tint,
  PALETTE,
} from "../ui";
import { NoteEditor } from "./note-editor";

export function excerpt(html: string, max = 120) {
  const text = html
    .replace(/<\/(p|li|h2|ul|ol|div)>/gi, " · ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  return text.length > max ? `${text.slice(0, max).trimEnd()}…` : text;
}

function relDate(iso: string) {
  const d = parseISO(iso);
  if (isToday(d)) return "Today";
  if (isYesterday(d)) return "Yesterday";
  return format(d, "d MMM");
}

export function checkProgress(html: string) {
  const items = (html.match(/<li/g) ?? []).length;
  const done = (html.match(/<li class="done"/g) ?? []).length;
  return items ? { done, total: items } : null;
}

/* ------------------------------ Long press -------------------------------- */

const LONG_PRESS_MS = 600;

/** Pointer-based long press: fires a menu (not the action) after ~0.6s,
 *  cancelled by movement/scroll; right-click works on desktop too. */
function useLongPress(onTrigger: () => void) {
  const timer = useRef<number | undefined>(undefined);
  const pos = useRef<{ x: number; y: number } | null>(null);
  const fired = useRef(false);

  const clear = () => window.clearTimeout(timer.current);

  const handlers = {
    onPointerDown: (e: React.PointerEvent) => {
      fired.current = false;
      pos.current = { x: e.clientX, y: e.clientY };
      clear();
      timer.current = window.setTimeout(() => {
        fired.current = true;
        buzz(22);
        onTrigger();
      }, LONG_PRESS_MS);
    },
    onPointerMove: (e: React.PointerEvent) => {
      if (!pos.current) return;
      const dx = Math.abs(e.clientX - pos.current.x);
      const dy = Math.abs(e.clientY - pos.current.y);
      if (dx > 10 || dy > 10) clear();
    },
    onPointerUp: clear,
    onPointerLeave: clear,
    onContextMenu: (e: React.MouseEvent) => {
      e.preventDefault();
      clear();
      fired.current = true;
      buzz(22);
      onTrigger();
    },
  };
  const consumeClick = () => {
    if (fired.current) {
      fired.current = false;
      return true;
    }
    return false;
  };
  return { handlers, consumeClick };
}

/* -------------------------------- Note card -------------------------------- */

function NoteCard({
  note,
  onOpen,
  onMenu,
}: {
  note: Note;
  onOpen: (n: Note) => void;
  onMenu: (n: Note) => void;
}) {
  const cp = note.checklist ? checkProgress(note.content) : null;
  const hasImage = /<img\b/i.test(note.content);
  const lp = useLongPress(() => onMenu(note));

  return (
    <motion.button
      layout
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.96 }}
      transition={{ type: "spring", stiffness: 320, damping: 30 }}
      type="button"
      {...lp.handlers}
      onClick={() => {
        if (lp.consumeClick()) return;
        buzz(6);
        onOpen(note);
      }}
      className="mb-3 block w-full select-none break-inside-avoid rounded-[22px] border border-line p-4 text-left transition-transform duration-150 active:scale-[0.975]"
      style={{
        background: noteColor(note.color),
        boxShadow: "var(--shadow-card)",
        WebkitTouchCallout: "none",
      }}
    >
      {note.locked ? (
        <>
          {/* Title stays visible by design; only the body is protected. */}
          <p className="line-clamp-2 text-[15px] font-extrabold leading-snug tracking-[-0.01em] text-ink">
            {note.title || "Untitled"}
          </p>
          <div
            className="mt-2 inline-flex items-center gap-1.5 rounded-full px-2.5 py-1"
            style={{ background: tint("violet", 12) }}
          >
            <Lock size={11} style={{ color: "var(--brand)" }} />
            <span
              className="text-[10.5px] font-extrabold"
              style={{ color: "var(--brand)" }}
            >
              Private note
            </span>
          </div>
          {/* Placeholder bars keep the card the same visual size as others. */}
          <div className="mt-3 space-y-2" aria-hidden>
            {["100%", "68%", "82%"].map((w, i) => (
              <div
                key={i}
                className="h-2 rounded-full"
                style={{ width: w, background: "var(--surface-3)", opacity: 0.65 }}
              />
            ))}
          </div>
        </>
      ) : (
        <>
          <p className="line-clamp-2 text-[15px] font-extrabold leading-snug tracking-[-0.01em] text-ink">
            {note.title || "Untitled"}
          </p>
          {note.content && (
            <p className="mt-1.5 line-clamp-4 text-[12.5px] leading-relaxed text-ink-2">
              {excerpt(note.content) || "—"}
            </p>
          )}
          {cp && (
            <div className="mt-2.5 flex items-center gap-1.5">
              <ListChecks size={13} style={{ color: "var(--green)" }} />
              <span className="text-[11px] font-bold text-ink-3">
                {cp.done}/{cp.total} done
              </span>
            </div>
          )}
        </>
      )}
      <div className="mt-3 flex items-center gap-1.5 overflow-hidden">
        {note.pinned && (
          <Pin
            size={12}
            className="shrink-0 rotate-45"
            style={{ color: "var(--brand)" }}
            fill="var(--brand)"
          />
        )}
        {hasImage && !note.locked && (
          <ImageIcon size={12} className="shrink-0 text-ink-3" />
        )}
        {!note.locked && note.tags.length > 0 && (
          <span
            className="shrink-0 rounded-full px-2 py-0.5 text-[10.5px] font-bold"
            style={{ background: tint("blue", 13), color: "var(--blue)" }}
          >
            #{note.tags[0]}
          </span>
        )}
        <span className="ml-auto shrink-0 text-[11px] font-semibold text-ink-3">
          {relDate(note.updatedAt)}
        </span>
        {note.locked && <Lock size={11} className="text-ink-3" />}
      </div>
    </motion.button>
  );
}

/* --------------------------------- Screen --------------------------------- */

type SortKey = "updated" | "created" | "alpha";

export function NotesScreen() {
  const { notes, addNote, updateNote, deleteNote, verifyUnlock, toast, quick, consumeQuick } = useData();
  const [editorId, setEditorId] = useState<string | null>(null);
  const [fabOpen, setFabOpen] = useState(false);
  const [sortOpen, setSortOpen] = useState(false);
  const [sort, setSort] = useState<SortKey>("updated");
  const [view, setView] = useState<"notes" | "archived">("notes");
  const [searchOpen, setSearchOpen] = useState(false);

  // Long-press action menu + PIN gates
  const [actionNote, setActionNote] = useState<Note | null>(null);
  const [pinGate, setPinGate] = useState<{
    note: Note;
    purpose: "open" | "unlock";
  } | null>(null);
  const [pinError, setPinError] = useState<string | undefined>();
  const [pinAttempts, setPinAttempts] = useState(0);
  const [lockFor, setLockFor] = useState<Note | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Note | null>(null);

  useEffect(() => {
    if (quick?.tab === "notes") {
      if (quick.action === "search") setSearchOpen(true);
      else void createNote(quick.action === "checklist");
      consumeQuick();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [quick]);

  const visible = useMemo(() => {
    const filtered = notes.filter((n) =>
      view === "archived" ? n.archived : !n.archived,
    );
    const sorted = [...filtered].sort((a, b) => {
      if (a.pinned !== b.pinned && view === "notes") return a.pinned ? -1 : 1;
      if (sort === "alpha")
        return (a.title || "Untitled").localeCompare(b.title || "Untitled");
      const ka = new Date(sort === "created" ? a.createdAt : a.updatedAt).getTime();
      const kb = new Date(sort === "created" ? b.createdAt : b.updatedAt).getTime();
      return kb - ka;
    });
    return sorted;
  }, [notes, sort, view]);

  async function createNote(checklist = false) {
    setFabOpen(false);
    try {
      const row = await addNote({ checklist });
      setEditorId(row.id);
    } catch {
      /* toast already shown */
    }
  }

  function openNote(n: Note) {
    if (n.locked && !n.content) {
      setPinError(undefined);
      setPinGate({ note: n, purpose: "open" });
    } else {
      setEditorId(n.id);
    }
  }

  return (
    <div className="relative flex h-full flex-col">
      {/* Header */}
      <div className="flex items-center gap-2 px-5 pb-3 pt-5">
        <div className="flex-1">
          <h1 className="text-[26px] font-extrabold tracking-[-0.02em] text-ink">
            Notes
          </h1>
          <p className="text-[12.5px] font-medium text-ink-3">
            {notes.filter((n) => !n.archived).length} note
            {notes.filter((n) => !n.archived).length === 1 ? "" : "s"} ·{" "}
            {notes.filter((n) => n.pinned && !n.archived).length} pinned
          </p>
        </div>
        <HeaderBtn label="Sort notes" onClick={() => setSortOpen(true)}>
          <ArrowUpDown size={18} />
        </HeaderBtn>
        <HeaderBtn label="Search" onClick={() => setSearchOpen(true)}>
          <Search size={18} />
        </HeaderBtn>
      </div>

      {/* View chips */}
      <div className="flex gap-2 overflow-x-auto px-5 pb-3 no-scrollbar">
        {(["notes", "archived"] as const).map((v) => (
          <button
            key={v}
            type="button"
            onClick={() => {
              buzz(6);
              setView(v);
            }}
            className="shrink-0 rounded-full px-4 py-2 text-[13px] font-bold transition-all duration-200 active:scale-95"
            style={{
              background: view === v ? "var(--ink)" : "var(--surface-2)",
              color: view === v ? "var(--bg)" : "var(--ink-2)",
            }}
          >
            {v === "notes" ? "All notes" : "Archived"}
          </button>
        ))}
      </div>

      {/* Grid */}
      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-32 no-scrollbar">
        {visible.length === 0 ? (
          <EmptyState
            icon={view === "archived" ? Archive : NotebookPen}
            color="amber"
            title={view === "archived" ? "No archived notes" : "Nothing here yet"}
            sub={
              view === "archived"
                ? "Notes you archive will rest here, out of the way."
                : "Capture an idea before you forget it."
            }
            action={view === "notes" ? "Create note" : undefined}
            onAction={() => void createNote(false)}
          />
        ) : (
          <div className="columns-2 gap-3">
            <AnimatePresence mode="popLayout">
              {visible.map((n) => (
                <NoteCard key={n.id} note={n} onOpen={openNote} onMenu={setActionNote} />
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>

      {/* FAB — kept fully above the dock (see .fab in globals.css) */}
      <motion.button
        type="button"
        aria-label="Create"
        whileTap={{ scale: 0.88 }}
        onClick={() => setFabOpen(true)}
        className="fab grid h-14 w-14 place-items-center rounded-[20px] text-white"
        style={{
          background: "var(--brand)",
          boxShadow: "0 14px 30px -8px color-mix(in srgb, var(--brand) 65%, transparent)",
        }}
      >
        <Plus size={24} strokeWidth={2.6} />
      </motion.button>

      {/* FAB speed-dial */}
      <Sheet open={fabOpen} onClose={() => setFabOpen(false)} maxH="52%">
        <div className="px-5 pb-8 pt-1">
          <p className="px-2 pb-3 text-[13px] font-extrabold uppercase tracking-[0.12em] text-ink-3">
            Create
          </p>
          {[
            { label: "New note", sub: "A blank canvas for anything", icon: StickyNote, ck: false },
            { label: "New checklist", sub: "A list you can tick off", icon: ListChecks, ck: true },
          ].map((o) => (
            <button
              key={o.label}
              type="button"
              onClick={() => void createNote(o.ck)}
              className="flex w-full items-center gap-3.5 rounded-2xl p-2.5 text-left transition-colors active:bg-[var(--surface-2)]"
            >
              <div
                className="grid h-11 w-11 place-items-center rounded-2xl"
                style={{ background: tint("amber", 13), color: "var(--amber)" }}
              >
                <o.icon size={20} />
              </div>
              <div>
                <p className="text-[15px] font-bold text-ink">{o.label}</p>
                <p className="text-[12px] text-ink-3">{o.sub}</p>
              </div>
            </button>
          ))}
        </div>
      </Sheet>

      {/* Sort sheet */}
      <Sheet open={sortOpen} onClose={() => setSortOpen(false)} maxH="56%">
        <div className="px-5 pb-8 pt-1">
          <p className="px-2 pb-3 text-[13px] font-extrabold uppercase tracking-[0.12em] text-ink-3">
            Sort by
          </p>
          {(
            [
              ["updated", "Recently updated"],
              ["created", "Recently created"],
              ["alpha", "Alphabetical"],
            ] as [SortKey, string][]
          ).map(([k, label]) => (
            <button
              key={k}
              type="button"
              onClick={() => {
                buzz(6);
                setSort(k);
                setSortOpen(false);
              }}
              className="flex w-full items-center justify-between rounded-2xl px-3 py-3.5 text-left text-[15px] font-bold transition-colors active:bg-[var(--surface-2)]"
              style={{ color: sort === k ? PALETTE.violet : "var(--ink)" }}
            >
              {label}
              {sort === k && (
                <span className="h-2 w-2 rounded-full" style={{ background: "var(--brand)" }} />
              )}
            </button>
          ))}
        </div>
      </Sheet>

      {/* Search overlay */}
      <SearchOverlay open={searchOpen} onClose={() => setSearchOpen(false)} onOpen={openNote} />

      {/* Long-press action menu */}
      <Sheet open={!!actionNote} onClose={() => setActionNote(null)} maxH="80%">
        <div className="px-3.5 pb-8 pt-1">
          <p className="truncate px-2.5 pb-2 text-[15px] font-extrabold tracking-tight text-ink">
            {actionNote?.locked
              ? actionNote.title || "Untitled"
              : actionNote?.title || "Untitled"}
          </p>
          {actionNote && (
            <>
              <RowButton
                icon={Pin}
                color="violet"
                label={actionNote.pinned ? "Unpin note" : "Pin note"}
                sub="Pinned notes stay on top"
                onClick={() => {
                  void updateNote(actionNote.id, { pinned: !actionNote.pinned });
                  setActionNote(null);
                }}
              />
              <RowButton
                icon={actionNote.locked ? LockOpen : Lock}
                color="pink"
                label={actionNote.locked ? "Unlock note" : "Lock with PIN"}
                sub={
                  actionNote.locked
                    ? "Enter the PIN to remove protection"
                    : "Hide this note's content behind a PIN"
                }
                onClick={() => {
                  const n = actionNote;
                  setActionNote(null);
                  if (n.locked) {
                    setPinError(undefined);
                    setPinGate({ note: n, purpose: "unlock" });
                  } else {
                    setLockFor(n);
                  }
                }}
              />
              <RowButton
                icon={actionNote.archived ? ArchiveRestore : Archive}
                color="teal"
                label={actionNote.archived ? "Restore note" : "Archive note"}
                sub={
                  actionNote.archived
                    ? "Bring it back to your grid"
                    : "Hide it from your notes grid"
                }
                onClick={() => {
                  void updateNote(actionNote.id, {
                    archived: !actionNote.archived,
                  }).then(() =>
                    toast(actionNote.archived ? "Note restored" : "Note archived"),
                  );
                  setActionNote(null);
                }}
              />
              <RowButton
                icon={Trash2}
                danger
                label="Delete note"
                sub="This can't be undone"
                onClick={() => {
                  const n = actionNote;
                  setActionNote(null);
                  setConfirmDelete(n);
                }}
              />
            </>
          )}
        </div>
      </Sheet>

      {/* PIN gate — open or unlock. Every failed attempt resets the input
          automatically (via resetKey) so a fresh PIN can be typed at once. */}
      <Sheet open={!!pinGate} onClose={() => setPinGate(null)} maxH="86%">
        {pinGate && (
          <PinPad
            title={pinGate.purpose === "open" ? "Enter PIN" : "Enter PIN to unlock"}
            sub={pinGate.note.title || "This note is private"}
            error={pinError}
            resetKey={pinAttempts}
            onCancel={() => setPinGate(null)}
            onComplete={async (pin) => {
              const gate = pinGate;
              const ok = await verifyUnlock(gate.note.id, pin);
              if (ok) {
                setPinGate(null);
                setPinError(undefined);
                if (gate.purpose === "open") setEditorId(gate.note.id);
                else {
                  await updateNote(gate.note.id, { lock: false });
                  toast("Note unlocked");
                }
              } else {
                // Keep the dialog open, show the error, and clear the input.
                setPinError("Incorrect PIN. Try again.");
                setPinAttempts((a) => a + 1);
              }
            }}
          />
        )}
      </Sheet>

      {/* Create a PIN (locking an open note from the action menu) */}
      <Sheet open={!!lockFor} onClose={() => setLockFor(null)} maxH="86%">
        {lockFor && (
          <PinPad
            title="Create a PIN"
            sub="4 digits — needed to open this note"
            onCancel={() => setLockFor(null)}
            onComplete={(pin) => {
              void updateNote(lockFor.id, { lock: true, pin }).then(() => {
                toast("Note locked");
                setLockFor(null);
              });
            }}
          />
        )}
      </Sheet>

      <ConfirmSheet
        open={!!confirmDelete}
        onClose={() => setConfirmDelete(null)}
        title="Delete this note?"
        sub={confirmDelete ? `"${confirmDelete.title || "Untitled"}" will be permanently removed.` : ""}
        onConfirm={() => confirmDelete && void deleteNote(confirmDelete.id)}
      />

      {/* Editor */}
      <NoteEditor noteId={editorId} onClose={() => setEditorId(null)} />
    </div>
  );
}

function HeaderBtn({
  children,
  onClick,
  label,
}: {
  children: React.ReactNode;
  onClick: () => void;
  label: string;
}) {
  return (
    <button
      type="button"
      aria-label={label}
      onClick={() => {
        buzz(6);
        onClick();
      }}
      className="grid h-10 w-10 place-items-center rounded-2xl border border-line bg-surface text-ink-2 transition-transform active:scale-92"
    >
      {children}
    </button>
  );
}

/* ---------------------------- Search overlay ------------------------------ */

function SearchOverlay({
  open,
  onClose,
  onOpen,
}: {
  open: boolean;
  onClose: () => void;
  onOpen: (n: Note) => void;
}) {
  const { notes } = useData();
  const [q, setQ] = useState("");
  const [filter, setFilter] = useState<string>("all");

  const allTags = useMemo(() => {
    const s = new Set<string>();
    notes.forEach((n) => !n.locked && n.tags.forEach((t) => s.add(t)));
    return [...s];
  }, [notes]);

  const results = useMemo(() => {
    const query = q.trim().toLowerCase();
    return notes.filter((n) => {
      if (n.archived) return false;
      if (filter === "pinned" && !n.pinned) return false;
      if (filter === "locked" && !n.locked) return false;
      if (filter.startsWith("#") && !n.tags.includes(filter.slice(1))) return false;
      if (!query) return true;
      // Private bodies never participate in search; their titles may match.
      return (
        n.title.toLowerCase().includes(query) ||
        (!n.locked && excerpt(n.content, 1000).toLowerCase().includes(query)) ||
        (!n.locked && n.tags.some((t) => t.toLowerCase().includes(query)))
      );
    });
  }, [notes, q, filter]);

  return (
    <Overlay show={open}>
      <div className="flex items-center gap-2 px-4 pb-2 pt-4">
        <div className="flex flex-1 items-center gap-2 rounded-2xl border border-line bg-surface px-3.5">
          <Search size={17} className="text-ink-3" />
          <input
            autoFocus
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Search notes, tags, content…"
            className="h-11 flex-1 bg-transparent text-[14.5px] font-semibold text-ink outline-none placeholder:text-ink-3"
          />
          {q && (
            <button type="button" aria-label="Clear" onClick={() => setQ("")}>
              <X size={16} className="text-ink-3" />
            </button>
          )}
        </div>
        <button
          type="button"
          onClick={() => {
            buzz(6);
            onClose();
          }}
          className="px-2 text-[14px] font-bold text-brand"
        >
          Cancel
        </button>
      </div>
      <div className="flex gap-2 overflow-x-auto px-5 pb-2 pt-1 no-scrollbar">
        {["all", "pinned", "locked", ...allTags.map((t) => `#${t}`)].map((f) => (
          <button
            key={f}
            type="button"
            onClick={() => {
              buzz(5);
              setFilter(f);
            }}
            className="shrink-0 rounded-full px-3.5 py-1.5 text-[12.5px] font-bold transition-all active:scale-95"
            style={{
              background: filter === f ? "var(--ink)" : "var(--surface-2)",
              color: filter === f ? "var(--bg)" : "var(--ink-2)",
            }}
          >
            {f === "all" ? "All" : f === "pinned" ? "Pinned" : f === "locked" ? "Locked" : f}
          </button>
        ))}
      </div>
      <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-10 no-scrollbar">
        {results.length === 0 ? (
          <EmptyState
            icon={Search}
            color="amber"
            title="No matches"
            sub="Try a different word, or widen your filters."
          />
        ) : (
          results.map((n) => (
            <button
              key={n.id}
              type="button"
              onClick={() => {
                onOpen(n);
                onClose();
              }}
              className="mb-2 flex w-full items-stretch overflow-hidden rounded-2xl border border-line bg-surface text-left transition-transform active:scale-[0.985]"
            >
              <span
                className="w-1.5 shrink-0"
                style={{ background: noteColor(n.color), filter: "saturate(1.4) brightness(0.92)" }}
              />
              <span className="min-w-0 flex-1 px-3.5 py-3">
                <span className="flex items-center gap-1.5">
                  {n.locked && <Lock size={12} className="text-ink-3" />}
                  {n.pinned && !n.locked && (
                    <Pin size={11} className="rotate-45" style={{ color: "var(--brand)" }} fill="var(--brand)" />
                  )}
                  <span className="truncate text-[14px] font-bold text-ink">
                    {n.title || "Untitled"}
                  </span>
                </span>
                <span className="mt-0.5 block truncate text-[12px] text-ink-3">
                  {n.locked
                    ? "Private note — body protected"
                    : excerpt(n.content, 80) || "No content yet"}
                </span>
              </span>
            </button>
          ))
        )}
      </div>
    </Overlay>
  );
}
