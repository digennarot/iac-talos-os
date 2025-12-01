# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation suite
  - Main documentation with architecture overview
  - Step-by-step deployment workflows
  - Detailed architecture documentation
  - Complete configuration reference
  - Troubleshooting guide
  - Quick reference for daily operations
  - Contributing guidelines

### Changed
- Updated main README with documentation links
- Improved project structure documentation

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- None

---

## How to Update This Changelog

When making changes to the project:

1. **Add entries under [Unreleased]** in the appropriate category:
   - **Added**: New features
   - **Changed**: Changes in existing functionality
   - **Deprecated**: Soon-to-be removed features
   - **Removed**: Removed features
   - **Fixed**: Bug fixes
   - **Security**: Security fixes

2. **When releasing a new version**:
   - Change `[Unreleased]` to `[X.Y.Z] - YYYY-MM-DD`
   - Add a new `[Unreleased]` section at the top
   - Update version links at the bottom

3. **Example entry**:
   ```markdown
   ### Added
   - Support for multi-cluster deployments (#123)
   - Cilium ClusterMesh configuration (#124)
   ```

---

## Version History Template

```markdown
## [1.0.0] - 2024-01-15

### Added
- Initial release
- Packer templates for Talos OS
- OpenTofu modules for VM provisioning
- Talos configuration with Talhelper
- Cilium networking setup
- Proxmox Ansible playbooks
- Complete documentation

### Changed
- N/A (initial release)

### Fixed
- N/A (initial release)
```

---

## Links

- [Unreleased]: https://github.com/digennarot/iac-talos-os/compare/v1.0.0...HEAD
- [1.0.0]: https://github.com/digennarot/iac-talos-os/releases/tag/v1.0.0
