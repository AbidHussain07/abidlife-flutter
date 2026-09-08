/** ABIDLIFE brand mark — a bold "A" crowned with a small minimal crown. */
export function LumaLogo({ size = 30 }: { size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 48 48"
      fill="none"
      aria-label="LifeDeck logo"
    >
      <rect width="48" height="48" rx="13" fill="url(#abid-g)" />
      {/* crown */}
      <path
        d="M17.6 14.4 L19.2 9.1 L22 11.8 L24 7.2 L26 11.8 L28.8 9.1 L30.4 14.4 Z"
        fill="white"
      />
      <rect x="17.6" y="15.2" width="12.8" height="2.1" rx="1.05" fill="white" />
      {/* letter A */}
      <path
        d="M15 37 L24 19 L33 37"
        stroke="white"
        strokeWidth="4.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M19.1 30.6 H28.9"
        stroke="white"
        strokeWidth="3.9"
        strokeLinecap="round"
      />
      <defs>
        <linearGradient
          id="abid-g"
          x1="0"
          y1="0"
          x2="48"
          y2="48"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#8B7CFF" />
          <stop offset="0.55" stopColor="#6E5BFF" />
          <stop offset="1" stopColor="#462BE0" />
        </linearGradient>
      </defs>
    </svg>
  );
}
