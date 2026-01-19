#!/usr/bin/env python3
"""
Generate PopMatch app icon with red clapperboard design
"""

from PIL import Image, ImageDraw
import os

def create_icon(size):
    """Create an icon of the specified size"""
    # Create image with red background
    img = Image.new('RGBA', (size, size), (229, 62, 62, 255))  # Red background
    draw = ImageDraw.Draw(img)
    
    # Calculate proportions
    clapperboard_size = int(size * 0.6)
    clapperboard_x = (size - clapperboard_size) // 2
    clapperboard_y = (size - clapperboard_size) // 2
    
    # Draw white clapperboard body
    body_width = clapperboard_size
    body_height = int(clapperboard_size * 0.7)
    draw.rectangle([clapperboard_x, clapperboard_y, 
                   clapperboard_x + body_width, clapperboard_y + body_height], 
                  fill='white')
    
    # Draw black stripes
    stripe_width = int(clapperboard_size * 0.08)
    stripe_spacing = int(clapperboard_size * 0.15)
    stripe_height = int(clapperboard_size * 0.5)
    stripe_y = clapperboard_y + int(clapperboard_size * 0.1)
    
    for i in range(3):
        stripe_x = clapperboard_x + (i * stripe_spacing)
        draw.rectangle([stripe_x, stripe_y, 
                       stripe_x + stripe_width, stripe_y + stripe_height], 
                      fill='black')
    
    # Draw white handle
    handle_width = int(clapperboard_size * 0.8)
    handle_height = int(clapperboard_size * 0.15)
    handle_x = clapperboard_x + int(clapperboard_size * 0.1)
    handle_y = clapperboard_y + int(clapperboard_size * 0.8)
    draw.rectangle([handle_x, handle_y, 
                   handle_x + handle_width, handle_y + handle_height], 
                  fill='white')
    
    return img

def main():
    print("🎬 Generating PopMatch app icons...")
    
    # iOS icon sizes
    ios_sizes = [20, 29, 40, 60, 76, 83, 1024]
    
    # Create iOS icons directory
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_dir, exist_ok=True)
    
    # Generate iOS icons
    for size in ios_sizes:
        icon = create_icon(size)
        filename = f"Icon-App-{size}x{size}@1x.png"
        filepath = os.path.join(ios_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Generated: {filename} ({size}x{size})")
    
    # Android icon sizes
    android_sizes = [48, 72, 96, 144, 192]
    
    # Create Android icons directory
    android_dir = "android/app/src/main/res"
    os.makedirs(android_dir, exist_ok=True)
    
    # Generate Android icons
    for size in android_sizes:
        icon = create_icon(size)
        filename = f"ic_launcher_{size}.png"
        filepath = os.path.join(android_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Generated: {filename} ({size}x{size})")
    
    print("✅ App icons generated successfully!")

if __name__ == "__main__":
    main() 