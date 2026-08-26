# 75 Feature Ideas for Tarkov DB

A comprehensive brainstorm for expanding the Tarkov reference database into a full-featured companion platform. Every idea is scoped to a single-player, non-commercial reference tool — no game API calls, no real-money integration, no cheating assistance.

---

## Backend (30 Ideas)

### 1. Ammo Price Tracker

Scrape or periodically import ammo prices from tarkov-market or similar community APIs. Store historical price snapshots per ammo type (e.g., M855, 7.62 BP) and compute rolling averages. Expose a `GET /api/ammo/:tid/history` endpoint returning JSON with daily/weekly/monthly price series. This lets the frontend render price trend charts without hitting third-party APIs on every page load. Consider a `cron`-style Rake task (`tarkov:prices:update`) that runs nightly and appends to an `ammo_prices` table with columns: `item_tid, price_rub, price_usd, recorded_at`. Retain 90 days of history, purge older rows on each run.

### 2. Quest Reward Optimizer

Given a target item the player wants (e.g., "Items case"), reverse-engineer the cheapest path to obtain it: which quests reward it, what are the quest prerequisites, what items are needed for those prerequisites, and what is the total RUB cost of those items at current prices. Store this as a computed graph in the backend — a `QuestRewardOptimizer` service that accepts a target `item_tid` and returns an ordered list of quest chains with cumulative cost. Cache the result per item and invalidate when task or item data changes.

### 3. Armor vs. Ammo Penetration Simulator

Build a deterministic damage model using BSG's published penetration formulas. Given an armor class, durability, and ammo type, compute the probability of penetration, expected damage, and bleed chance. Store the formulas in `Tarkov::Ballistics` and expose a `POST /api/simulate` endpoint accepting `{ armor_tid, ammo_tid, durability }` and returning `{ penetration_pct, expected_damage, shots_to_kill }`. The model should handle edge cases like zero-durability armor, subsonic rounds, and shotgun pellets.

### 4. Hideout Upgrade Planner

Model the hideout as a directed acyclic graph: each station (e.g., "Intelligence Center L3") has prerequisites (other stations at specific levels) and material requirements (specific items with counts). Expose a `GET /api/hideout/plan?target=station&level=3` endpoint that returns a topologically-sorted list of all upgrades needed, total material counts, and estimated RUB cost. Persist the hideout structure as JSON in the client payload and parse it into `HideoutStation` and `HideoutRequirement` models during sync.

### 5. Dynamic Pricing Integration

Integrate with tarkov-market.com or tarkov.dev to pull real-time item prices. Create a `PricingSource` abstraction with implementations for each data provider, a rate limiter, and a caching layer. Store the latest price alongside each item (`items.price_rub`, `items.price_usd`, `items.price_updated_at`). A background job (`Tarkov::PricingJob`) runs every 6 hours, fetches prices, and writes to the database. Expose `GET /api/prices` with optional `?category=` and `?sort=price_asc` filters.

### 6. Gunsmith Task Part Matcher

Gunsmith quests require specific weapon builds. For each gunsmith task, store the required configuration (specific parts, no more/less). Build a `GunsmithMatcher` service that, given a player's current weapon build (list of part tids), computes the "closeness" to each gunsmith requirement: which parts match, which are wrong, and which are missing. Expose `POST /api/gunsmith/match` returning `{ task_tid, matched_parts, missing_parts, extra_parts, completion_pct }`.

### 7. Boss Drop Table Lookup

Model boss-specific loot tables: which bosses spawn on which maps, what unique items they carry (e.g., Reshala's golden TT, Killa's/tags), and the approximate drop rates. Store as `BossSpawn` and `BossDrop` records synced from the API payload or a curated JSON file. Expose `GET /api/bosses/:tid/drops` returning a list of items with drop rate percentages and spawn locations.

### 8. Scav Karma Tracker

Model the karma system: which actions increase/decrease karma (killing PMCs vs. Scavs, helping players, extracting with USB drives to Ref), what rewards each karma tier unlocks (scav case discounts, better Scav loadouts, Fence rep levels). Store as a reference lookup table. Expose `GET /api/karma/actions` and `GET /api/karma/rewards` for the frontend to render a karma guide.

### 9. Daily/Weekly Quest Rotation Tracker

