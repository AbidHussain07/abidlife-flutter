/**
 * Local reminder delivery.
 * Permission is requested lazily (only when the user actually enables a
 * reminder, which is a user gesture) and every firing is a real system
 * Notification API notification with the task title. Timers are re-armed
 * whenever the task list changes, so edits/deletes never leave stale or
 * duplicate schedules.
 */
export async function ensureNotificationPermission(): Promise<boolean> {
  if (typeof window === "undefined" || !("Notification" in window))
    return false;
  if (Notification.permission === "granted") return true;
  if (Notification.permission === "denied") return false;
  try {
    return (await Notification.requestPermission()) === "granted";
  } catch {
    return false;
  }
}

export function fireTaskReminder(title: string) {
  if (typeof window === "undefined" || !("Notification" in window)) return;
  if (Notification.permission !== "granted") return;
  try {
    new Notification("LifeDeck reminder", {
      body: title,
      icon: "/icon.svg",
      badge: "/icon.svg",
      tag: "abidlife-reminder",
    });
  } catch {
    /* unsupported construction on some mobile browsers — no-op */
  }
}
