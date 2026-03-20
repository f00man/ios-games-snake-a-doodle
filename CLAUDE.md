# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Snake-a-Doodle** is an iOS game built with SwiftUI. The core gameplay is classic Snake, but with a creative post-game twist: after losing, the player can draw on the level map (with the snake still visible), place stickers, and add pictures.

**Key gameplay rule:** The snake does NOT increase in speed when eating food — it only elongates.

**Business model:**
- Requires an Apple account to install (sign-in with Apple)
- Contains ads (Google AdMob or similar)
- One-time purchase price: $0.99 (via StoreKit / App Store)

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData
- **Target:** iOS
- **IDE:** Xcode (project at `snake-a-doodle/snake-a-doodle.xcodeproj`)

## Project Structure

```
snake-a-doodle/
  snake-a-doodle/           # Main app source
    snake_a_doodleApp.swift  # App entry point, SwiftData ModelContainer setup
    ContentView.swift        # Root view (currently boilerplate — replace with game)
    Item.swift               # Boilerplate SwiftData model (will be replaced)
  snake-a-doodleTests/      # Unit tests
  snake-a-doodleUITests/    # UI tests
  snake-a-doodle.xcodeproj/ # Xcode project
```

## Building & Running

Build and run via Xcode — open `snake-a-doodle/snake-a-doodle.xcodeproj`.

From the command line:

```bash
# Build for simulator
xcodebuild -project snake-a-doodle/snake-a-doodle.xcodeproj \
  -scheme snake-a-doodle \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Run unit tests
xcodebuild test \
  -project snake-a-doodle/snake-a-doodle.xcodeproj \
  -scheme snake-a-doodle \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test \
  -project snake-a-doodle/snake-a-doodle.xcodeproj \
  -scheme snake-a-doodle \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:snake-a-doodleTests/SnakeGameTests
```

## Architecture Plan

The game is split into three major layers:

### 1. Game Engine (`GameEngine` / `GameState`)
- Manages the snake body (array of grid positions), food position, score
- Tick-based movement at a **fixed interval** (speed never changes — only length grows on eat)
- Direction input buffering to prevent 180° reversals

### 2. Views
- `GameView` — renders the grid, snake, and food during active play
- `PostGameCanvasView` — shown after losing; overlays a drawing canvas on top of the frozen game board snapshot, supports stickers and photo placement
- `MainMenuView` — entry point with start/leaderboard/store access

### 3. Monetization & Auth
- **StoreKit 2** for the $0.99 one-time purchase unlock
- **Sign in with Apple** for account requirement
- **Ad integration** (e.g., Google AdMob) for interstitial/banner ads; ads should be suppressed for paying users

## Git / GitHub

All git remote operations (push, pull, fetch, clone) must use this SSH key:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa.bilberryhome -o IdentitiesOnly=yes' git push
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa.bilberryhome -o IdentitiesOnly=yes' git pull
# etc.
```

Always prefix git commands that communicate with GitHub with that `GIT_SSH_COMMAND` env var. Do not rely on the default SSH agent for remote operations in this repo.

## Important Constraints

- The snake speed is **constant** — do not increase tick rate or reduce timer interval on food consumption.
- The post-game canvas must preserve a snapshot of the final game state (grid + snake positions) as the background layer.
- SwiftData is used for persistence (high scores, unlocked stickers, purchase state).
- Entitlements currently have app sandbox and user-selected file read access — update as needed for photo library access (`NSPhotoLibraryUsageDescription`).
