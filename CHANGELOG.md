# Changelog

All notable changes to Mount Watchlist will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project uses semantic versioning where practical.

## [Unreleased]

### Added

### Changed

### Fixed

---

## [0.3.0] - 2026-08-17

### Added

- Added source filters for:
  - Drop
  - Vendor
  - Achievement
  - Quest
  - Profession
- Added Ctrl + Left Click mount preview using the Dressing Room.
- Added a tooltip hint for Dressing Room previews.

### Changed

- Increased the size of the main Mount Watchlist window.
- Moved mount acquisition and description text into a scrollable details area.

### Fixed

- Fixed mount list rows extending underneath the selected mount details panel.
- Fixed long source descriptions overflowing outside the addon window.

## [0.2.0] - 2026-08-17

### Added

- Added a Watch Mount button directly to the default Mount Journal.
- Added support for removing tracked mounts from the Mount Journal.

### Changed

- Replaced the custom scrolling implementation with Blizzard's ScrollBox system.
- Changed the uncollected mount list to alphabetical sorting.

### Fixed

- Fixed the uncollected mounts list stopping after the first visible rows.
- Fixed only the first source category appearing to be available.

## [0.1.0] - 2026-08-17

### Added

- Initial release.
- Added a standalone Mount Watchlist window.
- Added uncollected mount browsing.
- Added mount search.
- Added persistent account-wide watchlist.
- Added Blizzard Mount Journal source information.
- Added automatic removal of collected mounts.