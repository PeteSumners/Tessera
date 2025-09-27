from PIL import Image
import random

# Load the images (assume 16x16 PNGs; handle RGBA if needed)
dirt = Image.open('dirt.png')
grass = Image.open('grass.png')

# Create a new 16x16 image
side = Image.new('RGBA', (16, 16))

# Generate jagged grass heights for each column (x)
heights = []
current_height = 3  # Starting depth from top
for x in range(16):
    heights.append(current_height)
    delta = random.choice([-1, 0, 1])
    current_height = max(3, min(6, current_height + delta))  # Clamp for natural variation

# Apply pixels: grass above the boundary, dirt below
for x in range(16):
    for y in range(16):
        if y < heights[x]:
            pixel = grass.getpixel((x, y))
        else:
            pixel = dirt.getpixel((x, y))
        side.putpixel((x, y), pixel)

# Save the result
side.save('grass_side_jagged.png')
print("Generated grass_side_jagged.png")