# 📎 ClipStash

A tiny, **100% offline** clipboard history manager for macOS. Lives in your menu bar,
remembers your recent clippings, and **never touches the network** — by design and by proof.

![menu bar app](https://img.shields.io/badge/platform-macOS%2013%2B-blue) ![offline](https://img.shields.io/badge/network-none-success) ![swift](https://img.shields.io/badge/Swift-6-orange)

---

## Why this exists

This started as plain curiosity.

I was looking at a popular Mac clipboard manager and asked a simple question: *can this app
see everything I copy — and could it send that somewhere?* A clipboard manager reads your
clipboard constantly (that's the whole job), so the only thing that really matters for privacy
is whether it can phone home.

So I inspected it. On macOS you can read any app's sandbox **entitlements** and its **linked
frameworks** to see what it's actually capable of:

```sh
codesign -d --entitlements - "/Applications/SomeClipboardApp.app"   # capabilities
otool -L "/Applications/SomeClipboardApp.app/Contents/MacOS/..."    # linked libraries
```

The app I looked at was reputable and the network access it had was for ordinary things
(checking for updates, validating a license) — nothing nefarious. But it *did* declare network
access and bundle networking frameworks, which means the *capability* to read your clipboard
**and** make network calls lives in the same process. For something that sees every password,
token, and private note you ever copy, "trust me" wasn't quite the answer I wanted.

So instead of trusting, I built one I could **prove** is offline. The entire app — code, icon,
build script, this README — was created in a single ~30-minute session with
[Claude Code](https://claude.com/claude-code) on **June 1, 2026**. The interesting part wasn't
just that it wrote the Swift; it's that it could *verify the privacy claim the same way I
audited the original app* — inspecting entitlements, linked frameworks, and live network
connections, and showing the receipts.

### The proof

ClipStash has **no network entitlement**, links **no networking frameworks**, and contains
**zero networking code**. You can confirm all three yourself:

```sh
# 1. Capabilities the OS grants it — should be empty
codesign -d --entitlements - "/Applications/ClipStash.app"

# 2. Linked libraries — only AppKit / Foundation / Swift runtime, no CFNetwork / Network.framework
otool -L "/Applications/ClipStash.app/Contents/MacOS/ClipStash"

# 3. Live connections while it runs — should print nothing
lsof -i -nP | grep -i clipstash

# 4. The source — grep for any networking API
grep -Eni 'URLSession|URLRequest|Socket|Network\.|http|connect\(' main.swift
```

---

## Features

- 📎 **Menu-bar only** — no Dock icon, stays out of your way
- 🧠 **Remembers your last 25 text clippings** — click any one to copy it back
- ⌨️ **Number shortcuts** (`⌘1`–`⌘9`) for the most recent clippings
- 🔒 **Password-aware** — ignores clipboard content that apps mark *concealed* or *transient*
  (`org.nspasteboard.ConcealedType` / `TransientType`), so most password managers' copies are
  never recorded
- 🫥 **Memory-only** — history lives in RAM and is forgotten when you quit. Nothing is written
  to disk, ever.
- 🚀 **Launch at Login** — optional toggle in the menu (uses Apple's modern `SMAppService`)
- 🌐 **No network. At all.** — verifiable, not just promised (see above)

---

## Build & install

Requires macOS 13+ and the Swift toolchain (Xcode or Command Line Tools — `xcode-select --install`).

```sh
git clone <your-repo-url> ClipStash
cd ClipStash
./build.sh --install      # builds the icon + app, installs to /Applications, and launches it
```

Or just build without installing:

```sh
./build.sh                # produces ./ClipStash.app
open ClipStash.app
```

After first launch, look for the 📎 icon in your menu bar. To start it automatically on login,
open the menu and click **Launch at Login**.

> **Note on Gatekeeper:** the app is *ad-hoc* code-signed (free, no Apple Developer account),
> which is enough to run on Apple Silicon. If macOS warns about an unidentified developer on
> first open, right-click the app → **Open**, or remove the quarantine flag:
> `xattr -dr com.apple.quarantine "/Applications/ClipStash.app"`.

---

## How it works

About 150 lines of Swift:

- An `NSStatusItem` puts the 📎 in the menu bar.
- A `Timer` polls `NSPasteboard.general.changeCount` twice a second. When it changes, the new
  string is read and pushed to the front of an in-memory list (deduped, capped at 25).
- Clicking a menu item writes that string back to the pasteboard.
- Concealed/transient pasteboard types are skipped so secrets aren't captured.
- That's it. No storage, no accounts, no servers.

| File | Purpose |
|------|---------|
| `main.swift` | The whole app |
| `make_icon.swift` | Renders the app icon (blue square + white paperclip) into an `.icns` |
| `Info.plist` | Bundle metadata (`LSUIElement` = menu-bar-only) |
| `build.sh` | Compiles, bundles, signs, and optionally installs |

---

## A note on the name

This project is **not** affiliated with, endorsed by, or derived from any commercial clipboard
manager. It was written from scratch. It was briefly prototyped under a different working name
during development; it was renamed to **ClipStash** before publishing specifically to avoid any
confusion with existing trademarked products. If you believe there's still a naming conflict,
please open an issue.

---

## License

**No license yet.** Until a `LICENSE` file is added, default copyright applies, which means
others may view this code but **may not legally reuse, modify, or redistribute it**. A
permissive license (e.g. MIT) will likely be added soon — until then, treat it as
source-available, not open-source.

---

## Acknowledgements

Built with [Claude Code](https://claude.com/claude-code) in one short session — including the
privacy audit that started the whole thing.
