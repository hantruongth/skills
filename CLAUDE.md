# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

This is Anthropic's official **Agent Skills** repository — a collection of skills that Claude loads dynamically to improve performance on specialized tasks. Each skill is a self-contained folder with a `SKILL.md` file (YAML frontmatter + markdown instructions) plus optional bundled scripts, reference docs, and assets.

There are two plugin groups defined in `.claude-plugin/marketplace.json`:
- **document-skills**: `xlsx`, `docx`, `pptx`, `pdf` — production document-processing skills used inside Claude.ai
- **example-skills**: `algorithmic-art`, `brand-guidelines`, `canvas-design`, `doc-coauthoring`, `frontend-design`, `internal-comms`, `mcp-builder`, `skill-creator`, `slack-gif-creator`, `theme-factory`, `web-artifacts-builder`, `webapp-testing`

The `spec/` folder links to the public Agent Skills specification at agentskills.io. The `template/` folder contains the minimal skeleton for a new skill.

## Skill Structure

```
skills/<skill-name>/
├── SKILL.md          # Required: YAML frontmatter (name, description) + instructions
├── scripts/          # Executable helpers — called as black boxes, not read into context
├── references/       # Docs loaded into context on demand
└── assets/           # Static files used in output (fonts, templates, icons)
```

**Three-level loading:** only `name` + `description` from frontmatter are always in context; the `SKILL.md` body loads when the skill triggers; bundled resources load on demand. Keep `SKILL.md` under ~500 lines.

## Creating or Editing a Skill

1. **`name`** — lowercase, hyphens for spaces; must be unique across the repo.
2. **`description`** — this is the primary trigger mechanism. It must describe both *what* the skill does and *when* to invoke it. Lean slightly "pushy" to prevent under-triggering (see the `skill-creator` SKILL.md for guidance).
3. All "when to use" information belongs in the frontmatter `description`, not the body.
4. Prefer explaining the *why* behind instructions rather than MUST/NEVER caps-lock directives.
5. Use the imperative form in instructions.

## Packaging a Skill

```bash
python -m scripts.package_skill skills/<skill-name>
# Produces <skill-name>.skill (zip archive); evals/ directory is excluded automatically
```

## Installing Skills in Claude Code

```
/plugin marketplace add anthropics/skills
/plugin install document-skills@anthropic-agent-skills
/plugin install example-skills@anthropic-agent-skills
```

## Skill-Creator Eval Workflow

The `skill-creator` skill has its own eval/benchmark infrastructure under `skills/skill-creator/scripts/`:

```bash
# Run eval loop (description optimization)
python -m scripts.run_loop \
  --eval-set <path-to-trigger-eval.json> \
  --skill-path <path-to-skill> \
  --model <model-id> \
  --max-iterations 5

# Aggregate benchmark results
python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>

# Generate HTML review viewer
python skills/skill-creator/eval-viewer/generate_review.py <workspace>/iteration-N \
  --skill-name "my-skill" \
  --benchmark <workspace>/iteration-N/benchmark.json
# Use --static <output_path> in headless/Cowork environments
```

JSON schemas for `evals.json`, `grading.json`, `benchmark.json`, and related files are in `skills/skill-creator/references/schemas.md`. The viewer depends on exact field names (`configuration` not `config`, `result.pass_rate` not top-level `pass_rate`).

## Document Skills — Key Conventions

These skills are production code used inside Claude.ai. When editing them, follow the patterns already established:

- **docx / pptx / xlsx**: All three use the same `scripts/office/` subpackage (unpack → edit XML → pack). The `unpack.py` / `pack.py` / `validate.py` scripts are shared across all three but copied into each skill folder independently.
- **docx** new documents use `docx` (npm): always set page size explicitly (docx-js defaults to A4); use `WidthType.DXA` for tables, never `WidthType.PERCENTAGE`; use `LevelFormat.BULLET` not Unicode characters; `PageBreak` must be inside a `Paragraph`.
- **pptx** reads use `markitdown`; creation uses pptxgenjs; visual inspection uses `scripts/thumbnail.py`.
- **xlsx** enforces zero formula errors and industry-standard financial color coding (blue=inputs, black=formulas, green=cross-sheet links, red=external links).
- **pdf** uses `pypdf`, `pdfplumber`, `reportlab`, and CLI tools (`qpdf`, `pdftotext`). For forms, see `skills/pdf/forms.md`.

## Webapp Testing

The `webapp-testing` skill uses native Python Playwright. The key pattern is **reconnaissance-then-action**: navigate → wait for `networkidle` → inspect DOM → act. Always launch Chromium in headless mode. Use `scripts/with_server.py` to manage server lifecycle; run with `--help` first and treat it as a black box.

## License Notes

- Most example skills: Apache 2.0 (`LICENSE.txt` per folder)
- Document skills (`docx`, `pdf`, `pptx`, `xlsx`): Proprietary/source-available — do not relicense or redistribute
