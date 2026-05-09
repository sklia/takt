# Changelog

## [0.4.1](https://github.com/sklia/takt/compare/v0.4.0...v0.4.1) (2026-05-09)


### Bug Fixes

* **release:** discard build artifacts before switching to gh-pages ([c04ba5b](https://github.com/sklia/takt/commit/c04ba5bbeec780e9bfae044cf5bdcef529b1b10a))

## [0.4.0](https://github.com/sklia/takt/compare/v0.3.1...v0.4.0) (2026-05-09)


### Features

* Swift 6 strict concurrency migration ([00bb70a](https://github.com/sklia/takt/commit/00bb70a38bb63e984bc4c3e7f1183c5163d5312e))

## [0.3.1](https://github.com/sklia/takt/compare/v0.3.0...v0.3.1) (2026-05-09)


### Bug Fixes

* **release:** re-sign Sparkle binaries for notarization ([85b8ffc](https://github.com/sklia/takt/commit/85b8ffc85bea869cd44915f267e9600d94d25e9b))

## [0.3.0](https://github.com/sklia/takt/compare/v0.2.0...v0.3.0) (2026-05-09)


### Features

* **narrator:** ducking safety ([#37](https://github.com/sklia/takt/issues/37)) ([bfff52f](https://github.com/sklia/takt/commit/bfff52f5b11f9f1adce01042c0e5940b9b3284a2))
* **narrator:** ducking safety with persist and timeout ([bfff52f](https://github.com/sklia/takt/commit/bfff52f5b11f9f1adce01042c0e5940b9b3284a2))
* **narrator:** Focus mode suppression ([#40](https://github.com/sklia/takt/issues/40)) ([46ad1ff](https://github.com/sklia/takt/commit/46ad1ffef9f8136660cb5e4dcccf944bbb99e560))
* **narrator:** periodic permission re-check on foreground ([aa7febb](https://github.com/sklia/takt/commit/aa7febb2d569be29d7d371b8647fc7caf36f55b6))
* **narrator:** permission re-check ([#39](https://github.com/sklia/takt/issues/39)) ([aa7febb](https://github.com/sklia/takt/commit/aa7febb2d569be29d7d371b8647fc7caf36f55b6))
* **narrator:** suppress narration during Focus modes ([46ad1ff](https://github.com/sklia/takt/commit/46ad1ffef9f8136660cb5e4dcccf944bbb99e560))
* **shell:** left-click opens menu ([#35](https://github.com/sklia/takt/issues/35)) ([005b528](https://github.com/sklia/takt/commit/005b52846bbeb6f8d8c3cdcdfcd3d2e5c2077109))
* **updates:** sparkle auto-update with appcast pipeline ([#41](https://github.com/sklia/takt/issues/41)) ([30bd502](https://github.com/sklia/takt/commit/30bd502e2d5e3aa5de20163e9d9e7ca42326b884))


### Code Refactoring

* **narrator:** extract MusicSource protocol ([#38](https://github.com/sklia/takt/issues/38)) ([d790c97](https://github.com/sklia/takt/commit/d790c97c83b8cabdb6eefbfb8d51d73627176976))

## [0.2.0](https://github.com/sklia/takt/compare/v0.1.0...v0.2.0) (2026-05-09)


### Features

* **assets:** app icon and asset catalog ([#24](https://github.com/sklia/takt/issues/24)) ([f601cd1](https://github.com/sklia/takt/commit/f601cd10a0c63b40e32231a740f42ef30628ba48))
* **ci:** notarized DMG release pipeline ([#26](https://github.com/sklia/takt/issues/26)) ([9361213](https://github.com/sklia/takt/commit/936121348124ff3f9e259a5c135aa530345620f8))
* **github:** set up project ([5fd169e](https://github.com/sklia/takt/commit/5fd169efa13db313dd36afa89751f5e40df7e65a))
* **narrator:** NarratorEngine state machine ([bd358ac](https://github.com/sklia/takt/commit/bd358ac70fe2a849517d70baf1ab0b72493c88fb))
* **narrator:** speak on Spotify track-change ([8ff5f8e](https://github.com/sklia/takt/commit/8ff5f8e8cb8f654a874302fd2f287c9512c8328d))
* **narrator:** speak on Spotify track-change ([3cfcdd0](https://github.com/sklia/takt/commit/3cfcdd08796e9758c3d3883b91324c150e873595))
* permission-denied UX with engine state transition ([#20](https://github.com/sklia/takt/issues/20)) ([904d4e8](https://github.com/sklia/takt/commit/904d4e8ea7edbf5cc189ad94353cb23827d87d13))
* **release:** update release configuration and manifest version ([8295d65](https://github.com/sklia/takt/commit/8295d65b1dfb47d00eb2ad7f06de5e5eba00481e))
* **settings:** ducking slider, global hotkey, launch-at-login ([#25](https://github.com/sklia/takt/issues/25)) ([ec3bca7](https://github.com/sklia/takt/commit/ec3bca7b38e0e60883516a03f8d2de0f262d57a1))
* **settings:** voice picker, speech-rate slider, preview ([#21](https://github.com/sklia/takt/issues/21)) ([96edfda](https://github.com/sklia/takt/commit/96edfda3226ddc650a2cd855de96c6fab0abc27f))
* **shell:** first-run welcome sheet ([#19](https://github.com/sklia/takt/issues/19)) ([258a232](https://github.com/sklia/takt/commit/258a2324872caf72b714505c2bb90ec67721f05d))
* **shell:** voice-quality nudge ([#22](https://github.com/sklia/takt/issues/22)) ([e7be3cf](https://github.com/sklia/takt/commit/e7be3cfd27879a4d35d3c5468d95d52ef8be18e4))
* Spotify ducking and menu-bar narrator toggle ([#17](https://github.com/sklia/takt/issues/17)) ([4f29f87](https://github.com/sklia/takt/commit/4f29f87e37a9b2ade838ac6e23d1a627a417c277))


### Bug Fixes

* **dependabot:** change commit message prefix from chore to ci ([455f2a2](https://github.com/sklia/takt/commit/455f2a2e2c036d9190282bc97b22b2488910637f))
* **release:** update manifest file path and create new manifest ([9e05e1a](https://github.com/sklia/takt/commit/9e05e1ad519a24f118f6fe582227495108b108d1))

## [0.1.0](https://github.com/sklia/takt/compare/takt-v0.0.1...takt-v0.1.0) (2026-05-09)


### Features

* **github:** set up project ([5fd169e](https://github.com/sklia/takt/commit/5fd169efa13db313dd36afa89751f5e40df7e65a))
* **narrator:** NarratorEngine state machine ([bd358ac](https://github.com/sklia/takt/commit/bd358ac70fe2a849517d70baf1ab0b72493c88fb))
* **narrator:** speak on Spotify track-change ([8ff5f8e](https://github.com/sklia/takt/commit/8ff5f8e8cb8f654a874302fd2f287c9512c8328d))
* **narrator:** speak on Spotify track-change ([3cfcdd0](https://github.com/sklia/takt/commit/3cfcdd08796e9758c3d3883b91324c150e873595))
* **release:** update release configuration and manifest version ([8295d65](https://github.com/sklia/takt/commit/8295d65b1dfb47d00eb2ad7f06de5e5eba00481e))


### Bug Fixes

* **dependabot:** change commit message prefix from chore to ci ([455f2a2](https://github.com/sklia/takt/commit/455f2a2e2c036d9190282bc97b22b2488910637f))
* **release:** update manifest file path and create new manifest ([9e05e1a](https://github.com/sklia/takt/commit/9e05e1ad519a24f118f6fe582227495108b108d1))
