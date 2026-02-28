# Technical Writing & Release Management

> **Goal:** Clear communication, predictable releases.
> **Standards:** [Keep a Changelog](https://keepachangelog.com/), [SemVer](https://semver.org/).

## 1. Documentation Types

### README.md
The front page. MUST include:
1.  **What** is it? (One sentence hook).
2.  **Why** use it? (Features).
3.  **How** to install/start? (Quickstart).

### ADR (Architecture Decision Records)
Immutable records of decisions.
- **Format:** `docs/arch/001-use-postgres.md`
- **Structure:** Context -> Decision -> Consequences.

## 2. Release Management

### Semantic Versioning (SemVer)
Format: `MAJOR.MINOR.PATCH` (e.g., 2.1.4)
- **MAJOR:** Breaking changes.
- **MINOR:** New features (backward compatible).
- **PATCH:** Bug fixes.

### CHANGELOG.md
**Never** dump git logs. Write for humans.

**Structure:**
```markdown
## [Unreleased]

## [1.0.0] - 2024-03-20
### Added
- Feature X.
### Fixed
- Bug Y.
```

## 3. The Release Process
1.  **Audit Docs:** Are new features documented in README/Wiki?
2.  **Bump Version:** Update `version.rb`, `package.json`.
3.  **Update Changelog:** Move "Unreleased" items to new version header.
4.  **Tag:** Create git tag (`git tag v1.0.0`).
5.  **Release:** Push to RubyGems/NPM/Docker Hub.
