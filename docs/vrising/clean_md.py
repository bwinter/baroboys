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

    # Remove any full lines that are only buttons or icons
    input_text = re.sub(r'^\s*\[!\[.*?\]\(.*?\)\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)
    input_text = re.sub(r'^\s*!?\[.*?\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)

    # Remove Markdown edit links (like [[...]] or [\[...\]])
    input_text = re.sub(r'\[\[\\?\[.*?\]\(.*?\)\]\]', '', input_text)

    # Remove leftover empty brackets
    input_text = re.sub(r'\[\]', '', input_text)

    # Collapse multiple blank lines
    input_text = re.sub(r'\n{3,}', '\n\n', input_text)

    # Strip trailing whitespace
    input_text = re.sub(r'[ \t]+$', '', input_text, flags=re.MULTILINE)

    return input_text.strip()

def main():
    if len(sys.argv) != 3:
        print("Usage: clean_md.py input.md output.md")
        sys.exit(1)

    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        raw = f.read()

    cleaned = clean_markdown(raw)

    with open(sys.argv[2], 'w', encoding='utf-8') as f:
        f.write(cleaned)

    print(f"Cleaned markdown written to {sys.argv[2]}")

if __name__ == "__main__":
    main()
