"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";

export type ThemeMode = "system" | "light" | "dark";

const ThemeCtx = createContext<{
  mode: ThemeMode;
  resolved: "light" | "dark";
  setMode: (m: ThemeMode) => void;
}>({ mode: "system", resolved: "dark", setMode: () => {} });

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [mode, setModeState] = useState<ThemeMode>("system");
  const [system, setSystem] = useState<"light" | "dark">("dark");

  useEffect(() => {
    const saved = window.localStorage.getItem("abidlife.theme");
    if (saved === "light" || saved === "dark" || saved === "system")
      setModeState(saved);
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const apply = () => setSystem(mq.matches ? "dark" : "light");
    apply();
    mq.addEventListener("change", apply);
    return () => mq.removeEventListener("change", apply);
  }, []);

  const setMode = useCallback((m: ThemeMode) => {
    setModeState(m);
    window.localStorage.setItem("abidlife.theme", m);
  }, []);

  const resolved = mode === "system" ? system : mode;
  const value = useMemo(
    () => ({ mode, resolved, setMode }),
    [mode, resolved, setMode],
  );
  return <ThemeCtx.Provider value={value}>{children}</ThemeCtx.Provider>;
}

export const useTheme = () => useContext(ThemeCtx);
