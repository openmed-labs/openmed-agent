(function () {
  const STORAGE_KEY = "openmed-theme";

  function getStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch {
      return null;
    }
  }

  function setStoredTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      // Ignore storage failures.
    }
  }

  function getSystemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function resolveTheme() {
    return getStoredTheme() || getSystemTheme();
  }

  function applySiteTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
      const nextAction = theme === "dark" ? "Switch to light theme" : "Switch to dark theme";
      button.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
      button.setAttribute("aria-label", nextAction);
      button.dataset.theme = theme;
      button.removeAttribute("title");
    });
  }

  function initCopyButtons() {
    document.querySelectorAll("[data-copy-text]").forEach((button) => {
      if (button.dataset.copyBound === "true") {
        return;
      }

      button.dataset.copyBound = "true";
      const idleLabel = button.getAttribute("data-copy-label") || "Copy command";
      button.setAttribute("aria-label", idleLabel);
      button.title = idleLabel;

      button.addEventListener("click", async () => {
        const text = button.getAttribute("data-copy-text") || "";
        const label = button.querySelector(".om-copy-btn__label");

        try {
          await navigator.clipboard.writeText(text);
          button.dataset.copyState = "copied";
          button.setAttribute("aria-label", "Copied to clipboard");
          button.title = "Copied to clipboard";
          if (label) {
            label.textContent = "Copied to clipboard";
          }
          window.setTimeout(() => {
            button.dataset.copyState = "";
            button.setAttribute("aria-label", idleLabel);
            button.title = idleLabel;
            if (label) {
              label.textContent = idleLabel;
            }
          }, 1400);
        } catch {
          button.dataset.copyState = "";
          button.setAttribute("aria-label", idleLabel);
          button.title = idleLabel;
        }
      });
    });
  }

  function initThemeToggle() {
    document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
      if (button.dataset.themeBound === "true") {
        return;
      }

      button.dataset.themeBound = "true";
      button.addEventListener("click", () => {
        const nextTheme = resolveTheme() === "dark" ? "light" : "dark";
        setStoredTheme(nextTheme);
        applySiteTheme(nextTheme);
      });
    });
  }

  function boot() {
    applySiteTheme(resolveTheme());
    initThemeToggle();
    initCopyButtons();
    initTerminalLoop();
  }

  /* Hero terminal: after the initial CSS reveal, keep the session "live" —
     retype the operator prompt character by character, then replay the plan,
     tool traces, and review line on a loop, like a real streaming terminal.
     Without JS the one-shot CSS animation still runs; with reduced motion
     everything stays static. */
  function initTerminalLoop() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return;
    }
    var body = document.querySelector(".om-term__body");
    if (!body || body.dataset.loopBound === "true") {
      return;
    }
    body.dataset.loopBound = "true";

    var lines = Array.prototype.slice.call(body.querySelectorAll(".om-tline"));
    if (lines.length < 2) {
      return;
    }
    var promptSpan = lines[0].querySelector(".om-t-fg");
    var promptText = promptSpan ? promptSpan.textContent : "";
    if (!promptSpan || !promptText) {
      return;
    }

    var TYPE_MS = 24; /* per character */
    var STAGGER_MS = 220; /* between replayed lines */
    var PLAN_PAUSE_MS = 480; /* extra beat while the "plan" renders */
    var HOLD_MS = 4500; /* linger on the finished session */
    var INITIAL_CSS_RUN_MS = 2600; /* let the one-shot CSS pass finish first */

    function hideLine(line) {
      line.style.animation = "none";
      line.style.opacity = "0";
    }

    function playLine(line) {
      // Re-trigger the stylesheet animation (om-tfade, and om-blink on the
      // cursor) from a clean slate, ignoring the original inline delay.
      line.style.animation = "none";
      line.style.animationDelay = "0s";
      void line.offsetWidth;
      line.style.animation = "";
      line.style.opacity = "";
    }

    function cycle() {
      lines.forEach(hideLine);
      promptSpan.textContent = "";
      lines[0].style.opacity = "1";

      var chars = 0;
      var typer = window.setInterval(function () {
        chars += 1;
        promptSpan.textContent = promptText.slice(0, chars);
        if (chars < promptText.length) {
          return;
        }
        window.clearInterval(typer);
        var delay = 320;
        lines.slice(1).forEach(function (line, index) {
          window.setTimeout(function () {
            playLine(line);
          }, delay);
          delay += STAGGER_MS + (index === 0 ? PLAN_PAUSE_MS : 0);
        });
        window.setTimeout(cycle, delay + HOLD_MS);
      }, TYPE_MS);
    }

    window.setTimeout(cycle, INITIAL_CSS_RUN_MS + HOLD_MS);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
