# README demo image

`make_demo.py` builds the picture at the top of the README (`docs/demo-<lang>.webp`): a MacBook with the admin panel in a browser and an iPhone (6.1") with the user page. It takes two screenshots, so it can be refreshed for every release in a minute.

## Update for a new version

1. Take two screenshots on a test panel, light theme, one pair per language:
   - **Admin panel** (Admin V2 dashboard) at **1288×765**, browser page only → `screens/desktop-<lang>.webp`
   - **User page** on a phone at **390×763** (the iPhone status bar and home indicator are drawn by the script) → `screens/phone-<lang>.webp`

   Use a scale factor of 2 or 3 for sharp text. Hide anything private first: server IPs, domains, UUIDs, links, QR codes.
   An animated WebP/GIF works too (the script then makes an animated picture).
2. Run, from the repository root:

   ```bash
   python3 docs/readme-demo/make_demo.py            # all languages in screens/
   python3 docs/readme-demo/make_demo.py --lang fa  # one language
   ```

3. Commit the new `docs/demo-<lang>.webp` and the inputs in `screens/`.

## Requirements

- Python 3 with Pillow: `pip install pillow`
- Google Chrome or Chromium (set `CHROME=/path/to/chrome` if it is not found)

Right-to-left languages (`fa`, `ar`, `ps`, `ur`, `he`) get a mirrored layout (iPhone on the left). The README files use `demo-fa.webp` for Persian and `demo-en.webp` for the other languages. The address bar always shows `panel.example.com`.
