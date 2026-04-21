# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this gem adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-04-21

### Added
- `Pipe.halt!(value)` — short-circuits the currently executing pipeline and returns `value` as the final result; bypasses `on_error`
- `Pipe::Halted` exception carrying the halt value (intended for rescue-free control flow)

## [0.4.0] - 2026-04-09

### Added
- `#call(value)` executes the pipeline on any input, making pipelines reusable
- `#to_proc` converts the pipeline to a Proc for use with `map`, `select`, and `&` operator

## [0.3.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.3.0] - 2026-03-29

### Added
- Pipeline composition with `compose` and `>>` operator to chain pipelines together
- Step naming with optional symbol argument for error identification
- `PipeError` class wrapping errors with `step_name` and `original_error` attributes
- `tap_value` method for capturing and inspecting intermediate values
- `.github/` issue templates, PR template, and dependabot configuration

### Changed
- Errors raised in steps are now wrapped in `PipeError` with step context
- README updated with full badge set, Support section, and new feature documentation

## [0.2.1] - 2026-03-26

### Changed
- Add Sponsor badge to README
- Fix License section format
- Sync gemspec summary with README


## [0.2.0] - 2026-03-24

### Fixed
- Align README one-liner with gemspec summary

## [0.1.9] - 2026-03-24

### Fixed
- Standardize README code examples to use double-quote require statements
- Remove inline comments from Development section to match template

## [0.1.8] - 2026-03-24

### Fixed
- Fix Installation section quote style to double quotes

## [0.1.7] - 2026-03-22

### Changed
- Expand test coverage

## [0.1.6] - 2026-03-20

### Fixed
- Fix README description trailing period
- Fix CHANGELOG header wording

## [0.1.5] - 2026-03-20

### Changed
- Restructure CHANGELOG to follow Keep a Changelog format

## [0.1.4] - 2026-03-20

### Changed
- Revert gemspec to single-quoted strings per RuboCop default configuration

## [0.1.3] - 2026-03-20

### Fixed
- Fix RuboCop Style/StringLiterals violations in gemspec

## [0.1.2] - 2026-03-20

### Added
- Add License badge to README
- Add bug_tracker_uri to gemspec
- Add Requirements section to README

## [0.1.0] - 2026-03-15

### Added
- Initial release
- Sequential step composition with fluent DSL
- Conditional steps with if/unless guards
- Error short-circuiting
- Tee steps for side effects

[0.4.0]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.4.0
[0.3.1]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.3.1
[0.3.0]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.3.0
[0.2.1]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.2.1
[0.2.0]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.2.0
[0.1.9]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.9
[0.1.8]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.8
[0.1.7]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.7
[0.1.6]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.6
[0.1.5]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.5
[0.1.4]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.4
[0.1.3]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.3
[0.1.2]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.2
[0.1.0]: https://github.com/philiprehberger/rb-pipe/releases/tag/v0.1.0
