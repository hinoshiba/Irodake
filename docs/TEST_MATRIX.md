# Release Test Matrix

Record model, chip, RAM, macOS build, display model/resolution/scale/rotation, FPS setting, commit, and result for every run.

## Core behavior

- [ ] Full grayscale with no color spots
- [ ] Color spot inside each display
- [ ] Multiple overlapping fixed spots
- [ ] Gray-selected mode with 1 and multiple spots
- [ ] Gray-selected mode with zero spots refuses to capture
- [ ] Mode switch while ON
- [ ] Add/remove/clear spot while ON
- [ ] `⌥⌘G` from every app and full-screen Space
- [ ] `⌥⌘C` press, repeat, release, and modifier-order variations
- [ ] Menu bar ON/OFF and error recovery with main window closed

## Window tracking

- [ ] move, resize, minimize, restore, close
- [ ] window crosses displays
- [ ] window becomes partially offscreen
- [ ] owner app quits and restarts
- [ ] another window overlaps the tracked rectangle
- [ ] no title or Window ID persists after Irodake quits
- [ ] front-window action never chooses an unrelated fallback

## Display topology

- [ ] one Retina display
- [ ] one non-Retina display
- [ ] Intel Mac and Apple Silicon Mac
- [ ] two 4K displays
- [ ] one 5K/6K display
- [ ] mixed 1x / 2x scale
- [ ] left/right negative coordinate arrangement
- [ ] display above and below primary
- [ ] portrait rotation
- [ ] mirror mode
- [ ] hot plug / unplug
- [ ] resolution and scaling change while ON
- [ ] 60 Hz / 120 Hz mixed refresh

## macOS environment

- [ ] Spaces and rapid Space switching
- [ ] Mission Control
- [ ] Stage Manager
- [ ] another app in full screen
- [ ] menu bar, Dock, notification, Control Center
- [ ] screen lock / unlock
- [ ] sleep / wake
- [ ] session logout / Fast User Switching
- [ ] launch at login starts OFF and does not open unwanted capture
- [ ] app update and uninstall

## Permission failures

- [ ] first-run deny
- [ ] allow from System Settings and retry
- [ ] revoke while ON
- [ ] stop from macOS system capture UI
- [ ] TCC reset
- [ ] signed build upgrade keeps or correctly re-requests permission
- [ ] capture stream stops unexpectedly
- [ ] overlay disappears immediately even if `stopCapture` is delayed

## Color and protected content

- [ ] sRGB test chart orientation and grayscale luminance
- [ ] Display P3 image
- [ ] HDR/XDR behavior documented
- [ ] Night Shift
- [ ] True Tone
- [ ] macOS system grayscale already enabled
- [ ] Safari / TV protected video behavior documented; no bypass attempted
- [ ] screenshots and third-party screen sharing behavior documented

## Performance

- [ ] 20 / 30 / 60 fps
- [ ] low-end supported Mac at 4K/5K
- [ ] dual high-resolution displays
- [ ] p50 / p95 input-to-display latency
- [ ] CPU / GPU / Energy Impact after 15 min steady state
- [ ] memory, IOSurface, and file descriptors over 8 hours
- [ ] rapid mode/spot changes do not create render backlog
- [ ] screen static and screen animated workloads

## Accessibility and UI

- [ ] onboarding completes one successful real effect
- [ ] VoiceOver order, labels, selected state, and announcements
- [ ] keyboard-only navigation and Escape from selection HUD
- [ ] Voice Control labels
- [ ] Increase Contrast
- [ ] Reduce Transparency
- [ ] Reduce Motion
- [ ] large text / long English and Japanese strings
- [ ] light and dark appearance
- [ ] menu bar crowded / icon hidden scenarios