Track the rotating daily and weekly barters/tasks that change with each server reset. Store the current rotation in a `DailyRotation` model with columns: `rotation_type, item_tid, task_tid, trader_tid, expires_at`. A Rake task (`tarkov:rotations:refresh`) runs every 24 hours and updates the rotation. Expose `GET /api/rotations?type=daily` for the frontend to display "today's deals."

### 10. Wipe History and Item Availability Tracker

Record which items were available in which wipes. Store wipe metadata (`wipes` table: `id, version, started_at, ended_at`) and cross-reference with item availability (`item_wipes` join table: `item_tid, wipe_id, was_available`). This enables queries like "Was the GPU available in wipe 13?" and "How many wipes has the red keycard been available?"

### 11. Bullet Trajectory Calculator

Implement a simplified external ballistics model: given ammo type, muzzle velocity, zeroing distance, and target distance, compute bullet drop (MOA/MRAD), flight time, and retained energy. Use published muzzle velocities and ballistic coefficients. Expose `POST /api/ballistics` returning `{ drop_inches, drop_moa, flight_time_ms, energy_joules }`. This helps players adjust scopes for long-range shots.

### 12. Medical Item Effectiveness Database

Model every medical item's healing properties: hp_restore, bleedstop_chance, clamp_bones, use_time, and debuff penalties (e.g., painkiller fatigue). Store as `MedicalItem` records with columns for each property. Expose `GET /api/medical` with filters for bleed treatment, bone treatment, and use time. Include a "field hospital" comparison tool: given a list of injuries (bleeds, fractures, pain), compute the optimal healing order and total time.

### 13. Grenade Damage Radius Calculator

Model grenade blast radii: M67, VOG-25, F-1, RGD-5, M61, Zarya, impact grenades. Store each grenade's `max_damage, min_damage, fuse_time, radius, fragmentation_pattern`. Expose `POST /api/grenades/simulate` accepting `{ grenade_tid, target_distance, armor_tid }` returning `{ expected_damage, kill_probability, stun_duration }`.

### 14. Insurance Value Estimator

Given a loadout (list of item tids with quantities), compute the total insurance cost from each trader (Prapor, Therapist) based on item values and trader loyalty level. Expose `POST /api/insurance/estimate` returning `{ prapor_cost, therapist_cost, recommended_trader, total_loadout_value }`. Use the insurance formula: `cost = base_insurance_rate * item_value * loyalty_modifier`.

### 15. Flea Market Fee Calculator

Model the flea market listing fee formula: `fee = base_fee + (value * fee_percentage) + (quantity - 1) * per_unit_fee`. Different fee rates apply for different item categories. Expose `POST /api/flea/fee` accepting `{ item_tid, value, quantity }` returning `{ listing_fee, profit_after_fee, fee_percentage }`. Help players optimize their listing prices.

### 16. Trader Level Requirement Calculator

Given a target trader loyalty level, compute all prerequisites: player level, reputation, spent amount, completed tasks, and required items. Expose `GET /api/traders/:tid/requirements?level=4` returning a checklist of everything needed. Cross-reference with the player's current state (if a player profile feature is added later).

### 17. Loadout Cost Optimizer

Given a desired loadout type (e.g., "budget assault rifle"), find the cheapest combination of weapon + attachments + ammo + armor + rig + backpack that meets minimum performance thresholds (e.g., "ergonomics > 50", "recoil < 250"). This is a constrained optimization problem — use a greedy algorithm or dynamic programming approach. Expose `POST /api/loadouts/optimize` returning the cheapest loadout that satisfies the constraints.

### 18. Ballistics Reference Table Generator

Pre-compute and cache a full ballistics reference table: every ammo type × every armor class × every durability level → penetration probability. Store as a materialized view or a denormalized `ballistics_cache` table. Refresh when ammo or armor stats change. Expose `GET /api/ballistics/table?ammo_caliber=556x45&armor_class=5` for fast table lookups without per-request simulation.

### 19. Map Extraction Point Database

Model every map's extraction points: PMC extracts (conditional and unconditional), Scav extracts, co-op extracts, and危险 extracts. Store as `ExtractionPoint` records with columns: `map_name, point_name, extract_type, is_conditional, conditions, video_url, map_image_url`. Expose `GET /api/maps/:name/extracts` returning a list of extraction points grouped by type.

