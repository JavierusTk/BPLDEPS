# Changelog

All notable changes to BPLDeps will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-29

### Added
- Initial release
- Direct dependency analysis from BPL Import Table
- Recursive dependency analysis (transitive dependencies)
- Tree view mode (`-t`) for hierarchical visualization
- Verbose mode (`-v`) with full paths and statistics
- Automatic BPL search in common directories
- Full path expansion for all found dependencies
- Summary statistics (total/found/not found)
- Support for relative and absolute paths
- English and Spanish documentation
- MIT License

### Features
- Reads PE32 Import Table directly (no external dependencies)
- Supports any Delphi version (analyzes compiled BPLs)
- Handles missing dependencies gracefully
- Copy/paste friendly output
- Scriptable for CI/CD integration
- Thread-safe file access

### Technical Details
- Written in Delphi 12 (Athens)
- Uses native Windows API (no external DLLs)
- Portable executable (~1 MB)
- Console application (exit codes for automation)

## [Unreleased]

### Planned Features
- Support for 64-bit BPL files
- JSON output format for parsing
- XML output format
- Configuration file support
- Recursive depth limiting
- Performance improvements for large dependency trees
- Cross-reference analysis (which packages use package X)
- Dependency graph visualization (DOT/GraphViz format)

---

## Release Notes

### How to Report Issues

Found a bug or have a suggestion? Please [open an issue](https://github.com/yourusername/bpldeps/issues).

### Version Numbering

- **Major** (X.0.0): Breaking changes or major new features
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes and minor improvements
