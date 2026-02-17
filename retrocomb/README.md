# RetroComb (iOS SpriteKit)

RetroComb is a native iOS arcade game built with **Swift + SpriteKit**.

> This repository is an Xcode iOS project (not a JavaScript/web game).

## What’s in the game

The game currently contains multiple arcade-style levels/scenes (including flappy, top-down, open-world/survival, and additional challenge modes), shared progression systems, retro visual effects, and generated/managed sound.

Main code is in:
- `retrocomb/` (game scenes, game systems, audio, config)
- `retrocomb.xcodeproj/` (Xcode project)

## Requirements

- macOS with Xcode
- Xcode 16+ (recommended for current project settings)
- iOS deployment target in project: **18.4** (`project.pbxproj`)

## Run locally (Xcode)

1. Open project:
   - `open retrocomb.xcodeproj`
2. Select scheme: `retrocomb`
3. Select simulator or physical iPhone
4. Press **Run** (`Cmd+R`)

## Build from CLI (optional)

```bash
# From repo root
xcodebuild \
  -project retrocomb.xcodeproj \
  -scheme retrocomb \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

For Release build:

```bash
xcodebuild \
  -project retrocomb.xcodeproj \
  -scheme retrocomb \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build
```

## Release device target

For release readiness, smoke-test on:
- iPhone 12
- iPhone 13
- iPhone 14
- iPhone 15

See `RELEASE_CHECKLIST.md` for the exact matrix and pass/fail criteria.

## Known limitations (current)

- iPhone + iPad families are enabled in project settings, but release smoke matrix is currently iPhone-focused (12/13/14/15).
- UI/UX and gameplay complexity differ by scene; transitions and performance must be validated on real devices before TestFlight/App Store submission.
- Logging is currently simple (`print(...)` in some components). For release logging expectations, see `LOGGING_POLICY.md`.

## QA / release docs

- `RELEASE_CHECKLIST.md` — manual smoke-test matrix and preflight checks
- `LOGGING_POLICY.md` — minimal DEBUG vs RELEASE logging policy
- `APP_STORE_PUBLICATION.md` / `QUICK_PUBLICATION_GUIDE.md` — publication guidance