### 20. Key Loot Room Database

Model which keys open which rooms and what loot spawns in each room. Store as `KeyRoom` records linking `key_tid` → `room_id` → `loot_items[]`. Include spawn chance percentages. Expose `GET /api/keys/:tid/rooms` returning rooms opened by that key, their locations, and average loot value. Expose `GET /api/maps/:name/rooms` for all loot rooms on a map.

### 21. Barters Alternative Finder

Given a target item, find all ways to obtain it: direct purchase, barter, craft, or quest reward. Compute the cheapest path for each method using current prices. Expose `GET /api/items/:tid/sources` returning `{ direct_purchase: [...], barters: [...], crafts: [...], quest_rewards: [...] }` each sorted by estimated cost.

### 22. Item Price Alert System

Allow users to set price thresholds per item (stored in `price_alerts` table with `user_id, item_tid, threshold, direction`). A background job checks prices every hour and sends notifications (email, webhook, or in-app) when thresholds are crossed. For a single-user tool, this is a local notification system — store alerts in SQLite and surface them via `GET /api/alerts`.

### 23. Inventory Value Tracker

Model a virtual inventory: users add items with quantities, and the system computes total value using current prices. Store as `inventory_items` table with `item_tid, quantity, added_at`. Expose `GET /api/inventory/value` returning `{ total_rub, total_usd, item_count, per_item_breakdown }`. Include a "what-if" mode: simulate selling/buying items and see the value change.

### 24. Squad Composition Optimizer

Given a squad size (2-5 players), suggest complementary loadouts: one sniper, one CQB, one support, etc. Ensure coverage of all ammo calibers, medical supplies, and utility items. Use a heuristic-based approach: assign roles, then fill each role with the cheapest loadout that meets minimum specs. Expose `POST /api/squad/compose` returning role assignments with loadout details.

### 25. Night Vision Equipment Finder

Catalog all night vision devices (NVGs, thermal scopes, flashlights, IR lasers) with their properties: detection range, weight, battery life, magnification. Expose `GET /api/night-vision` returning all NVGs sorted by detection range, with compatible helmet mounts and battery requirements.

### 26. Suppressor Sound Reduction Tracker

Model suppressor effectiveness: which suppressors fit which weapons, what the sound reduction percentage is, how much they affect muzzle velocity, and what the length/weight penalty is. Expose `GET /api/suppressors?caliber=556x45` returning compatible suppressors sorted by sound reduction.

### 27. Container Capacity Calculator

Model secure containers (Alpha, Beta, Kappa, Documents case, Items case, etc.) with their grid dimensions and slot sizes. Expose `GET /api/containers` returning a comparison table: grid size, total slots, weight, and which items fit in which containers. Include a "packing optimizer" that maximizes item count in a given container.

### 28. Fuel Consumption Tracker

Model generator fuel consumption rates: which fuel types (Metal Fuel Tank, Military Fuel Tank, Expeditionary), burn rates, and how long each lasts. Expose `GET /api/fuel` returning a comparison table with cost-per-hour calculations.

### 29. Weapon Part Compatibility Matrix

Build a complete compatibility matrix: which parts fit which weapons. Store as a many-to-many relationship between `WeaponPart` and `Weapon` with columns for attachment type (scope, muzzle, grip, stock, etc.). Expose `GET /api/weapons/:tid/parts?type=muzzle` returning all compatible muzzle devices sorted by performance metrics.

### 30. Batch Import and Data Versioning

Implement a data versioning system: each time the upstream data source (tarkov.dev API) is queried, snapshot the full payload and store it with a version number. This enables: (a) diffing between versions to detect changes, (b) reverting to a previous version if the upstream API introduces errors, (c) audit trail of all data changes. Store as `data_versions` table with `version, payload_json, created_at, diff_summary`.

---

## Frontend (30 Ideas)

### 1. Interactive Ballistics Chart

Replace static tables with an interactive scatter plot (using Chart.js or D3) showing ammo penetration vs. damage for all ammo types. Color-code by caliber. Add tooltips showing exact stats on hover. Click an ammo type to see a detailed breakdown panel with velocity, fragmentation chance, and armor damage. Make it zoomable and filterable by caliber.

### 2. Drag-and-Drop Loadout Builder

