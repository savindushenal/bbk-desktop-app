"""Create a simple icon file for the application"""
import struct

def create_minimal_ico(filename):
    """Create a minimal valid 16x16 ICO file"""
    # ICO header
    ico_header = struct.pack('<HHH', 0, 1, 1)  # Reserved, Type (1=ICO), Count
    
    # Image directory entry (16x16, 32-bit)
    width, height = 16, 16
    color_count = 0  # 0 for 32-bit
    reserved = 0
    color_planes = 1
    bits_per_pixel = 32
    
    # Create simple blue square with white B
    pixels = []
    for y in range(height):
        for x in range(width):
            # Blue background
            b, g, r, a = 185, 128, 41, 255
            
            # White 'B' letter (simplified)
            if 4 <= x <= 11 and 2 <= y <= 13:
                if x == 4 or (6 <= y <= 7) or y == 2 or y == 13:
                    b, g, r, a = 255, 255, 255, 255
                elif x == 11 and (3 <= y <= 6 or 8 <= y <= 12):
                    b, g, r, a = 255, 255, 255, 255
                    
            pixels.append(struct.pack('<BBBB', b, g, r, a))
    
    # AND mask (all transparent for 32-bit)
    and_mask = b'\x00' * ((width + 31) // 32 * 4 * height)
    
    # BMP info header
    bmp_info = struct.pack('<IIIHHIIIIII',
        40,  # Header size
        width,
        height * 2,  # Height is doubled in ICO
        1,  # Planes
        bits_per_pixel,
        0,  # Compression
        len(pixels) * 4 + len(and_mask),  # Image size
        0, 0, 0, 0  # Colors
    )
    
    image_data = bmp_info + b''.join(pixels) + and_mask
    image_size = len(image_data)
    image_offset = 6 + 16  # ICO header + directory entry
    
    directory_entry = struct.pack('<BBBBHHII',
        width, height, color_count, reserved,
        color_planes, bits_per_pixel,
        image_size, image_offset
    )
    
    # Write ICO file
    with open(filename, 'wb') as f:
        f.write(ico_header)
        f.write(directory_entry)
        f.write(image_data)
    
    print(f"Created {filename}")

if __name__ == '__main__':
    create_minimal_ico('resources/icon.ico')
