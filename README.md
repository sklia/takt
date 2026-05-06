# Takt

A macOS menu-bar app that announces the artist and title of every Spotify track as it plays. Named after the Norwegian/German word for the basic unit of musical time.

## Status

v1 in development. See [PLAN.md](PLAN.md) for the full design.

## Requirements

- macOS 14+
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build

```sh
brew install xcodegen
xcodegen generate
open Takt.xcodeproj
```

Or from the command line:

```sh
xcodebuild -project Takt.xcodeproj -scheme Takt -destination 'platform=macOS' build
xcodebuild -project Takt.xcodeproj -scheme Takt -destination 'platform=macOS' test
```

## Project layout

- `project.yml` — XcodeGen source of truth (the `.xcodeproj` is generated and gitignored)
- `Takt/`
  - `App/` — `@main` entry point and `NSApplicationDelegate`
  - `Narrator/` — engine state machine and protocols (`Speaker`, `Ducker`, `PlaybackEvent`)
- `TaktTests/` — unit tests covering `NarratorEngine`

## License

[MIT](LICENSE).
