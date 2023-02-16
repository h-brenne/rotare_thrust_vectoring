# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][keep_chglog], and this project adheres
to [Semantic Versioning][sem_ver].

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed
- Issue with zero lift angle calculation when polars provided for a single
  Reynolds
- Issue with lift curve slope calculation when polars provided for a single
  Reynolds

## [0.1.1] - 2023-02-13

### Added
- Documentation now added to the release archive

### Fixed
- Proper extrapolation method

## [0.1.0] - 2023-02-02

### Added
- Publish documentation (beta)
- Roadmap
- Logo
- Clarification on beta status

### Changed
- Moved repo to its own group (thlamb -> rotare)
- Update URLs in all doc
- Make basic functions compliant with multi-rotor parameters

### Fixed
- Blade orientation on 3D view for propellers (#4)


## [0.0.1] - 2022-11-27

### Changed

Remove useless files from the release archive

## [0.0.0] - 2022-11-27

_Initial commit_: single rotor in hover/axial flows

[sem_ver]:<https://semver.org/spec/v2.0.0.html>
[keep_chglog]: <https://keepachangelog.com/en/1.0.0/>

[Unreleased]: https://gitlab.uliege.be/rotare/rotare/compare/0.1.1...main
[0.1.1]: https://gitlab.uliege.be/rotare/rotare/compare/0.1.0...0.1.1
[0.1.0]: https://gitlab.uliege.be/rotare/rotare/compare/0.0.1...0.1.0
[0.0.1]: https://gitlab.uliege.be/rotare/rotare/compare/0.0.0...0.0.1
[0.0.0]: https://gitlab.uliege.be/rotare/rotare/-/releases/0.0.0
