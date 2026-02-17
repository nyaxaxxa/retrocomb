# Release Checklist (Smoke Test)

Use this checklist before each TestFlight/App Store candidate.

## Scope

Target devices (required):
- iPhone 12
- iPhone 13
- iPhone 14
- iPhone 15

Build under test:
- [ ] Release configuration
- [ ] Correct bundle id / signing profile
- [ ] Version + build number updated

## Smoke Matrix (pass/fail per device)

| Test Area | iPhone 12 | iPhone 13 | iPhone 14 | iPhone 15 |
|---|---|---|---|---|
| App launches to main menu without crash (cold start) | ⬜ | ⬜ | ⬜ | ⬜ |
| New game starts, first scene is playable | ⬜ | ⬜ | ⬜ | ⬜ |
| Scene/level transitions complete without freeze/black screen | ⬜ | ⬜ | ⬜ | ⬜ |
| FPS sanity is stable (no severe stutter during normal play) | ⬜ | ⬜ | ⬜ | ⬜ |
| Audio works (music + SFX), no distortion/cutouts | ⬜ | ⬜ | ⬜ | ⬜ |
| Background/foreground resume works (home -> app) | ⬜ | ⬜ | ⬜ | ⬜ |
| 10-minute play session without crash | ⬜ | ⬜ | ⬜ | ⬜ |

## Pass Criteria

- No launch crashes on any target device.
- No blocking gameplay issues in core flow (launch -> play -> transition -> continue).
- No reproducible crash in 10-minute smoke session per device.
- Performance and audio are acceptable for TestFlight.

## Manual Notes (required)

Record for each failing checkbox:
- Device + iOS version
- Build number
- Repro steps
- Screenshot/video if possible

## Final Go/No-Go

- [ ] GO (all critical checks pass)
- [ ] NO-GO (critical check failed; block release)

Release owner sign-off: ____________________
Date: ____________________
