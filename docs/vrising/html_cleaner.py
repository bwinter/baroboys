from bs4 import BeautifulSoup

def clean_html(raw_html):
    soup = BeautifulSoup(raw_html, "html5lib")

    # Find content container
    main = soup.find("div", class_="mw-parser-output")
    if not main:
        raise ValueError("Could not find main content div (mw-parser-output)")

    # Tags to remove completely
    remove_tags = {"script", "style", "svg", "footer", "aside", "noscript"}

    for tag in main.find_all(True):
        if tag.name in remove_tags:
            tag.decompose()
        else:
            tag.attrs = {}  # strip all attributes

    # Remove comments
    for comment in main.find_all(string=lambda text: isinstance(text, type(soup.Comment))):
        comment.extract()

    # Normalize whitespace
    cleaned_html = str(main)
    cleaned_html = "\n".join(line.strip() for line in cleaned_html.splitlines() if line.strip())

    return cleaned_html.strip()
