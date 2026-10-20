// Chiroptera live recolor for Spotify: `spicetify refresh` rewrites colors.css and
// user.css in place when the palette changes; this swaps them into the open window,
// so Spotify recolors without a restart and keeps playing.
(function chiropteraLive() {
  let last = null;
  async function check() {
    try {
      const res = await fetch("colors.css", { cache: "no-store" });
      const css = await res.text();
      if (last !== null && css !== last) {
        for (const link of document.querySelectorAll("link[rel=stylesheet]")) {
          const name = link.getAttribute("href").split("?")[0];
          if (name === "colors.css" || name === "user.css") link.href = `${name}?t=${Date.now()}`;
        }
      }
      last = css;
    } catch (_) {}
  }
  check();
  setInterval(check, 2000);
})();
