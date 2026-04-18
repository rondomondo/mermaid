# mermaid

A shell function (compatible with **bash** and **zsh**) that renders [Mermaid](https://mermaid.js.org/) diagrams found inside Markdown files. It uses the official [`minlag/mermaid-cli`](https://hub.docker.com/r/minlag/mermaid-cli) Docker image — no Node.js or local npm install required.

Each ```` ```mermaid ```` fenced block in your input file is extracted and rendered to an image (SVG, PNG, or PDF). The output is a new Markdown file with the diagram code blocks replaced by `![diagram](./image-N.ext)` image references, plus the rendered image files alongside it.

---

## Requirements

- **Docker** installed and running locally
- **bash** (3.2+) or **zsh**

---

## Installation

```bash
# call 'setopt interactivecomments' if you want to cut'n'paste the following into a zsh
# terminal verbatim

# Clone the repo
git clone https://github.com/rondomondo/mermaid.git
cd mermaid

# Copy the script to your PATH (default /usr/local/bin, adjust as needed)
INSTALL_DIR=/usr/local/bin
cp mermaid.sh "$INSTALL_DIR/mermaid.sh"

# Source it in your shell profile so the function is available in every session
# For zsh:
echo 'source '"$INSTALL_DIR"'/mermaid.sh' >> ~/.zshrc && source ~/.zshrc

# For bash:
echo 'source '"$INSTALL_DIR"'/mermaid.sh' >> ~/.bashrc && source ~/.bashrc
```

> The script defines a **shell function** (not a standalone executable), so it must be sourced rather than executed directly.

---

## Quick start

Put your Markdown files in a `data/` subdirectory (create it if it doesn't exist):

```bash
mkdir -p data
# drop your .md files with mermaid blocks into data/
```

Then render:

```bash
mermaid data/example.md
```

---

## Usage

```
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

### PNG with a coloured background

```bash
mermaid data/example.md --format png --width 640 --height 480 --bg red
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

## Tips

- Use `--scale 2` or `--scale 3` for retina/HiDPI PNG exports.
- Combine `--bg transparent` with SVG output for diagrams you embed in dark-mode docs.
- The `--dir` flag lets you mount a different directory if your assets span multiple folders.
- Run `mermaid -h` at any time to print the built-in help.
