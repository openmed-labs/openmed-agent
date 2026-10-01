/* OpenMed docs chrome: theme toggle (shared "openmed-theme" key with the
   landing page) and ink code-block header bars (language label + Material's
   copy button moved inline). Instant-navigation aware via document$. */
(function () {
  var STORAGE_KEY = "openmed-theme";

  function getStoredTheme() {
    try {
      return localStorage.getItem(STORAGE_KEY);
    } catch (error) {
      return null;
    }
  }

  function setStoredTheme(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch (error) {
      /* private mode */
    }
  }

  function systemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function resolveTheme() {
    var stored = getStoredTheme();
    return stored === "dark" || stored === "light" ? stored : systemTheme();
  }

  function applyTheme(theme) {
    var root = document.documentElement;
    root.setAttribute("data-theme", theme);
    root.setAttribute("data-md-color-scheme", theme === "dark" ? "slate" : "default");
    document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
      button.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
      button.setAttribute(
        "aria-label",
        theme === "dark" ? "Switch to light theme" : "Switch to dark theme"
      );
    });
  }

  function bindThemeToggles() {
    document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
      if (button.dataset.themeBound === "true") return;
      button.dataset.themeBound = "true";
      button.addEventListener("click", function () {
        var next = resolveTheme() === "dark" ? "light" : "dark";
        setStoredTheme(next);
        applyTheme(next);
      });
    });
  }

  /* Give each code block the handoff's ink header bar: lowercase language
     label on the left, our own ⧉ copy button on the right. Material's own
     clipboard button mounts asynchronously, so it is hidden in CSS instead
     of relocated. */
  function decorateCodeBlocks(scope) {
    (scope || document).querySelectorAll(".md-typeset .highlight").forEach(function (block) {
      if (block.dataset.omDecorated === "true") return;
      var pre = block.querySelector("pre");
      if (!pre) return;
      block.dataset.omDecorated = "true";

      var lang = "code";
      block.classList.forEach(function (cls) {
        if (cls.indexOf("language-") === 0) lang = cls.slice("language-".length);
      });

      var header = document.createElement("div");
      header.className = "om-cb__hd";
      var label = document.createElement("span");
      label.className = "om-cb__lang";
      label.textContent = lang;
      header.appendChild(label);

      var copyButton = document.createElement("button");
      copyButton.type = "button";
      copyButton.className = "om-cb__copy";
      copyButton.textContent = "⧉ copy";
      copyButton.setAttribute("aria-label", "Copy code to clipboard");
      copyButton.addEventListener("click", function () {
        var code = block.querySelector("pre code");
        if (!code) return;
        try {
          navigator.clipboard.writeText(code.textContent || "");
          copyButton.textContent = "✓ copied";
          window.setTimeout(function () {
            copyButton.textContent = "⧉ copy";
          }, 1600);
        } catch (error) {
          /* clipboard unavailable */
        }
      });
      header.appendChild(copyButton);

      block.insertBefore(header, pre);
    });
  }

  /* ---------- table-of-contents highlight ----------

     Material marks a heading current only once it has scrolled to the very top
     of the viewport — which, under a 65px sticky header, means the heading is
     already hidden behind it. While you are reading a section whose title sits
     comfortably below the header, the row highlighted is the section ABOVE it.

     Material also marks the nested TOC copy inside the primary drawer, so at
     drawer widths two rows glow at once: the current page and the current
     section.

     Both are fixed by owning the state: we pick the current section using the
     header height plus a reading band, publish it as data-om-current on every
     TOC copy, and let the stylesheet decide which single row gets the accent.
     Material's own --active class is left alone and simply not styled here. */
  var CURRENT_ATTR = "data-om-current";
  /* How far below the header a heading may sit and still count as "current".
     Without it a section only activates once its title is out of sight. */
  var READING_BAND = 96;

  function stickyHeaderHeight() {
    var header = document.querySelector(".md-header");
    if (!header) return 0;
    /* Material hides the header on scroll-down when header.autohide is on. */
    if (header.getAttribute("data-md-state") === "hidden") return 0;
    if (header.classList.contains("md-header--hidden")) return 0;
    var position = window.getComputedStyle(header).position;
    if (position !== "sticky" && position !== "fixed") return 0;
    return header.getBoundingClientRect().height || 0;
  }

  /* Every TOC link that points at a heading on this page, paired with it.
     Re-read on each pass: it is a handful of nodes, and it keeps us correct
     across instant navigation without tracking swaps. */
  function tocEntries() {
    var entries = [];
    document.querySelectorAll("[data-md-component='toc'] a.md-nav__link").forEach(
      function (link) {
        var hash = (link.hash || "").slice(1);
        if (!hash) return;
        var id;
        try {
          id = decodeURIComponent(hash);
        } catch (error) {
          id = hash;
        }
        var target = document.getElementById(id);
        if (target) entries.push({ link: link, target: target, id: id });
      }
    );
    return entries;
  }

  function updateTocHighlight() {
    var entries = tocEntries();
    if (!entries.length) return;

    var threshold = stickyHeaderHeight() + READING_BAND;
    var currentId = entries[0].id;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].target.getBoundingClientRect().top <= threshold) {
        currentId = entries[i].id;
      }
    }

    /* At the end of the page the final sections may never reach the threshold —
       a short last section would otherwise leave an earlier row highlighted
       even though the reader can see the bottom of the document. */
    var scrollBottom = window.scrollY + window.innerHeight;
    if (scrollBottom >= document.documentElement.scrollHeight - 2) {
      currentId = entries[entries.length - 1].id;
    }

    entries.forEach(function (entry) {
      if (entry.id === currentId) {
        entry.link.setAttribute(CURRENT_ATTR, "true");
      } else {
        entry.link.removeAttribute(CURRENT_ATTR);
      }
    });
  }

  var tocFrame = 0;
  function scheduleTocUpdate() {
    if (tocFrame) return;
    tocFrame = window.requestAnimationFrame(function () {
      tocFrame = 0;
      updateTocHighlight();
    });
  }

  /* Bound once for the life of the document — boot() may run many times under
     instant navigation, and re-adding these would stack duplicate listeners. */
  window.addEventListener("scroll", scheduleTocUpdate, { passive: true });
  window.addEventListener("resize", scheduleTocUpdate, { passive: true });
  window.addEventListener("hashchange", scheduleTocUpdate);

  function boot() {
    applyTheme(resolveTheme());
    bindThemeToggles();
    decorateCodeBlocks(document);
    updateTocHighlight();
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    // Material instant navigation: re-run on every page swap.
    window.document$.subscribe(function () {
      boot();
    });
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
