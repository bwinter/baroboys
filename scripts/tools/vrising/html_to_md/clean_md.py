#!/usr/bin/env python3

import re
import sys

def clean_markdown(input_text):
    # Remove ::: style blocks (Pandoc or Fandom divs)
    input_text = re.sub(r'^:{3,}.*$', '', input_text, flags=re.MULTILINE)

    # Remove HTML-style attributes: {#id .class ...}
    input_text = re.sub(r'\{[^\}]+\}', '', input_text)

    # Remove inline base64 images
    input_text = re.sub(r'!\[\]\(data:image/[^)]+\)', '', input_text)

    # Remove full lines that are only buttons, icons, or images
    input_text = re.sub(r'^\s*\[!\[.*?\]\(.*?\)\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)
    input_text = re.sub(r'^\s*!?\[.*?\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)

    # Remove Markdown edit links like [[...]] or [\[...\]]
    input_text = re.sub(r'\[\[\\?\[.*?\]\(.*?\)\]\]', '', input_text)

    # Remove internal wiki-style links like [[File:...]]
    input_text = re.sub(r'\[\[.*?\]\]', '', input_text)

    # Remove leftover empty brackets
    input_text = re.sub(r'\[\]', '', input_text)

    # Remove empty bullet points
    input_text = re.sub(r'^- *$', '', input_text, flags=re.MULTILINE)

    # Remove stray HTML tags (e.g. <span class="...">)
    input_text = re.sub(r'</?[\w\-]+(?:\s+[^>]*?)?>', '', input_text)

    # Remove loose footnote/citation references like [^1] or [1]
    input_text = re.sub(r'\[\^?\d+\]', '', input_text)

    # Remove empty headers that only contain class annotations
    input_text = re.sub(r'^#+\s*\{[^\}]+\}', '', input_text, flags=re.MULTILINE)

    # Trim leading/trailing whitespace on each line
    input_text = re.sub(r'^[ \t]+|[ \t]+$', '', input_text, flags=re.MULTILINE)

    # Collapse 3+ newlines to exactly 2
    input_text = re.sub(r'\n{3,}', '\n\n', input_text)

    return input_text.strip()

def main():
    if len(sys.argv) != 3:
        print("Usage: clean_md.py input.html output.md")
        sys.exit(1)

    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        raw = f.read()

    cleaned = clean_markdown(raw)

    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        f.write(cleaned)

    print(f"Cleaned markdown written to {sys.argv[2]}")

if __name__ == "__main__":
    main()
