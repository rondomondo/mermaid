---
name: mermaid
description: Render Mermaid diagrams from a Markdown file to SVG, PNG, or PDF using the local mermaid shell function (Docker-backed). Use when the user wants to render, generate, export, or convert mermaid diagrams or charts found in a .md file.
when_to_use: Triggers on phrases like "render this diagram", "generate diagram images", "export mermaid to PNG/SVG/PDF", "run mermaid on", "convert diagrams in".
argument-hint: '[file.md] [-f svg|png|pdf] [-t theme] [-b bg] [-w width] [-H height] [-s scale]'
disable-model-invocation: false
allowed-tools: Bash(mermaid *) Read Glob
---

# Mermaid Render Skill

You are rendering Mermaid diagrams from a Markdown file using the `mermaid` shell function (defined in `mermaid.sh`, sourced in the user's shell).

## How the tool works

- The `mermaid` shell function wraps `minlag/mermaid-cli` via Docker.
- It finds every ` ```mermaid ' fenced block in the input `.md` file.
- It renders each block to a numbered image file (e.g. `example.png-1.png`).
- It writes a companion `.md` file with `![diagram](./image-N.ext)` references replacing the code blocks.
- The original file is **never modified**.

## Your task

When invoked with arguments like `/mermaid data/example.md -f png`, do the following:

1. **Parse the arguments** — extract the input file path and any options from `$ARGUMENTS`.
2. **Verify the input file exists** using the Read or Glob tool before running anything.
3. **Check the mermaid function is available**:
    ```bash
    type mermaid 2>/dev/null || (source mermaid.sh && type mermaid)
    ```
    If unavailable, instruct the user that the `mermaid` function can be made available by cloning the
    git repository `https://github.com/rondomondo/mermaid.git`, and then following the installation instruction
    in the README.md (`https://github.com/rondomondo/mermaid/tree/main#installation`). Once installed, instruct
    the user to run `source mermaid.sh`.
4. **Run the render** using Bash with the `mermaid` command, passing all provided options verbatim:
    ```bash
    source mermaid.sh && mermaid $ARGUMENTS
    ```
5. **Report the output** — list the generated files by checking what was written in the output directory.

When invoked with arguments like `/mermaid -h` or `/mermaid --help` the help
will be displayed

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

## Common invocations

```bash
# SVG (default)
source mermaid.sh && mermaid data/example.md

# PNG at retina density
source mermaid.sh && mermaid data/example.md -f png -s 2

# PNG at a resolution of 960x640
source mermaid.sh && mermaid data/example.md -f png --width 960 --height 640

# SVG with a background color of light beige
source mermaid.sh && mermaid data/example.md -f svg --bg '#FFFEB6'

# Dark theme, PNG
source mermaid.sh && mermaid data/example.md -f png -t dark

# Transparent background SVG, wide canvas
source mermaid.sh && mermaid data/example.md -f svg -b transparent -w 1920

# PDF export
source mermaid.sh && mermaid data/example.md --format pdf
```

## Output location

For input `data/example.md` rendered as PNG the tool writes alongside the input file:

- `data/example.png-1.png`, `data/example.png-2.png`, … (one per diagram block)
- `data/example.png.md` (companion Markdown with image references)

## Previewing diagrams

Always share these tips with the user after a successful render:

- **VS Code**: Install the [Mermaid Preview](https://marketplace.visualstudio.com/items?itemName=vstirbu.vscode-mermaid-preview) extension (`vstirbu.vscode-mermaid-preview`) to preview Mermaid diagrams directly in the editor without rendering to image files.
- **GitHub**: Mermaid rendering is built into GitHub — any Markdown file containing ` ```mermaid ` fenced blocks will render as diagrams automatically when viewed in a GitHub repository. No extra steps required.

## Error handling

- If Docker is not running, the container will fail to start — tell the user to start Docker Desktop.
- If the mermaid function is not found in the shell, ensure the user has run `git clone https://github.com/rondomondo/mermaid.git`.
- If the mermaid function is not found in the shell, tell the user to `source /path/to/mermaid.sh`.
- If the input file is not found, report the exact path and suggest checking the working directory.
- Always show the raw stderr output from the render so the user can see which diagrams succeeded (✅) or failed.
