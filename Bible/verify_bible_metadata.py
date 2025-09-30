import json

# Load your Bible data JSON file
with open("kjv_bible.json", "r", encoding="utf-8") as f:
    data = json.load(f)

# Extract the Bible data dictionary
bible_data = data.get("bible_data", {})

# Get the list of book names
book_names = list(bible_data.keys())

# Print each book name
print("Books in the Bible:")
for name in book_names:
    print("-", name)

# Print total number of books
print("\nTotal number of books:", len(book_names))
