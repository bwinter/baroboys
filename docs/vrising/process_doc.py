#!/usr/bin/env python3

import subprocess
import sys
from html_cleaner import clean_html
from markdown_cleaner import clean_markdown

def main():
    if len(sys.argv) != 3:
        print("Usage: process_doc.py input.html output.md")
        sys.exit(1)

    html_in = sys.argv[1]
    html_clean = "cleaned.html"
    md_intermediate = "intermediate.md"
    md_final = sys.argv[2]

    # Step 1: Clean HTML
    with open(html_in, 'r', encoding='utf-8') as f:
        raw_html = f.read()

    cleaned_html = clean_html(raw_html)

    with open(html_clean, 'w', encoding='utf-8') as f:
        f.write(cleaned_html)

    # Step 2: Convert HTML → Markdown with Pandoc
    subprocess.run(["pandoc", html_clean, "-f", "html", "-t", "markdown", "-o", md_intermediate], check=True)

    # Step 3: Clean Markdown
    with open(md_intermediate, 'r', encoding='utf-8') as f:
        raw_md = f.read()

    final_md = clean_markdown(raw_md)

    with open(md_final, 'w', encoding='utf-8') as f:
        f.write(final_md)

    print(f"✅ Final cleaned Markdown written to: {md_final}")

if __name__ == "__main__":
    main()
