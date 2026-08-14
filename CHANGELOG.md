# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.2] - 2026-08-14
### Fixed
- MF Fix: replaced nine separate `reg add` calls with a single `.reg` file import for DLL overrides — faster and more reliable
- MF Fix: use full Windows paths (`C:\windows\regedit.exe`, `C:\windows\system32\regsvr32.exe`) for compatibility with CrossOver's `--cx-app` wrapper
- MF Fix: registry files (`mf.reg`, `wmf.reg`) are now imported in both 64-bit and 32-bit architectures — previously 32-bit games could not enumerate Media Foundation handlers
- MF Fix: COM components (`colorcnv`, `msmpeg2adec`, `msmpeg2vdec`) are now registered with `regsvr32` in both 64-bit and 32-bit — registering `msmpeg2vdec` in 32-bit writes the H.264 decoder's `InputTypes`/`OutputTypes`, fixing black video in 32-bit games
- MF Fix: removed incorrect popup warning from UI and progress log

### Changed
- Bundled GStreamer updated from 1.28.3 to 1.28.6

## [1.1.1] - 2026-06-11

### Added
- GStreamer Patch tab improvements:
  - CrossOver version is now displayed next to the selected app name
  - The backup badge now shows the CrossOver version the backup was created from
  - Backup version badge separated from the selector pane
  - Version mismatch detection: if the selected CrossOver version differs from the one the backup was created with, a warning prompts the user to delete the incompatible backup before applying a fresh patch

## [1.1.0] - 2026-05-23

### Added
- GStreamer Patch tab: apply and restore GStreamer libraries directly to CrossOver.app
- Tab bar navigation to switch between MF Fix and GStreamer Patch
- NSOpenPanel-based CrossOver.app selector (grants write access without disabling SIP)
- Smart backup system: snapshot of original lib64 state before patching
- Automatic backup restore: overwrites modified files and removes added ones
- Backup moved to Trash after successful restore, ready for a fresh patch
- Support for subdirectories in GStreamer zip
- Correct symlink handling during copy (real files copied first, symlinks recreated last)
- Backup stored in ~/Library/Application Support/CXMFFix/Backup_GStreamer.zip

### Changed
- Patch/Restore buttons are mutually exclusive based on backup state: Apply Patch shown when no backup exists, Restore shown when backup is present
- Tab bar replaces single-view layout

### Fixed
- libffi.dylib copy failure caused by symlink resolution order

## [1.0.0] - 2026-02-21

### Added
- Initial release
- Native macOS SwiftUI interface
- Drag and drop support for CrossOver bottles
- Real-time progress tracking with detailed logs
- Automatic extraction and installation of Media Foundation DLLs (32-bit (syswow64) and 64-bit (system32) DLLs)
- Registry file import (mf.reg, wmf.reg)
- DLL registration with RegSvr32
- Administrator privilege handling with password prompt
- Log export functionality
- "New Fix" button to process multiple bottles
- Multilingual support (English and Italian)
- Custom file picker that opens directly in Bottles directory
- Success/error alerts with localized messages
- Modern macOS design with custom icon

### Features
- Automatically handles symbolic links and file permissions
- Progress bar showing completion percentage
- Scrollable log with emoji indicators (✓, ❌, ⚠️, 🔐, ℹ️, ✅)
- Text-selectable logs for easy copying
- Safe cleanup of temporary files
- Validates bottle structure before processing