Build a full weapon customization screen where users drag parts onto a weapon: stock, handguard, grip, scope, muzzle, magazine. Validate compatibility in real-time (disable incompatible parts). Show live stats (ergonomics, recoil, weight, cost) as parts are added. Save loadouts to the database and share via URL-encoded state.

### 3. 3D Weapon Model Viewer

Integrate Three.js or model-viewer to display 3D weapon models. Load GLB/GLTF files from a static asset directory. Allow rotation, zoom, and part highlighting. Click a part to see its name, stats, and a link to the item page. This is the most technically ambitious frontend feature — start with a single weapon (M4A1) and expand.

### 4. Interactive Map Overlay

Use Leaflet.js or Mapbox to render Tarkov maps as image overlays. Plot extraction points, boss spawns, loot containers, and key rooms as interactive markers. Toggle layers for different data types. Show distance measurements between points. Include a "route planner" tool for marking paths to extracts.

### 5. Side-by-Side Item Comparison

Allow users to select two items (any type) and see a detailed side-by-side comparison table. For weapons: compare recoil, ergonomics, fire rate, mod slots. For armor: compare durability, class, material, ricochet chance. For ammo: compare penetration, damage, velocity. Highlight the winner in each category with color coding.

### 6. Visual Hideout Upgrade Tree

Render the hideout as an interactive node-graph (using vis.js or dagre-d3). Each node is a station level. Edges show prerequisites. Click a node to see requirements and cost. Allow users to "check off" completed upgrades and see what's still needed. Color nodes by completion status (red = not started, yellow = in progress, green = done).

### 7. Dark Mode and Theme System

Implement a full theme system using CSS custom properties and Bootstrap 5.3's color mode. Provide at least 3 themes: default dark (current), light, and a "military green" theme. Store the user's preference in `localStorage`. Add a theme picker in the navbar. Ensure all components respect the active theme.

### 8. Gunfire Sound Comparison Player

For each weapon, embed audio clips of gunfire (suppressed and unsuppressed). Use the HTML5 `<audio>` element with a custom waveform visualizer (Web Audio API). Allow A/B comparison: play two weapons' sounds back-to-back. This helps players identify guns by sound in-game.

### 9. Ammo Penetration Probability Chart

A heatmap visualization: rows are ammo types, columns are armor classes (1-6). Cell color intensity represents penetration probability (0% = white, 100% = deep red). Click a cell to see the exact percentage and shots-to-kill. Filter by caliber and armor material. Use CSS grid or a canvas-based renderer for performance.

### 10. URL-Encoded Loadout Sharing

Serialize a complete loadout (weapon + all attachments + ammo + armor + rig + backpack + medical) into a URL-safe base64 string. The URL encodes the full state, so anyone with the link can view the loadout. Add a "Share" button that copies the URL to clipboard. On the receiving end, parse the URL and render the loadout view.

### 11. Keyboard Shortcuts for Power Users

Implement a keyboard shortcut system (using `Mousetrap` or native `KeyboardEvent`). Defaults: `/` focuses search, `Esc` closes modals, `?` shows shortcut help. Allow users to customize shortcuts and store them in `localStorage`. Display a shortcut cheat sheet overlay.

### 12. Offline Mode with Service Worker

Register a service worker that caches all static assets and API responses. When offline, serve cached pages and data. Show a "You are offline — showing cached data" banner. Use the Cache API for assets and IndexedDB for database-like storage of item data. This makes the tool usable at LAN parties without internet.

### 13. Sortable, Filterable Data Tables

Upgrade all data tables (items, tasks, traders, barters) with server-side sorting and filtering. Use Turbo Frames for instant page updates without full reloads. Add column-level filters (type, caliber, trader), text search, and numeric range filters. Show result counts and pagination info.

### 14. Visual Task Dependency Graph

For each task, render its prerequisite chain as a directed graph. Start from the target task, walk backward through `task_requirements`, and render all prerequisite tasks as nodes. Highlight the critical path (longest chain). Allow users to "pin" a task and see all tasks that depend on it.

### 15. Trader Loyalty Progress Tracker

Model the player's progress toward each trader's loyalty levels. Show a progress bar for each level with: player level (current → required), reputation (current → required), spent amount (current → required), and completed tasks. Allow users to input their current stats and see exactly what they need.

### 16. Price Trend Sparklines

