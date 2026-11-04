english = open("lib/python/english.txt", "r", encoding="utf-8").read().split("\n")
dictionary = open("lib/python/txt.txt", "r", encoding="utf-8").read().split()

dictionary = [word for word in dictionary if word != '']

merged_dictionary = []
i = 0
while i < len(dictionary):
    word = dictionary[i]
    # Zkontroluj, jestli existuje další slovo a je v závorkách
    if i + 1 < len(dictionary) and dictionary[i + 1].startswith('(') and dictionary[i + 1].endswith(')'):
        word = f"{word} {dictionary[i + 1]}"
        i += 1  # přeskoč další slovo, protože už je sloučené
    if i + 2 < len(dictionary) and dictionary[i + 1].startswith('(') and dictionary[i + 2].endswith(')'):
        word = f"{word} {dictionary[i + 1]} {dictionary[i + 2]}"
        i += 2  # přeskoč další slovo, protože už je sloučené
   # přeskoč další slovo, protože už je sloučené
    merged_dictionary.append(word)
    i += 1

# Spoj víceslovné výrazy v merged_dictionary podle english
max_phrase_len = max(len(e.split()) for e in english)
i = 0
merged_dictionary_fixed = []
while i < len(merged_dictionary):
    found = False
    # Zkoušej od nejdelších po nejkratší víceslovné výrazy
    for l in range(max_phrase_len, 1, -1):
        if i + l <= len(merged_dictionary):
            phrase = " ".join(merged_dictionary[i:i+l])
            if phrase in english:
                merged_dictionary_fixed.append(phrase)
                i += l
                found = True
                break
    if not found:
        merged_dictionary_fixed.append(merged_dictionary[i])
        i += 1
merged_dictionary = merged_dictionary_fixed

translations = []

i = 0
while i < len(merged_dictionary):
    word = merged_dictionary[i]
    if word in english:
        trans_2 = []
        j = i + 1
        # Sbírej slova, dokud nenarazíš na další anglické slovo nebo konec seznamu
        while j < len(merged_dictionary) and merged_dictionary[j] not in english:
            trans_2.append(merged_dictionary[j])
            j += 1
        # Pokud je trans_2 prázdné a další slovo je také v english, spoj je
        if not trans_2 and j < len(merged_dictionary) and merged_dictionary[j] in english:
            next_word = merged_dictionary[j]
            # Najdi překlad pro další slovo
            trans_3 = []
            k = j + 1
            while k < len(merged_dictionary) and merged_dictionary[k] not in english:
                trans_3.append(merged_dictionary[k])
                k += 1
            # Spoj slova a překlad
            word = f"{word} {next_word}"
            trans_2 = trans_3
            i = j  # přeskoč na další slovo
        translations.append((word, trans_2))
    i += 1

translations_merged = []

for word, trans in translations:
    new_trans = []
    buffer = ""
    for idx, t in enumerate(trans):
        t = t.strip()
        if not t:
            continue
        if t.endswith(','):
            # Pokud je v bufferu něco, přidej to jako jeden výraz
            if buffer:
                new_trans.append(buffer.strip())
                buffer = ""
            # Přidej aktuální výraz (s čárkou) jako samostatný překlad
            new_trans.append(t)
        else:
            # Připojuj k bufferu
            if buffer:
                buffer += " " + t
            else:
                buffer = t
    # Po skončení přidej případný zbytek v bufferu
    if buffer:
        new_trans.append(buffer.strip())
    translations_merged.append((word, new_trans))

print(translations_merged)
       

print(len(english) - len(translations))
for eng, trans in translations:
    if eng not in english:
        print(f"Chybí v english: {eng}")

with open("lib/python/translations.py", "w", encoding="utf-8") as f:
    f.write("translations = {\n")
    for word, trans in translations_merged:
        # Každý překlad jako seznam řetězců
        trans_list = ", ".join([f'"{t}"' for t in trans])
        f.write(f'    "{word}": [{trans_list}],\n')
    f.write("}\n")