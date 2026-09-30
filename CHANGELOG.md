# Changelog

All notable fork-specific changes are documented here. Upstream Jitouch history
remains available in the repository's Git history.

## [2.82.1-firefox.1] - 2026-09-30

### Changed

- Allow configured three-finger horizontal trackpad swipes to be dispatched in
  Firefox.
- Keep Safari's upstream horizontal-swipe handling unchanged.
- Prefer `/Applications/Jitouch.app` from the preference pane while retaining the
  upstream embedded runtime as a fallback.

### Added

- Reproducible, ad-hoc-signed Release build script.
- Installer with fresh-install and upgrade paths.
- Gesture and preference backup, checksum, validation, and restoration.
- Optional Accessibility reset for locally rebuilt binaries.
- Dry-run, build-only, skip-build, and no-reset installer modes.
- CI build verification and issue templates.

### Distribution

- Source code only; no application or installer binaries are published.

[2.82.1-firefox.1]: https://github.com/jedrzejdrygas/Jitouch/compare/v2.82.1...v2.82.1-firefox.1
