# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Asset pipeline integration for images (items, traders)
- `image_processing` gem for image optimization
- Bootsnap configuration for production
- Puma configuration with worker/thread tuning
- PostgreSQL connection tuning for Neon pooler

### Changed
- Images moved from `public/images/` to `app/assets/images/` with fingerprinting
- `ApplicationHelper` updated to use asset pipeline
- `HistoricalPurge` no longer deletes image files
- `neon:push` task hardened for pooled connections

### Removed
- `public/images/` directory (990MB) - moved to asset pipeline
- `local_image` helper and `LOCAL_IMAGE_CACHE`
- File deletion logic from `PresetCollapse` and `HistoricalPurge`

### Fixed
- `neon:push` now handles Neon pooler empty search_path
- Coverage threshold adjusted to 99.8% (realistic for string continuations)

## [1.2.0] - 2024-08-27

### Added
- Market price backfill via tarkov-market API
- Route-based item purge (removes items without money/barter/craft routes)
- Single-category enforcement with precedence
- Live JSON.tarkov.dev snapshot refresh rake task

### Changed
- Single-category enforcement with precedence (grenades > ammo > gun > ...)
- Item purge now removes items without money/barter/craft routes
- Syncer steps include market sync after crafts

### Removed
- Category protection list (medical, grenades, provisions, containers)

## [1.1.0] - 2024-08-20

### Added
- Category derivation with precedence logic
- Barter sync from json.tarkov.dev
- Craft sync from json.tarkov.dev

### Changed
- Category derivation from single to multi-category (temporarily)

## [1.0.0] - 2024-08-15

### Added
- Initial release
- Item, Task, Trader sync from json.tarkov.dev
- Barter and Craft sync
- Basic web UI for items/tasks/traders