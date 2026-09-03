Vendored web assets for offline website and docs builds.

Current sources:
- `asciinema-player` `3.15.1` from `https://unpkg.com/asciinema-player@3.15.1/`
- `IBM Plex Sans`, `IBM Plex Mono`, and `Space Grotesk` latin `woff2` files fetched from Google Fonts / `fonts.gstatic.com`

These files are intentionally checked in so the built website and docs do not
depend on remote CSS, JS, or font requests at runtime.
