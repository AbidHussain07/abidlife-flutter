"use client";

import { format, parseISO } from "date-fns";
import {
  AlignCenter,
  AlignLeft,
  AlignRight,
  Archive,
  ArchiveRestore,
  Bold,
  Camera,
  ChevronLeft,
  Hash,
  Image as GalleryIcon,
  ImagePlus,
  Italic,
  List,
  ListChecks,
  ListOrdered,
  Lock,
  LockOpen,
  MoreHorizontal,
  Pin,
  Trash2,
  Type,
  X,
} from "lucide-react";
import { useCallback, useEffect, useRef, useState } from "react";
import { useData } from "../data";
import {
  buzz,
  ConfirmSheet,
  NOTE_COLORS,
  noteColor,
  Overlay,
  PinPad,
  RowButton,
  Sheet,
  tint,
} from "../ui";

/** Downscale a picked image so notes stay light: max side 1280px, JPEG 0.82. */
async function fileToDataURL(file: File): Promise<string> {
  const MAX = 1280;
  let bitmap: ImageBitmap;
  try {
    bitmap = await createImageBitmap(file);
  } catch {
    bitmap = await new Promise<ImageBitmap>((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        resolve(img as any);
      };
      img.onerror = reject;
      img.src = URL.createObjectURL(file);
    });
  }
  const scale = Math.min(1, MAX / Math.max(bitmap.width, bitmap.height));
  const w = Math.max(1, Math.round(bitmap.width * scale));
  const h = Math.max(1, Math.round(bitmap.height * scale));
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("canvas unavailable");
  ctx.drawImage(bitmap, 0, 0, w, h);
  if ("close" in bitmap) bitmap.close();
  return canvas.toDataURL("image/jpeg", 0.82);
}