On item index pages, show tiny inline sparklines (using Chart.js line charts with no axes) next to each item's price. Hover to see the full price history tooltip. Click to expand into a full price history page. This gives at-a-glance price movement indication without leaving the list view.

### 17. Armor Plate Visualizer

Show a 2D grid representation of a tactical rig or armor carrier, with colored cells representing plate coverage areas. Different colors for different armor classes. Show which body parts are protected at each coverage zone. This is a common community request — visual armor coverage maps.

### 18. Quick Search with Fuzzy Matching

Replace exact-match search with a fuzzy search (using `fuzzy` gem backend or `textacular` gem). Accept typos and partial matches. Show results grouped by type: items first, then tasks, then traders. Highlight matching characters in results. Debounce input to avoid excessive queries.

### 19. Responsive Mobile Layout

Audit and optimize all pages for mobile viewports. Use Bootstrap's responsive grid consistently. Collapse the sidebar into a hamburger menu on small screens. Make data tables horizontally scrollable. Ensure touch-friendly tap targets (minimum 44px). Test on iPhone SE and Android small screens.

### 20. Breadcrumb Navigation

Add breadcrumb navigation to all detail pages: `Home > Items > Colt M4A1` or `Home > Tasks > Supplier`. Use semantic `<nav aria-label="breadcrumb">` for accessibility. Make each segment a link for easy backtracking.

### 21. Related Items Suggestions

On each item's show page, display a "Related Items" sidebar with: items in the same category, items used in barters for this item, items crafted from this item, and items that share the same caliber or armor class. Pre-compute these relationships during sync and store as JSON columns on the item.

### 22. Recently Viewed Items

Track the last 20 items a user viewed (stored in `localStorage`). Display them as a "Recently Viewed" section on the homepage and in a dropdown in the navbar. Clear history with a button.

### 23. Loadout Cost Summary Bar

On the loadout builder page, show a floating cost summary bar at the bottom: total RUB cost, total USD cost, insurance estimate, and a breakdown by category (weapon, armor, medical, etc.). Update in real-time as parts are added/removed.

### 24. Visual Ammo Comparison Tool

Select 2-5 ammo types and see a radar chart comparing: penetration, damage, fragmentation, armor damage, and velocity. Use Chart.js radar chart with semi-transparent fills for overlap. Highlight the best value in each dimension.

### 25. Interactive Hideout Material Calculator

For each hideout station level, show the required materials as icons with quantities. Allow users to check off materials they already have. Compute "still needed" quantities and total cost. Show a progress percentage for the entire hideout.

### 26. Task Progress Checkboxes

On the tasks index page, allow users to mark tasks as "completed" (stored in `localStorage`). Visually strike through completed tasks. Show a completion counter. Link task completion to the hideout planner — completed tasks unlock their rewards.

### 27. Export Data to CSV/PDF

Add an "Export" button on data tables that downloads the current view as a CSV file (using `send_data` in the controller). For item detail pages, offer a PDF export (using `prawn` gem) with formatted stats, an image, and a barcode.

### 28. Social Media Share Cards

When a user shares a Tarkov DB link on Discord/Twitter/Reddit, render an Open Graph meta tag with the item's name, image, and a description. Use `og:title`, `og:image`, `og:description`, and `twitter:card` meta tags in the `<head>`. Generate these server-side in the layout.

### 29. Quick Reference Cards

Create printable one-page reference cards for common topics: "Ammo Chart" (all 5.56 ammo in a grid), "Armor Classes" (visual comparison), "Hideout Requirements" (all stations). Render as a dedicated `/reference` page with a "Print" button that uses `@media print` CSS to format for paper.

### 30. Notification Toast System

Implement a toast notification system (using Hotwire or Stimulus) for sync status updates, price alerts, and user actions. Show success toasts on save, error toasts on failure, and info toasts for sync completion. Use Bootstrap 5 toasts with auto-dismiss after 5 seconds.

---

## Miscellaneous (15 Ideas)

### 1. Discord Bot Integration

Build a Discord bot that responds to commands like `!item M4A1` or `!task Supplier` and returns formatted embeds with item stats, price, and a link to the Tarkov DB page. Use the `discordrb` gem and interact with the app's internal service layer directly (no HTTP needed if co-hosted). Store bot configuration in `config/discord.yml`.

