---
name: mermaid
description: Render Mermaid diagrams from a Markdown file to SVG, PNG, or PDF using the local mermaid shell function (Docker-backed). Use when the user wants to render, generate, export, or convert mermaid diagrams or charts found in a .md file, a local directory, or a URL.
---

# Mermaid Render Skill

You are rendering Mermaid diagrams from Markdown sources using either the `mermaid` shell function (Docker-backed, non-sandbox) or `mmdc` directly (sandbox).

## How the tool works

- The `mermaid` shell function wraps `minlag/mermaid-cli` via Docker.
- It finds every ` ```mermaid ` fenced block in the input `.md` file.
- It renders each block to a numbered image file (e.g. `example.svg-1.svg`).
- It writes a companion `.md` file with `![diagram](./image-N.ext)` references replacing the code blocks.
- The original file is **never modified**.

## Input types

The skill accepts three types of input:

| Type | Example |
|------|---------|
| Single file | `data/example.md` |
| Local directory | `./docs/` or `/some/path/` |
| URL (single file) | `https://example.com/diagram.md` |
| URL (GitHub directory) | `https://github.com/user/repo/tree/main/docs` |

---

## Your task

When invoked with arguments like `/mermaid data/example.md -f png`, do the following:

### Step 1 — Detect the environment
```bash
echo "${IS_SANDBOX:-no}"
```
- `IS_SANDBOX=yes` → use the **mmdc sandbox render path** throughout (see *Sandbox render* section).
- Otherwise → use `source mermaid.sh && mermaid ...` throughout.

### Step 2 — Classify the input

Inspect the first non-flag argument:

- **Starts with `http://` or `https://`** → URL input. Go to *URL handling*.
- **Is a directory path** (ends with `/`, or `test -d` is true) → Directory input. Go to *Directory handling*.
- **Otherwise** → single file. Go to *Single file handling*.

---

## Single file handling

1. Verify the file exists.
2. If it is under a read-only mount (e.g. `/mnt/`), copy it to `/home/claude/` first.
3. Render it (see *Render command* section).
4. Report the output files.

---

## Directory handling

1. List all `.md` files in the directory (non-recursive):
    ```bash
    ls /path/to/dir/*.md 2>/dev/null
    ```
2. Filter to only files that contain at least one mermaid block:
    ```bash
    grep -l '```mermaid' /path/to/dir/*.md
    ```
3. Skip any file whose name matches a companion pattern (contains `.svg.md`, `.png.md`, `.pdf.md`) — these are already-rendered outputs, not sources.
4. For each remaining file, render it following *Single file handling*.
5. Report a summary: how many files found, how many rendered, total diagrams.

---

## URL handling

There are two sub-cases:

### A) Single file URL

A URL ending in `.md` (or clearly pointing to a single Markdown file):

1. Use the `web_fetch` tool to retrieve the content (do **not** use `curl` — external domains may be blocked by the egress proxy).
2. Save the content to `/home/claude/<filename>.md` where `<filename>` is derived from the URL path.
3. Render it following *Single file handling*.

### B) GitHub directory URL

A URL of the form `https://github.com/user/repo/tree/<branch>/path/to/dir`:

1. Convert the GitHub tree URL to a GitHub API contents URL:
    - `https://github.com/user/repo/tree/main/docs`
    - → `https://api.github.com/repos/user/repo/contents/docs?ref=main`
2. Use `web_fetch` to retrieve the directory listing JSON.
3. Parse the JSON to find all entries where `"type": "file"` and `"name"` ends in `.md`.
4. Skip companion files (name contains `.svg.md`, `.png.md`, `.pdf.md`).
5. For each `.md` file, use `web_fetch` on its `download_url` field to fetch the content.
6. Save each to `/home/claude/<filename>.md` and render it.
7. Report a summary.

**Note**: `raw.githubusercontent.com` and `api.github.com` may be blocked by the sandbox egress proxy. If `web_fetch` fails with a network/403 error, inform the user that GitHub URLs are not reachable from the sandbox and ask them to download the file(s) locally and upload instead.

---

## Render command

### Sandbox (IS_SANDBOX=yes)

Write the puppeteer config once per session, then reuse:
```bash
cat > /tmp/puppeteer-config.json << 'EOF'
{
  "executablePath": "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
EOF

mmdc -i "$INPUT_FILE" -o "$OUTPUT_FILE" --puppeteerConfigFile /tmp/puppeteer-config.json
```

### Non-sandbox (Docker)

```bash
source mermaid.sh && mermaid "$INPUT_FILE" [options]
```

### Flag mapping (wrapper flags → mmdc flags)

| mermaid wrapper | mmdc equivalent     |
|-----------------|---------------------|
| `-f` / `--format`   | `--outputFormat`    |
| `-t` / `--theme`    | `--theme`           |
| `-b` / `--bg`       | `--backgroundColor` |
| `-w` / `--width`    | `--width`           |
| `-H` / `--height`   | `--height`          |
| `-s` / `--scale`    | `--scale`           |

---

## Options reference

| Flag | Long form  | Description                                            |
| ---- | ---------- | ------------------------------------------------------ |
| `-f` | `--format` | Output format: `svg` (default), `png`, `pdf`           |
| `-t` | `--theme`  | Theme: `default`, `dark`, `forest`, `neutral`          |
| `-b` | `--bg`     | Background colour: `white`, `transparent`, `'#rrggbb'` |
| `-w` | `--width`  | Canvas width in pixels                                 |
| `-H` | `--height` | Canvas height in pixels                                |
| `-s` | `--scale`  | Pixel density / scale factor (use 2–3 for retina PNG)  |
| `-d` | `--dir`    | Override the host directory mounted into Docker        |
| `-h` | `--help`   | Print built-in help                                    |

## Defaults

- Format: `svg`
- Scale: `1`
- Background: theme default (use `transparent` for dark-mode embedding)

---

## Output location

For input `data/example.md` rendered as SVG, mmdc writes:

- `data/example-1.svg`, `data/example-2.svg`, … (one per diagram block)

The `mermaid` wrapper writes:

- `data/example.svg-1.svg`, `data/example.svg-2.svg`, …
- `data/example.svg.md` (companion Markdown with image references)

---

## Previewing diagrams

Always share these tips with the user after a successful render:

- **VS Code**: Install the [Mermaid Preview](https://marketplace.visualstudio.com/items?itemName=vstirbu.vscode-mermaid-preview) extension to preview diagrams directly in the editor.
- **GitHub**: Mermaid rendering is built into GitHub — ` ```mermaid ` fenced blocks render automatically when viewed in a repository.

---

## Error handling

- **Sandbox / no Docker**: if `IS_SANDBOX=yes` or `docker` not on PATH, use mmdc path. Do not attempt Docker.
- **Chrome won't launch**: ensure `--no-sandbox` and `--disable-setuid-sandbox` are in puppeteer config args.
- **Chromium path changed**: find it with `find /opt/pw-browsers -name "chrome" | grep -v headless | head -1`.
- **Read-only input**: if file is under `/mnt/`, copy to `/home/claude/` before rendering.
- **URL fetch blocked**: if `web_fetch` fails with 403/network error on a GitHub URL, inform the user that domain is blocked by the egress proxy and ask them to upload the file directly.
- **mermaid shell function missing** (non-sandbox): instruct user to `git clone https://github.com/rondomondo/mermaid.git` then `source mermaid.sh`.
- **Docker not running** (non-sandbox): tell user to start Docker Desktop.
- **File not found**: report the exact path tried and suggest checking the working directory.
- Always show raw stderr from the render so the user can see which diagrams succeeded (✅) or failed.
