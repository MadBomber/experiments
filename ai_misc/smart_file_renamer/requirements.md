# smart_file_renamer — Requirements

Extracted from [rename.click/docs/getting-started/how-it-works](https://rename.click/docs/getting-started/how-it-works) on 2026-04-16.

---

## Core Functional Requirements

### File Input

- Accept files via drag-and-drop
- Accept files via file browser/picker dialog
- Accept files via OS right-click context menu integration
- Support batch processing (multiple files at once)

### AI Analysis

- Analyze file contents to derive a short, descriptive name
- Support text document analysis
- Support image analysis (content-aware naming)
- Generate name suggestions displayed alongside the original filename

### Output / Actions

- Rename the file in place
- Optionally relocate file to a category/topic folder
- Support both rename + relocate in a single operation

### Operation Safety

- Full undo/redo operation history

---

## Workflow Modes

| Mode | Description |
|------|-------------|
| **Rename** | Batch rename and organize files into category folders |
| **AI Search** | Natural language content-based file discovery |
| **Auto Flow** | Watch a source folder and auto-process new files continuously |

---

## AI Provider / Backend Requirements

- **Local-first**: Bundled LLM runs entirely on-device (no data leaves the machine)
- Optional cloud providers: OpenAI, Google Gemini
- Optional self-hosted models: LM Studio, Ollama
- Post-install operation with no internet required when using local mode

---

## Non-Functional Requirements

- ~4 GB RAM minimum for local model
- ~4 GB disk for model download
- GPU acceleration (Metal on macOS Apple Silicon)
- Automatic GPU/CPU selection on other hardware

---

## Platform Targets

- macOS (Apple Silicon + Intel)
- Windows
- Linux (not mentioned by reference app — opportunity to differentiate)

---

## Potential Additional Requirements (inferred gaps)

- Naming style configuration (snake_case, kebab-case, Title Case, etc.)
- Maximum filename length enforcement
- Conflict resolution when a target name already exists
- File type allowlist/denylist
- Preview mode (show proposed names before applying)
- Dry-run / simulation mode
- Logging of all rename operations