### 2. Browser Extension (Chrome/Firefox)

Create a browser extension that overlays Tarkov DB data on tarkov.dev or the official EFT website. When viewing an item on tarkov.dev, show a sidebar with barter recipes, hideout usage, and quest relevance. Use the extension's content script to parse the page and query the Tarkov DB API.

### 3. Command-Line Interface Tool

Build a CLI gem (`tarkov_db_cli`) that exposes the same data via terminal commands: `tarkov item M4A1`, `tarkov task "Supplier"`, `tarkov ammo --caliber 556x45`. Use `TTY::Table` for formatted terminal output. This is useful for quick lookups without opening a browser.

### 4. OpenAPI Documentation

Generate an OpenAPI 3.0 spec file documenting all API endpoints. Use `rswag` gem to auto-generate the spec from request/response tests. Host the interactive Swagger UI at `/api/docs`. This enables third-party developers to build tools on top of the Tarkov DB API.

### 5. Docker Compose Deployment

Create a `Dockerfile` and `docker-compose.yml` that build the app with SQLite, run migrations, seed the database, and start the server on port 3000. Include a health check endpoint (`GET /up`). Support environment variables for database path and secret key base. Publish to Docker Hub or GitHub Container Registry.

### 6. Performance Monitoring Dashboard

Add a `/admin/performance` page that shows: response times per endpoint (from Rails logs), database query counts per request, N+1 detection (using `bullet` gem in development), and memory usage. Use `rack-mini-profiler` for development and a custom middleware for production metrics.

### 7. Data Backup and Restore System

Implement automated SQLite backups: a Rake task (`tarkov:backup`) that copies the database file to a timestamped backup directory. Add a `tarkov:restore` task that restores from a backup. For extra safety, implement WAL (Write-Ahead Logging) mode for concurrent reads during backup.

### 8. Multi-Language Support (i18n)

Extract all user-facing strings into Rails i18n locale files (`config/locales/en.yml`, `config/locales/ru.yml`). Use `I18n.t()` everywhere. Add a language switcher in the navbar. Start with English and Russian (the game's two primary languages), then add Chinese and Portuguese.

### 9. Accessibility Audit and Improvements

Run axe-core against all pages and fix WCAG 2.1 AA violations. Add proper ARIA labels to all interactive elements. Ensure color contrast ratios meet 4.5:1. Add a "skip to content" link. Test with screen readers (VoiceOver, NVDA). Document accessibility features in the README.

### 10. Analytics Dashboard

Track page views, search queries, and feature usage using a lightweight, privacy-respecting analytics system (no Google Analytics). Store events in a `page_views` table with `path, user_agent, referrer, created_at`. Display a simple analytics dashboard at `/admin/analytics` with daily visitor counts, popular items, and search term frequency.

### 11. Community Data Corrections

Allow users to submit corrections (e.g., "This barter recipe is outdated") via a form. Store submissions in a `corrections` table with `item_tid, correction_type, description, status`. The admin can review and apply corrections. This crowdsources data maintenance without giving random users direct DB access.

### 12. Wipe Notification System

Monitor the EFT launcher or community sources for wipe announcements. When a wipe is detected, send a notification (email, Discord webhook, or in-app banner) and trigger a full data re-sync. Store wipe dates in the `wipes` table and display a "days since last wipe" counter on the homepage.

### 13. Streamer Overlay Integration

Provide a OBS-compatible overlay that shows real-time item prices, current hideout status, or task progress. Expose a `/overlay` endpoint that renders a minimal, transparent-background HTML page designed for browser source embedding in OBS. Use Server-Sent Events (SSE) for live updates without polling.

### 14. Voice Command Support

Implement Web Speech API integration for voice-controlled lookups. Say "search M4A1" or "show tasks for Prapor" and the app responds by navigating to the appropriate page. Use `SpeechRecognition` for input and `SpeechSynthesis` for spoken responses. This is experimental but fun for accessibility and novelty.

### 15. Augmented Reality Item Viewer

Use the WebXR API or `AR.js` to render 3D item models in the user's real-world environment via their phone camera. Point the phone at a flat surface, select an item (e.g., "Medical battery"), and see it placed in the room at actual scale. This is the most technically ambitious miscellaneous idea — start with a proof-of-concept using pre-made GLB models.
