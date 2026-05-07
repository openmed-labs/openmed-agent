(function () {
  const STORAGE_KEY = "openmed-theme";
  let docsTocCleanup = null;

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
      // Ignore private-mode/localStorage failures.
    }
  }

  function getSystemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function repairBrokenMaterialPalette() {
    try {
      const scope = new URL(".", location).pathname;
      const key = scope + ".__palette";
      const raw = localStorage.getItem(key);
      if (!raw) {
        return false;
      }

      const palette = JSON.parse(raw);
      if (!palette || typeof palette !== "object" || !palette.color || typeof palette.index === "number") {
        return false;
      }

      const repaired = {
        index: palette.color.scheme === "slate" ? 1 : 0,
        color: palette.color,
      };
      localStorage.setItem(key, JSON.stringify(repaired));

      const marker = scope + ".__palette-repaired";
      if (sessionStorage.getItem(marker) !== "true") {
        sessionStorage.setItem(marker, "true");
        location.reload();
        return true;
      }
    } catch {
      // Ignore storage failures.
    }

    return false;
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

  function syncMaterialPalette(theme) {
    const body = document.body;
    if (!body || !body.hasAttribute("data-md-color-scheme")) {
      return;
    }

    const scheme = theme === "dark" ? "slate" : "default";
    const input = document.querySelector('[data-md-component="palette"] input[data-md-color-scheme="' + scheme + '"]');
    if (input) {
      const inputs = Array.from(document.querySelectorAll('[data-md-component="palette"] input[data-md-color-scheme]'));
      const index = inputs.indexOf(input);
      input.checked = true;
      body.setAttribute("data-md-color-scheme", input.getAttribute("data-md-color-scheme"));
      body.setAttribute("data-md-color-primary", input.getAttribute("data-md-color-primary") || "black");
      body.setAttribute("data-md-color-accent", input.getAttribute("data-md-color-accent") || "deep-orange");
      try {
        const palette = {
          index: index >= 0 ? index : theme === "dark" ? 1 : 0,
          color: {
            media: input.getAttribute("data-md-color-media") || "(prefers-color-scheme: light)",
            scheme: input.getAttribute("data-md-color-scheme"),
            primary: input.getAttribute("data-md-color-primary") || "black",
            accent: input.getAttribute("data-md-color-accent") || "deep-orange",
          },
        };
        if (typeof window.__md_set === "function") {
          window.__md_set("__palette", palette);
        } else {
          const scope = new URL(".", location).pathname;
          localStorage.setItem(scope + ".__palette", JSON.stringify(palette));
        }
      } catch {
        // Ignore localStorage failures.
      }
    }
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
        syncMaterialPalette(nextTheme);
      });
    });
  }

  function ensureDocsThemeToggle() {
    const body = document.body;
    const headerInner = document.querySelector(".md-header__inner");
    if (!body || !body.hasAttribute("data-md-color-scheme") || !headerInner) {
      return;
    }

    let button = headerInner.querySelector("[data-docs-theme-toggle]");
    if (!button) {
      button = document.createElement("button");
      button.type = "button";
      button.className = "om-theme-toggle om-theme-toggle--docs";
      button.setAttribute("data-theme-toggle", "");
      button.setAttribute("data-docs-theme-toggle", "");
      button.innerHTML = `
        <span class="om-theme-toggle__icon om-theme-toggle__icon--sun" aria-hidden="true">
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" xmlns="http://www.w3.org/2000/svg">
            <path d="M8 1.11133V2.00022" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M12.8711 3.12891L12.2427 3.75735" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M14.8889 8H14" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M12.8711 12.8711L12.2427 12.2427" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M8 14.8889V14" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M3.12891 12.8711L3.75735 12.2427" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M1.11133 8H2.00022" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M3.12891 3.12891L3.75735 3.75735" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
            <path d="M8.00043 11.7782C10.0868 11.7782 11.7782 10.0868 11.7782 8.00043C11.7782 5.91402 10.0868 4.22266 8.00043 4.22266C5.91402 4.22266 4.22266 5.91402 4.22266 8.00043C4.22266 10.0868 5.91402 11.7782 8.00043 11.7782Z" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"></path>
          </svg>
        </span>
        <span class="om-theme-toggle__icon om-theme-toggle__icon--moon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" xmlns="http://www.w3.org/2000/svg">
            <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"></path>
          </svg>
        </span>
      `;
      const searchTrigger = headerInner.querySelector('label[for="__search"]');
      if (searchTrigger) {
        headerInner.insertBefore(button, searchTrigger);
      } else {
        headerInner.appendChild(button);
      }
    }
  }

  function initDocsTocState() {
    if (typeof docsTocCleanup === "function") {
      docsTocCleanup();
      docsTocCleanup = null;
    }

    const tocLinks = Array.from(document.querySelectorAll(".md-sidebar--secondary a.md-nav__link"));
    if (!tocLinks.length) {
      return;
    }

    const items = tocLinks.map((link) => {
      try {
        const hash = new URL(link.href, location.href).hash;
        if (!hash) {
          return null;
        }
        const heading = document.getElementById(decodeURIComponent(hash.slice(1)));
        if (!heading) {
          return null;
        }
        return { link, hash, heading };
      } catch {
        return null;
      }
    }).filter(Boolean);

    if (!items.length) {
      return;
    }

    const setCurrent = (hash) => {
      items.forEach(({ link }) => link.classList.remove("om-toc-link--current"));
      const current = items.find((item) => item.hash === hash);
      if (current) {
        current.link.classList.add("om-toc-link--current");
      }
    };

    const resolveCurrentHash = () => {
      const threshold = 170;
      let currentHash = items[0].hash;
      for (const item of items) {
        if (item.heading.getBoundingClientRect().top - threshold <= 0) {
          currentHash = item.hash;
        } else {
          break;
        }
      }
      return currentHash;
    };

    let frame = 0;
    const refresh = () => {
      frame = 0;
      setCurrent(resolveCurrentHash());
    };

    const requestRefresh = () => {
      if (frame) {
        return;
      }
      frame = window.requestAnimationFrame(refresh);
    };

    const onHashChange = () => {
      if (location.hash) {
        setCurrent(location.hash);
        window.setTimeout(requestRefresh, 120);
      } else {
        requestRefresh();
      }
    };

    items.forEach(({ link, hash }) => {
      if (link.dataset.tocBound === "true") {
        return;
      }
      link.dataset.tocBound = "true";
      link.addEventListener("click", () => {
        setCurrent(hash);
        window.setTimeout(requestRefresh, 120);
      });
    });

    window.addEventListener("scroll", requestRefresh, { passive: true });
    window.addEventListener("resize", requestRefresh);
    window.addEventListener("hashchange", onHashChange);

    if (location.hash) {
      setCurrent(location.hash);
      window.setTimeout(requestRefresh, 120);
    } else {
      refresh();
    }

    docsTocCleanup = () => {
      if (frame) {
        window.cancelAnimationFrame(frame);
      }
      window.removeEventListener("scroll", requestRefresh);
      window.removeEventListener("resize", requestRefresh);
      window.removeEventListener("hashchange", onHashChange);
    };
  }

  function initTabbedSets() {
    document.querySelectorAll(".tabbed-set").forEach((set) => {
      const inputs = Array.from(set.querySelectorAll(":scope > input[type='radio']"));
      const labels = Array.from(set.querySelectorAll(":scope > .tabbed-labels > label"));
      if (!inputs.length || inputs.length !== labels.length) {
        return;
      }

      const sync = () => {
        labels.forEach((label, index) => {
          label.classList.toggle("om-tabbed-label--active", Boolean(inputs[index] && inputs[index].checked));
        });
      };

      if (set.dataset.tabbedBound !== "true") {
        set.dataset.tabbedBound = "true";
        inputs.forEach((input) => input.addEventListener("change", sync));
        labels.forEach((label, index) => {
          label.addEventListener("click", () => {
            const input = inputs[index];
            if (input && !input.checked) {
              input.checked = true;
              input.dispatchEvent(new Event("change", { bubbles: true }));
            } else {
              sync();
            }
            window.setTimeout(sync, 0);
          });
        });
      }

      sync();
    });
  }

  function initMobileDrawer() {
    const drawer = document.querySelector("#__drawer");
    if (!drawer || drawer.dataset.omDrawerBound === "true") {
      return;
    }

    drawer.dataset.omDrawerBound = "true";

    const resetDrawerScroll = () => {
      if (!drawer.checked || window.matchMedia("(min-width: 76.25em)").matches) {
        return;
      }

      window.requestAnimationFrame(() => {
        const scrollwrap = document.querySelector(".md-sidebar--primary .md-sidebar__scrollwrap");
        const inner = document.querySelector(".md-sidebar--primary .md-sidebar__inner");
        if (scrollwrap) {
          scrollwrap.scrollTop = 0;
        }
        if (inner) {
          inner.scrollTop = 0;
        }
      });
    };

    drawer.addEventListener("change", () => {
      window.setTimeout(resetDrawerScroll, 20);
    });

    resetDrawerScroll();
  }

  function observeDocsTheme() {
    const body = document.body;
    if (!body || !body.hasAttribute("data-md-color-scheme")) {
      return;
    }

    const syncFromBody = () => {
      const theme = body.getAttribute("data-md-color-scheme") === "slate" ? "dark" : "light";
      setStoredTheme(theme);
      applySiteTheme(theme);
    };

    const palette = document.querySelector('[data-md-component="palette"]');
    if (palette) {
      palette.addEventListener("change", syncFromBody);
    }

    const observer = new MutationObserver(syncFromBody);
    observer.observe(body, { attributes: true, attributeFilter: ["data-md-color-scheme"] });
  }

  function initPageEnhancements() {
    ensureDocsThemeToggle();
    initThemeToggle();
    initCopyButtons();
    initMobileDrawer();
    initDocsTocState();
    initTabbedSets();
  }

  function boot() {
    if (repairBrokenMaterialPalette()) {
      return;
    }

    const theme = resolveTheme();
    applySiteTheme(theme);
    syncMaterialPalette(theme);
    initPageEnhancements();
    observeDocsTheme();

    if (window.document$ && typeof window.document$.subscribe === "function") {
      window.document$.subscribe(() => {
        const nextTheme = resolveTheme();
        applySiteTheme(nextTheme);
        syncMaterialPalette(nextTheme);
        initPageEnhancements();
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
