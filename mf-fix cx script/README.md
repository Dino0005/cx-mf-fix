# MF-Fix CrossOver Script

**English** | **[Italiano](README_IT.md)**

Command-line bash script to apply Media Foundation fixes to CrossOver bottles.

## Description

This script automates the installation of Windows Media Foundation DLLs into CrossOver bottles, enabling video playback in games that require native Media Foundation support.

**Prefer a graphical interface?** Use the [CX MF-Fix GUI app](https://github.com/Dino0005/cx-mf-fix).

## Requirements

- macOS
- CrossOver installed in `/Applications/CrossOver.app`
- Terminal/command-line access
- Administrator privileges (password may be required)

## Files Needed

The script requires these files in the same directory:

- `mf-fix-cx.sh` - The main script
- `system32/` - Folder with 64-bit DLLs
- `syswow64/` - Folder with 32-bit DLLs
- `mf.reg` - Registry file
- `wmf.reg` - Registry file

Download `mf-dlls.zip` from [Releases](../../releases) and extract it in the script directory.

## Installation

1. Download the script and required files
2. Extract `mf-dlls.zip` to get `system32/` and `syswow64/` folders
3. Place all files in the same directory
4. Make the script executable:

```bash
chmod +x mf-fix-cx.sh
```

## Usage

### Basic Usage

```bash
./mf-fix-cx.sh "/Users/MyUsername/Library/Application Support/CrossOver/Bottles/BottleName"
```

### Find Your Bottle Path

Your CrossOver bottles are typically located at:
```
~/Library/Application Support/CrossOver/Bottles/
```

List your bottles:
```bash
ls ~/Library/Application\ Support/CrossOver/Bottles/
```

### Full Example

```bash
# Navigate to the script directory
cd ~/Downloads/mf-fix-cx-script

# Make executable
chmod +x mf-fix-cx.sh

# Run the fix
./mf-fix-cx.sh "/Users/MyUsername/Library/Application Support/CrossOver/Bottles/MyGame"
```

## What the Script Does

1. Validates the bottle path
2. Copies 64-bit DLLs to `drive_c/windows/system32/`
3. Copies 32-bit DLLs to `drive_c/windows/syswow64/`
4. Sets Wine DLL overrides for Media Foundation libraries
5. Imports registry entries (`mf.reg`, `wmf.reg`)
6. Registers DLLs with RegSvr32

**Note**: You will see 3 RegSvr32 popup windows - click OK on each.

## Troubleshooting

### Invalid Bottle Error

Make sure the path points to a valid CrossOver bottle (must contain `drive_c` folder).

### Script Not Executable

```bash
chmod +x mf-fix-cx.sh
```

## Exit Codes

- `0` - Success
- `2` - Invalid directory path
- `3` - Wine prefix path not set
- `4` - Invalid Wine prefix (no `drive_c` folder)

## Help

View help message:
```bash
./mf-fix-cx.sh --help
```

## Comparison: Script vs GUI App

| Feature | Script | GUI App |
|---------|--------|---------|
| Interface | Terminal | Graphical |
| Progress | Text output | Real-time progress bar |
| Ease of use | Moderate | Easy |
| Automation | Scriptable | Manual |

## License

This script is part of the CX MF-Fix project, licensed under MIT License.

## Credits

- Based on the original mf-fix Proton bash script project from z0z0z, adapted for CrossOver on macOS

---

**Back to main project**: [CX MF-Fix](../)
