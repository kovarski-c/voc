from pdfminer.high_level import extract_pages
from pdfminer.layout import LTTextContainer, LTChar

english = []
translations = []

for page_layout in extract_pages("lib/python/English-Luganda_version_2_0.pdf"):
    for element in page_layout:
        if isinstance(element, LTTextContainer):
            for line in element:
                last_bold = ""
                buffer = ""
                collecting_bold = True
                for obj in line:
                    if isinstance(obj, LTChar):
                        is_bold = "Bold" in obj.fontname
                        char = obj.get_text()
                        if is_bold:
                            if not collecting_bold and last_bold and buffer:
                                # Ulož pouze kompletní dvojici
                                english.append(last_bold.strip())
                                translations.append(buffer.strip())
                                last_bold = ""
                                buffer = ""
                            collecting_bold = True
                            last_bold += char
                        else:
                            if collecting_bold:
                                collecting_bold = False
                            buffer += char
                    else:
                        buffer += obj.get_text()
                # Po zpracování řádku ulož dvojici, pokud je kompletní
                if last_bold and buffer:
                    english.append(last_bold.strip())
                    translations.append(buffer.strip())

with open("lib/python/english.txt", "w", encoding="utf-8") as f:
    f.write("\n".join([line for line in english if line.strip() and line.strip() != ","]))
with open("lib/python/translations.txt", "w", encoding="utf-8") as f:
    f.write("\n".join([line for line in translations if line.strip()]))