export function NoteEditor({
  noteId,
  onClose,
}: {
  noteId: string | null;
  onClose: () => void;
}) {
  const { notes, updateNote, deleteNote, toast } = useData();
  const note = notes.find((n) => n.id === noteId);

  const titleRef = useRef<HTMLInputElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  const saveTimer = useRef<number | undefined>(undefined);
  const [status, setStatus] = useState<"saved" | "saving">("saved");
  const [moreOpen, setMoreOpen] = useState(false);
  const [colorsOpen, setColorsOpen] = useState(false);
  const [tagsOpen, setTagsOpen] = useState(false);
  const [tagInput, setTagInput] = useState("");
  const [lockOpen, setLockOpen] = useState(false);
  const [confirmDel, setConfirmDel] = useState(false);
  const [imageMenuOpen, setImageMenuOpen] = useState(false);
  const galleryInputRef = useRef<HTMLInputElement>(null);
  const cameraInputRef = useRef<HTMLInputElement>(null);
  const [tick, setTick] = useState(0); // forces re-render of header state

  const persist = useCallback(
    (immediate = false) => {
      if (!noteId || !titleRef.current || !bodyRef.current) return;
      const payload = {
        title: titleRef.current.value,
        content: bodyRef.current.innerHTML,
      };
      window.clearTimeout(saveTimer.current);
      setStatus("saving");
      const run = () => {
        void updateNote(noteId, payload).then(() => setStatus("saved"));
      };
      if (immediate) run();
      else saveTimer.current = window.setTimeout(run, 700);
    },
    [noteId, updateNote],
  );

  // Initialise content once per opened note
  useEffect(() => {
    if (!noteId || !note) return;
    window.clearTimeout(saveTimer.current);
    if (titleRef.current) titleRef.current.value = note.title;
    if (bodyRef.current) {
      bodyRef.current.innerHTML =
        note.content ||
        (note.checklist
          ? '<ul class="check"><li>First item</li></ul><p></p>'
          : "<p><br></p>");
    }
    setStatus("saved");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [noteId]);

  // Checklist toggling: clicks near the checkbox area toggle completion
  useEffect(() => {
    const el = bodyRef.current;
    if (!el || !noteId) return;
    const handler = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const li = target.closest("li");
      const ul = target.closest("ul.check");
      if (!li || !ul) return;
      const rect = li.getBoundingClientRect();
      if (e.clientX - rect.left > 34) return; // only the checkbox zone
      e.preventDefault();
      li.classList.toggle("done");
      buzz(8);
      setTick((t) => t + 1);
      persist();
    };
    el.addEventListener("click", handler);
    return () => el.removeEventListener("click", handler);
  }, [noteId, persist]);

  const close = () => {
    persist(true);
    onClose();
  };

  const cmd = (command: string, value?: string) => {
    buzz(5);
    bodyRef.current?.focus();
    document.execCommand(command, false, value);
    persist();
    setTick((t) => t + 1);
  };

  const insertImageFile = async (file: File | null | undefined) => {
    if (!file) return;
    try {
      const url = await fileToDataURL(file);
      bodyRef.current?.focus();
      document.execCommand("insertImage", false, url);
      persist(true);
      toast("Image added");
    } catch {
      toast("Couldn't add this image. Try another one.");
    }
  };

  if (!note) {
    return <Overlay show={false}>{null}</Overlay>;
  }

  const tools: { label: string; icon: React.ElementType; onPress: () => void }[] = [
    { label: "Bold", icon: Bold, onPress: () => cmd("bold") },
    { label: "Italic", icon: Italic, onPress: () => cmd("italic") },
    { label: "Heading", icon: Type, onPress: () => cmd("formatBlock", "h2") },
    { label: "Bulleted list", icon: List, onPress: () => cmd("insertUnorderedList") },
    { label: "Numbered list", icon: ListOrdered, onPress: () => cmd("insertOrderedList") },
    {
      label: "Checklist",
      icon: ListChecks,
      onPress: () =>
        cmd("insertHTML", '<ul class="check"><li>New item</li></ul><p></p>'),
    },
    {
      label: "Add image",
      icon: ImagePlus,
      onPress: () => setImageMenuOpen(true),
    },
    { label: "Align left", icon: AlignLeft, onPress: () => cmd("justifyLeft") },
    { label: "Align center", icon: AlignCenter, onPress: () => cmd("justifyCenter") },
    { label: "Align right", icon: AlignRight, onPress: () => cmd("justifyRight") },
  ];

  return (
    <Overlay show={!!noteId}>
      <div
        className="flex h-full flex-col transition-colors duration-300"
        style={{ background: noteColor(note.color) }}
      >
        {/* Header */}
        <div className="flex items-center gap-1 px-3 pb-1 pt-3">
          <button
            type="button"
            aria-label="Back"
            onClick={close}
            className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 transition-colors active:bg-black/5"
          >
            <ChevronLeft size={22} />
          </button>
          <div className="flex-1 text-center">
            <span className="inline-flex items-center gap-1.5 text-[11.5px] font-bold uppercase tracking-[0.12em] text-ink-3">
              <span
                className="h-1.5 w-1.5 rounded-full transition-colors"
                style={{
                  background: status === "saved" ? "var(--green)" : "var(--amber)",
                }}
              />
              {status === "saved" ? "Saved" : "Saving…"}
            </span>
          </div>
          <button
            type="button"
            aria-label={note.pinned ? "Unpin" : "Pin"}
            onClick={() => {
              buzz(6);
              void updateNote(note.id, { pinned: !note.pinned });
            }}
            className="grid h-10 w-10 place-items-center rounded-2xl transition-colors active:bg-black/5"
            style={{ color: note.pinned ? "var(--brand)" : "var(--ink-3)" }}
          >
            <Pin size={19} className={note.pinned ? "rotate-45" : ""} fill={note.pinned ? "currentColor" : "none"} />
          </button>
          <button
            type="button"
            aria-label="More options"
            onClick={() => setMoreOpen(true)}
            className="grid h-10 w-10 place-items-center rounded-2xl text-ink-2 transition-colors active:bg-black/5"
          >
            <MoreHorizontal size={20} />
          </button>
        </div>

        {/* Toolbar */}
        <div className="flex gap-1 overflow-x-auto px-4 pb-2 pt-1 no-scrollbar" data-tick={tick}>
          {tools.map((t) => (
            <button
              key={t.label}
              type="button"
              aria-label={t.label}
              onMouseDown={(e) => e.preventDefault()}
              onClick={t.onPress}
              className="grid h-9 w-9 shrink-0 place-items-center rounded-xl text-ink-2 transition-all active:scale-90 active:bg-black/8"
            >
              <t.icon size={17} strokeWidth={2.2} />
            </button>
          ))}
        </div>

        {/* Content */}
        <div className="min-h-0 flex-1 overflow-y-auto px-5 pb-16 no-scrollbar">
          <input
            ref={titleRef}
            defaultValue={note.title}
            onChange={() => persist()}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                e.preventDefault();
                bodyRef.current?.focus();
              }
            }}
            placeholder="Title"
            className="w-full bg-transparent py-2 text-[22px] font-extrabold tracking-[-0.015em] text-ink outline-none placeholder:text-ink-3"
          />
          <div
            ref={bodyRef}
            contentEditable
            suppressContentEditableWarning
            role="textbox"
            aria-multiline
            aria-label="Note content"
            onInput={() => persist()}
            className="note-body min-h-[55vh] w-full outline-none"
            style={{ fontSize: 15, lineHeight: 1.75, color: "var(--ink-2)" }}
          />
          <p className="mt-6 text-[11px] font-semibold text-ink-3">
            Edited {format(parseISO(note.updatedAt), "d MMM, h:mm a")}
          </p>
        </div>
      </div>

      {/* More sheet */}
      <Sheet open={moreOpen} onClose={() => setMoreOpen(false)} maxH="80%">
        <div className="overflow-y-auto px-3.5 pb-8 pt-1 no-scrollbar">
          <RowButton
            icon={note.pinned ? Pin : Pin}
            color="violet"
            label={note.pinned ? "Unpin note" : "Pin note"}
            sub="Pinned notes stay on top"
            onClick={() => {
              setMoreOpen(false);
              void updateNote(note.id, { pinned: !note.pinned });
            }}
          />
          <RowButton
            icon={Hash}
            color="blue"
            label="Tags"
            sub={note.tags.length ? note.tags.map((t) => `#${t}`).join("  ") : "Add tags to organize"}
            onClick={() => {
              setMoreOpen(false);
              setTagsOpen(true);
            }}
          />
          <div className="px-2.5 pb-2 pt-3">
            <p className="pb-2.5 text-[12px] font-extrabold uppercase tracking-[0.12em] text-ink-3">
              Color
            </p>
            <div className="flex flex-wrap gap-2.5">
              {NOTE_COLORS.map((c) => (
                <button
                  key={c}
                  type="button"
                  aria-label={`Note color ${c}`}
                  onClick={() => {
                    buzz(6);
                    void updateNote(note.id, { color: c });
                  }}
                  className="h-9 w-9 rounded-full border border-line transition-transform active:scale-90"
                  style={{
                    background: noteColor(c),
                    boxShadow:
                      note.color === c
                        ? "0 0 0 2px var(--bg), 0 0 0 4.5px var(--brand)"
                        : "none",
                  }}
                />
              ))}
            </div>
          </div>
          <RowButton
            icon={note.locked ? LockOpen : Lock}
            color="pink"
            label={note.locked ? "Remove lock" : "Lock with PIN"}
            sub={note.locked ? "Anyone can open this note" : "Hide this note behind a PIN"}
            onClick={() => {
              setMoreOpen(false);
              if (note.locked) {
                void updateNote(note.id, { lock: false }).then(() =>
                  toast("Lock removed"),
                );
              } else {
                setLockOpen(true);
              }
            }}
          />
          <RowButton
            icon={note.archived ? ArchiveRestore : Archive}
            color="teal"
            label={note.archived ? "Restore note" : "Archive note"}
            sub="Archived notes hide from your grid"
            onClick={() => {
              setMoreOpen(false);
              void updateNote(note.id, { archived: !note.archived }).then(() => {
                toast(note.archived ? "Note restored" : "Note archived");
                if (!note.archived) close();
              });
            }}
          />
          <RowButton
            icon={Trash2}
            danger
            label="Delete note"
            sub="This can't be undone"
            onClick={() => {
              setMoreOpen(false);
              setConfirmDel(true);
            }}
          />
        </div>
      </Sheet>

      {/* Tags sheet */}
      <Sheet open={tagsOpen} onClose={() => setTagsOpen(false)} maxH="62%">
        <div className="px-5 pb-8 pt-1">
          <p className="pb-3 text-[15px] font-extrabold tracking-tight text-ink">
            Tags
          </p>
          <div className="flex flex-wrap gap-2">
            {note.tags.map((t) => (
              <span
                key={t}
                className="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-[12.5px] font-bold"
                style={{ background: tint("blue", 13), color: "var(--blue)" }}
              >
                #{t}
                <button
                  type="button"
                  aria-label={`Remove tag ${t}`}
                  onClick={() =>
                    void updateNote(note.id, {
                      tags: note.tags.filter((x) => x !== t),
                    })
                  }
                >
                  <X size={13} />
                </button>
              </span>
            ))}
            {note.tags.length === 0 && (
              <p className="text-[13px] text-ink-3">No tags yet.</p>
            )}
          </div>
          <div className="mt-4 flex items-center gap-2 rounded-2xl border border-line bg-surface-2 px-3.5">
            <Hash size={16} className="text-ink-3" />
            <input
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value.replace(/\s/g, ""))}
              onKeyDown={(e) => {
                if (e.key !== "Enter") return;
                const t = tagInput.trim().toLowerCase();
                if (!t) return;
                if (!note.tags.includes(t))
                  void updateNote(note.id, { tags: [...note.tags, t] });
                setTagInput("");
              }}
              placeholder="Add a tag and press enter"
              className="h-11 flex-1 bg-transparent text-[14px] font-semibold text-ink outline-none placeholder:text-ink-3"
            />
          </div>
        </div>
      </Sheet>

      {/* Lock sheet */}
      <Sheet open={lockOpen} onClose={() => setLockOpen(false)} maxH="86%">
        <PinPad
          title="Create a PIN"
          sub="4 digits — needed to open this note"
          onCancel={() => setLockOpen(false)}
          onComplete={(pin) => {
            void updateNote(note.id, { lock: true, pin }).then(() => {
              toast("Note locked");
              setLockOpen(false);
              close();
            });
          }}
        />
      </Sheet>

      {/* Image source: gallery or camera. Selection is downscaled client-side
          before being embedded and autosaved with the note. */}
      <Sheet open={imageMenuOpen} onClose={() => setImageMenuOpen(false)} maxH="52%">
        <div className="px-3.5 pb-8 pt-1">
          <p className="px-2.5 pb-2 text-[15px] font-extrabold tracking-tight text-ink">
            Add an image
          </p>
          <RowButton
            icon={GalleryIcon}
            color="blue"
            label="Choose from gallery"
            sub="Pick an existing photo"
            onClick={() => {
              setImageMenuOpen(false);
              galleryInputRef.current?.click();
            }}
          />
          <RowButton
            icon={Camera}
            color="teal"
            label="Take a photo"
            sub="Opens the camera on mobile"
            onClick={() => {
              setImageMenuOpen(false);
              cameraInputRef.current?.click();
            }}
          />
        </div>
      </Sheet>
      <input
        ref={galleryInputRef}
        type="file"
        accept="image/*"
        className="hidden"
        aria-hidden
        tabIndex={-1}
        onChange={(e) => {
          void insertImageFile(e.target.files?.[0]);
          e.target.value = "";
        }}
      />
      <input
        ref={cameraInputRef}
        type="file"
        accept="image/*"
        capture="environment"
        className="hidden"
        aria-hidden
        tabIndex={-1}
        onChange={(e) => {
          void insertImageFile(e.target.files?.[0]);
          e.target.value = "";
        }}
      />

      {/* Colors pop (unused visually, kept for parity) */}
      <Sheet open={colorsOpen} onClose={() => setColorsOpen(false)} maxH="40%">
        <div className="px-5 pb-8" />
      </Sheet>

      <ConfirmSheet
        open={confirmDel}
        onClose={() => setConfirmDel(false)}
        title="Delete this note?"
        sub={`"${note.title || "Untitled"}" will be permanently removed.`}
        onConfirm={() => {
          void deleteNote(note.id);
          close();
        }}
      />
    </Overlay>
  );
}
