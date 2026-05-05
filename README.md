# mermaid

**Render [Mermaid](https://mermaid.js.org/) diagrams from Markdown to SVG, PNG, or PDF without installing Node.js or npm.** A lightweight shell function (compatible with **bash** and **zsh**) scans every ` ```mermaid ` fenced block in a Markdown file and renders each one to a numbered image using the official [`minlag/mermaid-cli`](https://hub.docker.com/r/minlag/mermaid-cli) Docker image, producing a companion Markdown file with diagram code replaced by standard image references.

Suitable for local development, CI pipelines, documentation workflows, and [Claude Code](https://claude.ai/code) environments via the included [/mermaid](.claude/skills/mermaid/) slash command skill.

After each ```` ```mermaid ```` fenced block in your input file is extracted and rendered to an image (SVG, PNG, or PDF), the output is a new Markdown file with the diagram code blocks replaced by `![diagram](./image-N.ext)` image references, plus the rendered image files alongside it.

---

## Requirements

- **Docker** installed and running locally
- **bash** (3.2+) or **zsh**

---

## Installation

```bash
git clone https://github.com/rondomondo/mermaid.git
cd mermaid
make install        # copies mermaid.sh to /usr/local/bin and adds source line to your shell profile
source ~/.bashrc     # or ~/.zshrc — reload whichever profile make install updated
```

To install to a different directory:

```bash
make install INSTALL_DIR=~/bin
```

> `mermaid` is a **shell function**, not a standalone executable — it must be sourced into your shell session. `make install` handles this automatically.

Verify the install worked:

```bash
make check
```

---

## Quick start

```bash
mermaid data/example.md        # renders to SVG (default)
make test                      # smoke-test: renders example.md as SVG and PNG
```

---

## Usage

```bash
mermaid <input.md> [options]

Options:
  -f, --format <fmt>    Output format: svg (default), png, pdf
  -t, --theme <theme>   Mermaid theme: default, dark, forest, neutral
  -b, --bg <color>      Background colour (e.g. white, transparent, '#f5f5f5')
  -w, --width <px>      Diagram width in pixels
  -H, --height <px>     Diagram height in pixels
  -s, --scale <n>       Pixel density / scale factor (default 1)
  -d, --dir <dir>       Host directory to mount (defaults to directory of input file)
  -h, --help            Show this help
```

---

## Examples

### SVG output (default)

```bash
mermaid data/example.md
```

### PNG at a custom resolution

```bash
mermaid data/example.md --format png --width 960 --height 640
```

Example output:

```
mermaid: rendering 'example.md' → 'example.png.md' (png)
Found 6 mermaid charts in Markdown input
 ✅ ./example.png-1.png
 ✅ ./example.png-2.png
 ✅ ./example.png-3.png
 ✅ ./example.png-4.png
 ✅ ./example.png-5.png
 ✅ ./example.png-6.png
 ✅ /data/example.png.md
mermaid: written → /Users/davek/Code/mermaid/data/example.png.md
```

### PNG with dark theme and high pixel density

```bash
mermaid data/example.md -f png -t dark -s 3
```

### SVG with a transparent background, wide canvas

```bash
mermaid data/example.md -f svg -b transparent -w 1920
```

### PNG with a coloured background - slate

```bash
mermaid data/example.md --format png --width 640 --height 480 --bg '#99aacc'
```

### PDF export

```bash
mermaid data/example.md --format pdf
```

---

## Output files

For an input file `data/example.md` rendered as PNG the function writes:

| File | Description |
|---|---|
| `data/example.png-1.png` | First rendered diagram |
| `data/example.png-2.png` | Second rendered diagram |
| … | … |
| `data/example.png.md` | Updated Markdown with `![diagram](./example.png-N.png)` image links |

The original `.md` file is **not modified**.

---

## How it works

1. The function resolves the absolute path of the input file and mounts its parent directory into the Docker container at `/data`.
2. `minlag/mermaid-cli` iterates over every ```` ```mermaid ```` block in the file and renders each one to a numbered image file.
3. It writes a companion Markdown file (e.g. `example.png.md`) where the code blocks are replaced with standard `![diagram](...)` image references — ready to embed in GitHub, GitLab, Notion, or any Markdown renderer that serves local images.
4. The container runs as the current user (`-u $(id -u):$(id -g)`) so all output files are owned by you, not root.

---

## Themes

| Theme | Description |
|---|---|
| `default` | Light, clean (default if omitted) |
| `dark` | Dark background |
| `forest` | Green-toned |
| `neutral` | Greyscale, print-friendly |

---

## Claude Code skill

If you use [Claude Code](https://claude.ai/code), this repository ships a `/mermaid` slash command skill that lets Claude render your diagrams for you.

### What it does

Invoking `/mermaid data/example.md -f png` inside Claude Code will parse your arguments, verify the input file, check that the `mermaid` shell function is available, run the render, and report back the generated files — all without you touching the terminal.

### Installing safely

The skill lives in [.claude/skills/mermaid/](.claude/skills/mermaid/) inside this repository. Claude Code loads skills from a `.claude/skills/` directory in your **project root**, so the safest approach is to copy only the skill directory into your own project rather than pointing Claude at an arbitrary external directory.

If you have a local clone, the easiest path is:

```bash
make skill-install   # copies .claude/skills/mermaid/ into ~/.claude/skills/mermaid/
```

Alternatively, copy or download just the skill file:

```bash
mkdir -p .claude/skills/mermaid
curl -fsSL \
  https://raw.githubusercontent.com/rondomondo/mermaid/main/.claude/skills/mermaid/SKILL.md \
  -o .claude/skills/mermaid/SKILL.md
```

Or from a local clone:

```bash
cp /path/to/mermaid/.claude/skills/mermaid/SKILL.md .claude/skills/mermaid/SKILL.md
```

**Before copying**, open `SKILL.md` and review the `allowed-tools` frontmatter field. It declares exactly which tools the skill is permitted to use — confirm these match what you expect before letting Claude run it.

### Using the skill

Once installed, start or restart Claude Code in your project, then:

```
/mermaid data/example.md
/mermaid data/example.md -f png -s 2
/mermaid --help
```

The skill requires the `mermaid` shell function to be available in your environment (see [Installation](#installation) above). If it is not sourced, the skill will tell you exactly what to run.

---

## Sample output

The [data/example.png.md](data/example.png.md) file was produced by running:

```bash
mermaid data/example.md --format png --width 960 --height 640
```

### Example Rendered Diagrams - [SRE Common Diagrams](data/example.png.md)

![diagram](data/example.png-1.png)

<br>

## Relationship between frameworks

![diagram](data/example.png-2.png)

---

## Tips

- Use `--scale 2` or `--scale 3` for retina/HiDPI PNG exports.
- Combine `--bg transparent` with SVG output for diagrams you embed in dark-mode docs.
- The `--dir` flag lets you mount a different directory if your assets span multiple folders.
- Run `mermaid -h` at any time to print the built-in help.

