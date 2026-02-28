# Open Source & Community Standards

> **Goal:** Healthy community, clear legal status.
> **Standards:** [Community Health Files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions), [ChooseALicense](https://choosealicense.com/).

## 1. Licensing (Legal)
Every open source project MUST have a license.

### Common Choices
- **MIT:** Simple, permissive. "Do whatever you want, just keep my name on it." (Default for Rails).
- **Apache 2.0:** Permissive, but covers patent rights. Good for large enterprise projects.
- **GPLv3:** Copyleft. "If you use this, your code must also be open source."
- **AGPLv3:** Strong Copyleft. Covers network use (SaaS).

**Action:** Create `LICENSE` or `LICENSE.txt`.

## 2. Community Health Files

### CONTRIBUTING.md
Instructions for developers.
- How to set up the dev environment.
- How to run tests.
- PR process (branches, commit messages).
- "We use the Claude Rails Developer Kit."

### CODE_OF_CONDUCT.md
Standards for behavior.
- **Standard:** [Contributor Covenant](https://www.contributor-covenant.org/) (Industry Standard).
- Defines unacceptable behavior and reporting channels.

### SECURITY.md
Vulnerability reporting policy.
- "Do not open GitHub Issues for security bugs."
- "Email security@example.com."

### GOVERNANCE.md
(For larger projects)
- Who makes decisions?
- How to become a maintainer?

## 3. GitHub Profile (`.github/profile/README.md`)
Create a public `README` for the organization/user to showcase the project.
