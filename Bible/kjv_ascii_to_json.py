import re

file_path = "kjv_ascii.txt"
output_godot = "kjv_bible.gd"

bible_data = {}
chapters_per_book = {}
verses_per_chapter = {}

with open(file_path, "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("KJV") or line.startswith("King James"):
            continue
        
        if ":" not in line:
            continue  # skip malformed lines

        # Split on the first colon
        book_chapter, verse_text = line.split(":", 1)
        parts = book_chapter.rsplit(" ", 1)
        if len(parts) != 2:
            continue  # skip malformed lines
        book, chapter_str = parts
        chapter = int(chapter_str)

        # Clean the verse text: remove leading verse number and whitespace
        verse_text = verse_text.strip()
        verse_text = re.sub(r'^\d+\s+', '', verse_text)

        # Initialize nested structures
        if book not in bible_data:
            bible_data[book] = {}
            chapters_per_book[book] = 0
        if chapter not in bible_data[book]:
            bible_data[book][chapter] = []
            chapters_per_book[book] += 1

        bible_data[book][chapter].append(verse_text)

        # Use string key instead of tuple
        verses_per_chapter[f"{book} {chapter}"] = len(bible_data[book][chapter])

# Flatten for easier linear traversal in Godot
linear_verses = []
for book in bible_data:
    for chapter in sorted(bible_data[book]):
        for verse_number, verse_text in enumerate(bible_data[book][chapter], start=1):
            linear_verses.append({
                "book": book,
                "chapter": chapter,
                "verse": verse_number,
                "verse_text": verse_text
            })

# Function to convert Python dict/list to Godot Stringify
def godot_stringify(obj, indent=0):
    spacing = "  " * indent
    if isinstance(obj, dict):
        items = []
        for k, v in obj.items():
            key = f'"{k}"'
            items.append(f"{spacing}  {key}: {godot_stringify(v, indent+1)}")
        return "{\n" + ",\n".join(items) + f"\n{spacing}}}"
    elif isinstance(obj, list):
        items = [f"{spacing}  {godot_stringify(v, indent+1)}" for v in obj]
        return "[\n" + ",\n".join(items) + f"\n{spacing}]"
    elif isinstance(obj, str):
        return f'"{obj}"'
    else:
        return str(obj)

# Combine all data for export
export_data = {
    "bible_data": bible_data,
    "chapters_per_book": chapters_per_book,
    "verses_per_chapter": verses_per_chapter,
    "linear_verses": linear_verses
}

with open(output_godot, "w", encoding="utf-8") as f:
    f.write(godot_stringify(export_data))

print(f"Processed {len(bible_data)} books.")
print(f"Total verses: {len(linear_verses)}")
print(f"Godot-compatible export to: {output_godot}")
