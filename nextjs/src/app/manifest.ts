import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "LifeDeck — Notes, Tasks, Habits & Money",
    short_name: "LifeDeck",
    description:
      "Everything you need, in one place. A calm home for your notes, tasks, habits and money.",
    start_url: "/",
    display: "standalone",
    background_color: "#0a0c11",
    theme_color: "#0a0c11",
    icons: [
      {
        src: "/icon.svg",
        sizes: "any",
        type: "image/svg+xml",
        purpose: "any",
      },
    ],
  };
}
