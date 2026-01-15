# BBK Hardware Bridge - Icon Information

Since we cannot create actual .ico files with code, you have a few options:

## Option 1: Use Online Icon Converter
1. Create a logo image (PNG, JPG) for BBK Gym
2. Visit: https://www.icoconverter.com/
3. Upload your image and convert to .ico format
4. Save as `resources/icon.ico`

## Option 2: Use Existing Windows Icons
The start.bat and shortcuts will work fine without a custom icon.
Windows will use the default batch file icon.

## Option 3: Extract Icon from Existing App
If you have a BBK logo or gym software icon:
1. Use a tool like Resource Hacker (free)
2. Extract the .ico file
3. Place in `resources/icon.ico`

## Recommended Icon Design
- **Size**: 256x256px (will be scaled down automatically)
- **Format**: .ico (supports multiple sizes in one file)
- **Content**: BBK logo, gym dumbbell, fingerprint symbol
- **Colors**: Match your brand (blue/green suggested)
- **Background**: Transparent preferred

## File Location
Place your icon as:
```
bbk-desktop-app/
  resources/
    icon.ico   <-- Your custom icon here
```

Once you add icon.ico, the desktop shortcut will automatically use it!
