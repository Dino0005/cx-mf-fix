# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
