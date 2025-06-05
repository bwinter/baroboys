import re

def clean_markdown(input_text):
    # --- Structural Cleanup ---
    input_text = re.sub(r'^:{3,}.*$', '', input_text, flags=re.MULTILINE)  # Pandoc blocks
    input_text = re.sub(r'\{[^\}]+\}', '', input_text)                     # Pandoc attributes
    input_text = re.sub(r'!\[\]\(data:image/[^)]+\)', '', input_text)      # Base64 images
    input_text = re.sub(r'^\s*\[!\[.*?\]\(.*?\)\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)
    input_text = re.sub(r'^\s*!?\[.*?\]\(.*?\)\s*$', '', input_text, flags=re.MULTILINE)
    input_text = re.sub(r'\[\[\\?\[.*?\]\(.*?\)\]\]', '', input_text)      # Nested edit links
    input_text = re.sub(r'\[\[.*?\]\]', '', input_text)                    # Wiki-style links
    input_text = re.sub(r'\[\]', '', input_text)                           # Leftover brackets
    input_text = re.sub(r'^- *$', '', input_text, flags=re.MULTILINE)      # Empty bullet lines
    input_text = re.sub(r'</?[\w\-]+(?:\s+[^>]*?)?>', '', input_text)      # HTML tags
    input_text = re.sub(r'\[\^?\d+\]', '', input_text)                     # Footnote refs
    input_text = re.sub(r'^#+\s*\{[^\}]+\}', '', input_text, flags=re.MULTILINE)  # Empty class headers
    input_text = re.sub(r'<!--.*?-->', '', input_text, flags=re.DOTALL)    # HTML comments

    # --- Final Polish ---
    input_text = re.sub(r'^Advertisement\s*$', '', input_text, flags=re.MULTILINE)  # Strip "Advertisement" lines
    input_text = re.sub(r'\\\[\]', '', input_text)                                   # Remove \[\] artifacts
    input_text = re.sub(r'^:.*?Collapse\s*$', '', input_text, flags=re.MULTILINE)    # Remove TOC Collapse tags
    input_text = re.sub(r'^:+$', '', input_text, flags=re.MULTILINE)                 # Remove ::: lines
    input_text = re.sub(r'^[ \t]+|[ \t]+$', '', input_text, flags=re.MULTILINE)      # Trim line whitespace
    input_text = re.sub(r'\n{3,}', '\n\n', input_text)                                # Collapse >2 newlines

    return input_text.strip()
