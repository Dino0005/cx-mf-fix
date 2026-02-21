# CX MF-Fix

![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift: 6.2](https://img.shields.io/badge/Swift-6.2-orange)
![Xcode: 26.2](https://img.shields.io/badge/Xcode-26.2-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

A native macOS application to apply Media Foundation fixes to CrossOver bottles.

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot CX mf-fix.png" width="70%">
</p>


## Background

### The Media Foundation Problem

The lack of native support for Windows Media Foundation (MF) codecs in CrossOver prevents video playback in many modern games, especially those built with Unreal Engine.

CrossOver uses libraries called `.dylib` (macOS binary format) to handle audio and video. However, these libraries often fail to correctly "translate" the calls that Windows games make to Media Foundation APIs.

### GStreamer

While CrossOver includes GStreamer support, it currently cannot decode all proprietary video formats used in modern AAA games. This is due to codec licensing constraints and the ongoing development of the Media Foundation translation layer.

### Available Solutions

**CXPatcher:** Replaces older libraries in CrossOver with newer versions, including fixes for GStreamer and Media Foundation, so that games like the Resident Evil series can play cutscenes instead of freezing on a black screen.

**mf-fix (this project):** Installs the original Windows Media Foundation DLLs directly into the CrossOver "bottle". When the game tries to start a cutscene, it finds the libraries it expects (the DLLs) and the video plays. This solves freezes or black screens at game startup or during loading screens.

This application provides a native macOS graphical interface for the mf-fix approach, making it easier to apply the fix without using Terminal commands.

## Features

- 🎨 **Native macOS Interface** - Beautiful SwiftUI interface with drag & drop support
- 🌍 **Multilingual** - Supports English and Italian
- 📊 **Real-time Progress** - See exactly what's happening with live log updates
- 🔐 **Secure** - Automatically handles administrator privileges when needed
- 💾 **Save Logs** - Export process logs for troubleshooting
- ⚡ **Fast & Efficient** - Modern Swift implementation

## Requirements

### For Users
- **macOS**: 15.0 or later recommended
- **CrossOver**: Installed in `/Applications/CrossOver.app`

### For Developers (Building from source)
- **Xcode**: 26.2+
- **Swift**: 6.2+
- **Architecture**: Apple Silicon (arm64)

## Installation

### Option 1: Download Pre-built App (Recommended)

1. Download the latest release from [Releases](../../releases)
2. Move `CX mf-fix.app` to your Applications folder
3. **First time only**: open the app, If you see the error "Impossibile aprire l'applicazione" (Unable to open the application), it's because macOS blocks unsigned apps.
To fix this, open Terminal and run:
   ```bash
     sudo xattr -r -d com.apple.quarantine "/Applications/CX mf-fix.app"
   ```

### Option 2: Build from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/Dino0005/cx-mf-fix.git
   cd cx-mf-fix
   ```

2. Open `CX mf-fix.xcodeproj` in Xcode

3. Build and run (⌘+R)

## Usage

1. Launch the app
2. Drag your CrossOver bottle folder into the drop zone
   - Or click to select it in Finder
   - Bottles are typically located in: `~/Library/Application Support/CrossOver/Bottles/`
3. Click "Apply Fix"
4. Confirm the information dialog
5. Click OK on the 3 RegSvr32 popup windows that appear (These popups are normal as Wine is registering the new DLLs in the bottle's environment)
6. Wait for completion
7. Done! Your bottle now has Media Foundation support

## How It Works

The app performs the following steps:

1. Extracts Media Foundation DLL files from the embedded archive
2. Copies 64-bit DLLs to `drive_c/windows/system32/`
3. Copies 32-bit DLLs to `drive_c/windows/syswow64/`
4. Configures Wine DLL overrides
5. Imports required registry entries
6. Registers the DLLs with the system

## Building

Building with Xcode

### Prerequisites

- macOS 26.0+
- Xcode 26.0+
- Required files from mf-fix project:
  - `mf-dlls.zip` .zip file with DLL file folders (`system32/` and `syswow64/`)
  - `mf.reg` registry file
  - `wmf.reg` registry file

Note: These required files are already included in the Resources folder of the project

## Localization

The app supports multiple languages:
- 🇬🇧 English
- 🇮🇹 Italian

To add more languages:
1. Open `Localizable.xcstrings` in Xcode
2. Click the "+" next to Localizations
3. Select your language and translate all strings

## Troubleshooting

### App Won't Open

**Solution (Terminal):**
```bash
sudo xattr -r -d com.apple.quarantine "/Applications/CX mf-fix.app"
```

### "Invalid CrossOver bottle" Error

- Make sure you selected the correct bottle folder (it must contain a `drive_c` folder)
- Typical path: `~/Library/Application Support/CrossOver/Bottles/YourBottleName`

### Fix Fails

- Check the log output for specific errors
- Use the "Save Log" button to export the log
- Make sure CrossOver is installed in `/Applications/CrossOver.app`
- Ensure you have write permissions to the bottle folder

## Technical Details

The application performs the following steps to enable Media Foundation support:

1. **Extraction**: Unpacks the embedded `mf-dlls.zip` containing:
   - 64-bit DLLs for `system32/`
   - 32-bit DLLs for `syswow64/`

2. **Installation**: Copies DLLs to the appropriate Wine system directories:
   - `drive_c/windows/system32/` (64-bit versions)
   - `drive_c/windows/syswow64/` (32-bit versions)

3. **Configuration**: Sets Wine DLL overrides to use native Windows implementations:
   - `colorcnv`, `mf`, `mferror`, `mfplat`, `mfplay`
   - `mfreadwrite`, `msmpeg2adec`, `msmpeg2vdec`, `sqmapi`

4. **Registry**: Imports required registry entries (`mf.reg`, `wmf.reg`) for Media Foundation initialization

5. **Registration**: Registers the DLLs with RegSvr32:
   - `colorcnv.dll`
   - `msmpeg2adec.dll` (MPEG-2 audio decoder)
   - `msmpeg2vdec.dll` (MPEG-2 video decoder)

This ensures that when a game makes Media Foundation API calls, the original Windows DLLs handle the requests, providing full codec support.

## Legal Notice

### Media Foundation Files

The Media Foundation DLL files included in this project are extracted from **Windows 7 Service Pack 1 (KB976932)**, a public update freely distributed by Microsoft. These files are included solely for compatibility purposes with Wine/CrossOver environments.

**Source:** Windows 7 SP1 Platform Update (KB976932)  
**Purpose:** Enable video playback compatibility in games running through CrossOver  
**License Compliance:** Users are responsible for ensuring their use complies with Microsoft's licensing terms

### Third-Party Credits

- Original **mf-fix** Proton bash script concept by z0z0z
- Windows Media Foundation libraries © Microsoft Corporation

**Disclaimer:** This is an unofficial tool and is not affiliated with, endorsed by, or supported by CodeWeavers or Microsoft. Use at your own risk. Always backup your CrossOver bottles before applying modifications.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

