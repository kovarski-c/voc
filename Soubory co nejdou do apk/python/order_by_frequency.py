from translations_hand_fix import translations
ordered_file = open("lib/data/final_english_table.dart", "r", encoding="utf-8").read().split("\",\"")

new_ordered_file = []

for key in ordered_file:
    if key in translations:
        new_ordered_file.append((key, translations[key]))

print(len(new_ordered_file))

with open("lib/data/LU_english.dart", "w", encoding="utf-8") as f:
    f.write("const List<String> english = [")
    for key, value in new_ordered_file:
        f.write(f"\"{key}\", ")
    f.write("];")

with open("lib/data/LU_luganda.dart", "w", encoding="utf-8") as f:
    f.write("const List<String> translations = [")
    for key, value in new_ordered_file:
        translations_list = " ".join([f'{v}' for v in value])
        f.write(f"\"{translations_list}\", ")
    f.write("];")
