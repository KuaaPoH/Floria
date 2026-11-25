/** Only allow same-origin relative redirects after sign-in. */
export function safeRedirect(target: string | undefined, fallback = "/dashboard") {
  if (!target || !target.startsWith("/") || target.startsWith("//")) return fallback;
  if (["/login", "/register", "/forgot-password"].some((p) => target.startsWith(p))) return fallback;
  return target;
}
