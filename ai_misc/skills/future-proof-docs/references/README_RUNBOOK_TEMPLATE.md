# README as Emergency Manual

The README should be an operational runbook — what someone (including future-you) needs to get the project running, deployed, and debugged. Prioritize function over description.

## Template

```markdown
# Project Name

One-sentence description of what this does.

## Quick Start

Step-by-step commands to go from fresh clone to running:

    git clone <repo>
    cd <project>
    <install dependencies>
    <setup command>
    <run command>

## Development

### Prerequisites
- Runtime version and how to install it
- Required system dependencies

### Running Tests
    <test command>

### Common Tasks
- How to run a specific subset of tests
- How to seed the database
- How to generate fixtures or test data

## Deployment

### How to Deploy
    <deploy command or steps>

### Environment Variables
| Variable | Purpose | Where to find it |
|----------|---------|-------------------|

### Secrets
- Where secrets are stored (vault, env files, etc.)
- How to rotate them

## Troubleshooting

### Known Issues
- Issue description — workaround

### Useful Commands
    <diagnostic command and what it reveals>

## Architecture (brief)

Keep this short. Link to DECISIONS.md for the reasoning behind choices.
```

## Guidance

- Lead with commands, not prose. A developer in a hurry scans for code blocks.
- Every section should answer: "What do I type to make this work?"
- Keep architecture discussion minimal here — detailed reasoning belongs in DECISIONS.md.
- Update the README when deployment steps change. Stale runbooks are worse than none.
