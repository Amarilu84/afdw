# Changelog

All notable changes to this project will be documented in this file.  
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.2] - 2025-09-12
### Added
- Improved dependency checks and clearer README instructions for first-time users.
- Enhanced unmount logic: recursive unmount + lazy fallback for stubborn mounts.
- Double-confirmation safety flow refined (full path + explicit `ERASE` keyword).
- Additional error handling and user feedback messages.

### Changed
- Reorganized and simplified code structure for readability.
- Adjusted script to run cleanly under `bash` (instead of default `/bin/sh`).
- Updated README.md with usage instructions and quickstart notes.

---

## [1.1] - 2025-09-10
### Added
- Flush and sync step before unmount to ensure all writes are committed.
- Initial README.md with TL;DR and usage overview.

### Changed
- Streamlined prompts and confirmations to reduce accidental misuse.
- Minor code cleanups and comments for maintainability.

---

## [1.0] - 2025-09-08
### Added
- Initial release of **AFDW (Anti-Forensic Drive Wiper)**.
- Core functionality:  
  - Detect and list disks.  
  - Require full-path confirmation.  
  - Securely wipe drives using multiple passes.  
  - Basic unmounting routine.  
- MIT license.
