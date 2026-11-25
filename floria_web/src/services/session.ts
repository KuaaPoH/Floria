/** Mock session pointer (uid of the signed-in mock user). Firebase manages its own session in api mode. */
const KEY = "floria:session";

export const session = {
  get(): string | null {
    if (typeof window === "undefined") return null;
    return window.localStorage.getItem(KEY) ?? window.sessionStorage.getItem(KEY);
  },
  set(uid: string, remember: boolean) {
    if (remember) window.localStorage.setItem(KEY, uid);
    else window.sessionStorage.setItem(KEY, uid);
  },
  clear() {
    window.localStorage.removeItem(KEY);
    window.sessionStorage.removeItem(KEY);
  },
};
