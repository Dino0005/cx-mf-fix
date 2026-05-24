# CX MF-Fix

![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey)
![Swift: 6.3.2](https://img.shields.io/badge/Swift-6.3.2-orange)
![Xcode: 26.5](https://img.shields.io/badge/Xcode-26.5-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

**English** | **[Italiano](README_IT.md)**

A native macOS application to apply Media Foundation fixes to CrossOver bottles.

<table align="center">
  <tr>
    <td align="center" width="50%">
      <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot%20CX%20mf-fix.png" width="100%">
    </td>
    <td align="center" width="50%">
      <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot%20CX%20GS.png" width="100%">
    </td>
  </tr>
</table>

## Background

### The Media Foundation Problem

The lack of native support for Windows Media Foundation (MF) codecs in CrossOver prevents video playback in many modern games, especially those built with Unreal Engine.

CrossOver uses libraries called `.dylib` (macOS binary format) to handle audio and video. However, these libraries often fail to correctly "translate" the calls that Windows games make to Media Foundation APIs.

### GStreamer

GStreamer is an open-source multimedia framework used by operating systems and applications to manage the reading, decoding, and playback of audio and video streams.
While CrossOver includes GStreamer support, it currently cannot decode all proprietary video formats used in modern AAA games. This is due to codec licensing constraints and the ongoing development of the Media Foundation translation layer.

### Available Solutions

**CXPatcher:** Replaces older libraries in CrossOver with newer versions, including fixes for GStreamer and Media Foundation, so that games like the Resident Evil series can play cutscenes instead of freezing on a black screen. CXPatcher does not install GStreamer itself, but verifies whether the official GStreamer version is installed on the Mac. If detected, it neutralizes the existing GStreamer files within CrossOver by renaming them with the `_disabled` suffix, hiding these libraries from CrossOver to force the application to use the external, more complete version

**mf-fix:** Installs the original Windows Media Foundation DLLs directly into the CrossOver "bottle". When the game tries to start a cutscene, it finds the libraries it expects (the DLLs) and the video plays. This solves freezes or black screens at game startup or during loading screens.

### Why This Tool?

As stated by [CodeWeavers support](https://www.codeweavers.com/support/forums/general/?t=27;msg=260263), while Wine (and thus CrossOver) has its own implementation of Media Foundation, it is still a work in progress and cannot yet decode all proprietary video formats used in modern AAA games. CodeWeavers cannot support or distribute native Windows Media Foundation libraries due to licensing restrictions.

**CX MF-Fix** bridges this gap by allowing users to choose between two different methods: **mf-fix** or the **GStreamer patch**.

- **MF Fix:** Manually installs the native Windows DLLs directly into the game's bottle. This provides full compatibility with games that Wine's built-in implementation cannot yet handle. (**Note**: This fix is applied to a single bottle)
- **GStreamer patch:** Replaces the pre-installed GStreamer libraries inside CrossOver with a custom, comprehensive version containing all proprietary plugins and decoders (Good, Bad, and Ugly). This unlocks video and cutscene playback across your games. (**Note**: This patch modifies CrossOver's application files)

This application provides a native macOS graphical interface for making it easier to apply the fix without using Terminal commands.

> **Note:** This is an unofficial tool. It is not affiliated with, endorsed by, or supported by CodeWeavers or Microsoft.

### Tested Games

See [**GAMES.md**](GAMES.md) for a list of games tested and confirmed working with this fix.

## Features

- 🎨 **Native macOS Interface** - Beautiful SwiftUI interface with drag & drop support
- 🌍 **Multilingual** - Supports English and Italian
- 📊 **Real-time Progress** - See exactly what's happening with live log updates
- 🔐 **Secure** - Automatically handles administrator privileges when needed
- 💾 **Save Logs** - Export process logs for troubleshooting
- ⚡ **Fast & Efficient** - Modern Swift implementation

## Requirements

### For Users
- **macOS**: 13.0 or later recommended
- **CrossOver**: Installed in `/Applications/CrossOver.app`

### For Developers (Building from source)
- **Xcode**: 26.5+
- **Swift**: 6.3+
- **Architecture**: Apple Silicon (arm64)

## Installation

### Option 1: Download Pre-built App (Recommended)

1. Download the latest release from [Releases](../../releases)
2. Move `CX mf-fix.app` to your Applications folder
3. **First time only**: open the app, If you see the error "Unable to open the application", it's because macOS blocks unsigned apps.
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

### MF Fix

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot CX mf-fix.png" width="70%">
</p>

1. Launch the app
2. Drag your CrossOver bottle folder into the drop zone
   - Or click to select it in Finder
   - Bottles are typically located in: `~/Library/Application Support/CrossOver/Bottles/`
3. Click "Apply Fix"
4. Confirm the information dialog
5. Click OK on the 3 RegSvr32 popup windows that appear (These popups are normal as Wine is registering the new DLLs in the bottle's environment)
6. Wait for completion
7. Done! Your bottle now has Media Foundation support

### How MF Fix Works

The app performs the following steps:

1. Extracts Media Foundation DLL files from the embedded archive
2. Copies 64-bit DLLs to `drive_c/windows/system32/`
3. Copies 32-bit DLLs to `drive_c/windows/syswow64/`
4. Configures Wine DLL overrides
5. Imports required registry entries
6. Registers the DLLs with the system

##

### GStreamer patch

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/Screenshot CX GS.png" width="70%">
</p>

1. Launch the app.
2. Click "Select CrossOver" to choose the main CrossOver application.
   - The panel will open directly in the `/Applications` folder for convenience.
   - A quick check is performed automatically to ensure the selected CrossOver version is compatible.
3. Click "Apply Patch".
4. Confirm the informational dialog box.
5. Wait for the process to finish while monitoring the real-time progress log.
6. Done! CrossOver is now patched and ready to launch games with extended support for proprietary codecs.
7. *(Optional)* In case of any issues, if a backup is available, you can click "Restore" at any time to revert CrossOver to its original state.

### How GStreamer Patch Works

The app performs the following steps:

1. **Verification & Validation:** Checks for the required internal CrossOver directories (specifically `lib64`) to confirm compatibility.
2. **Resource Extraction:** Extracts the embedded `gstreamer.zip` archive from the app bundle into a temporary macOS directory.
3. **Snapshot & Automatic Backup:** Generates a snapshot list of the original CrossOver files and creates a compressed backup archive (`Backup_GStreamer.zip`) inside `~/Library/Application Support/CXMFFix/`, saving only the files that are about to be overwritten.
4. **Library Update:** Replaces and injects the newly optimized `.dylib` files directly into the `Contents/SharedSupport/CrossOver/lib64/` directory of the CrossOver application.
5. **Plugin Installation:** Updates the internal `gstreamer-1.0` folder with the new proprietary decoders required to unlock audio and video playback in games.

## Building with Xcode

To correctly compile the project, ensure that you include the following required files within the application bundle:

* **`gstreamer.zip`**: A compressed archive containing the custom, optimized multimedia library structure. Inside, it includes:
  * The main GStreamer `.dylib` binary files (e.g., `libgstreamer-1.0.dylib`, `libglib-2.0.dylib`, etc.) targetec for the `lib64` root directory.
  * The `gstreamer-1.0/` subfolder containing the complete set of proprietary plugins and decoders (Good, Bad, and Ugly).
* **`mf-dlls.zip`**: A compressed archive containing the native Windows DLL directories, structured as follows:
  * `system32/`: containing the 64-bit DLL files.
  * `syswow64/`: containing the 32-bit DLL files.
* **`mf.reg`**: A registry configuration file used to initialize core Media Foundation components.
* **`wmf.reg`**: A registry configuration file specifically tailored for Windows Media Format overrides and codecs.

**Note**: The `gstreamer.zip` and `mf-dlls.zip` files are not included directly within the project's resources folder. However, for your convenience, they are available inside the precompiled release package under the [Assets](../../releases/latest) section (remember to copy `gstreamer.zip` and `mf-dlls.zip` into the `CXMFFix` project resources folder before starting the compilation).

<p align="center">
  <img src="https://raw.githubusercontent.com/Dino0005/cx-mf-fix/main/images/files_project.png" width="40%">
</p>

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

### Will the fix persist after a CrossOver update?

Updating CrossOver (e.g., from version 25 to 25.1 or 26) may reset the bottle configuration. If videos stop working after an update, simply re-apply the fix using this app to restore functionality.

## Technical Details

**MF-Fix** performs the following steps to enable Media Foundation support:

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

**GStreamer patch** performs the following steps to upgrade CrossOver's multimedia framework:

1. **Validation**: Verifies the integrity of the selected CrossOver application bundle, ensuring the internal `Contents/SharedSupport/CrossOver/lib64/` directory is present.
2. **Temporary Extraction**: Extracts the embedded `gstreamer.zip` file (approx. 211 MB) into an isolated temporary subfolder generated inside `NSTemporaryDirectory()`.
3. **Snapshot & Backup**: Scans the original CrossOver structure to create a text-based snapshot of existing files (`.dylib` files in both the root and plugins folders). It then creates a compressed backup archive (`Backup_GStreamer.zip`) inside `Application Support`, saving only the native files that are about to be overwritten.
4. **Binary Update (lib64)**: Removes old binaries and copies the newly optimized main GStreamer `.dylib` libraries directly into the root of CrossOver's `lib64/` directory.
5. **Plugin Injection (gstreamer-1.0)**: Ensures the `gstreamer-1.0/` folder exists within `lib64/` and injects the complete updated set of proprietary plugins and decoders (Good, Bad, and Ugly).

This approach directly modifies CrossOver's global multimedia engine rather than a single bottle, unlocking upstream decoding for proprietary video and audio formats that Wine cannot yet translate natively.

## Legal Notes

### Media Foundation Files

The Media Foundation DLL files included in this project are extracted from **Windows 7 Service Pack 1 (KB976932)**, a public update distributed freely by Microsoft. These files are included solely for compatibility purposes within Wine/CrossOver environments.

* **Source:** Windows 7 SP1 Platform Update (KB976932)  
* **Purpose:** To enable video playback compatibility in games running via CrossOver  
* **License Compliance:** Users are responsible for ensuring that their usage complies with Microsoft's licensing terms.

### GStreamer Licensing

The GStreamer patch included in this tool utilizes the **GStreamer** multimedia framework, which is distributed primarily under the terms of the **GNU Lesser General Public License (LGPL) version 2.1**.

* **LGPL Compliance:** This project only distributes precompiled binary files extracted from the official GStreamer installer, acting as a third-party installer/extractor. In compliance with the LGPL license, users retain the right and technical ability to replace the provided libraries with custom or self-compiled versions. The original, unmodified source code for the framework is available on the official GStreamer project website.
* **Patent Caution (Proprietary Codecs):** Certain included optional packages and plugins (such as those implementing multimedia standard formats like MPEG-2 video/audio, H.264, MP3, AC3, etc.) may be subject to software patent restrictions depending on the country where the software is used. This software is provided "as-is", without any warranty whatsoever. It is the sole responsibility of the end-user to ensure that their usage and distribution of these components comply with local patent laws and to obtain any required licenses from the respective patent holders.

### Third-Party Credits

* Original Proton **mf-fix** bash script by z0z0z.
* Windows Media Foundation libraries © Microsoft Corporation.
* **GStreamer** multimedia framework (https://gstreamer.freedesktop.org) © GStreamer project contributors.

**Disclaimer:** This is an unofficial tool and is not affiliated with, authorized, endorsed, or supported by CodeWeavers or Microsoft. Use it at your own risk. Always back up your CrossOver bottles and application files before applying any modifications.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

