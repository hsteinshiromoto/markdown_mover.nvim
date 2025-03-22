# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Support for paths relative to git repository root
  - Paths in tag rules and default_path can now be relative to git root
  - Absolute paths (starting with `~` or `/`) are still supported
  - Falls back to current directory if not in a git repository

### Changed
- Updated default example configurations to use git root-relative paths
- Improved path resolution with better error handling and notifications

## [0.1.0] - 2024-03-21

### Added
- Initial release
- Basic markdown file organization based on YAML frontmatter tags
- Support for multiple tags in frontmatter
- Customizable tag rules and destinations
- Default path for untagged files
- Keymapping for manual file moving
- Auto-move on save option
- Directory ignore patterns
- Default ignored directories for common development folders
- Commands for manual moving and frontmatter testing
- Lazy.nvim compatibility 